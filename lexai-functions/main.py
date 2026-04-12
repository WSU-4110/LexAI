import json
import os
import time
import requests
from firebase_functions import https_fn
from firebase_admin import initialize_app
from pinecone import Pinecone
from dotenv import load_dotenv

load_dotenv()

# --- Config ---
PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")
RUNPOD_API_KEY = os.getenv("RUNPOD_API_KEY")
RUNPOD_ENDPOINT_ID = os.getenv("RUNPOD_ENDPOINT_ID")
INDEX_NAME = "michigan-legislation"
EMBED_MODEL = "multilingual-e5-large"

initialize_app()

# Initialize Pinecone
pc = Pinecone(api_key=PINECONE_API_KEY)
index = pc.Index(INDEX_NAME)


def embed_query(query_text: str) -> list:
    embeddings_response = pc.inference.embed(
        model=EMBED_MODEL,
        inputs=[query_text],
        parameters={"input_type": "query", "truncate": "END"},
    )
    return embeddings_response[0]["values"]


def query_pinecone(query_embedding: list, top_k: int = 5) -> list:
    results = index.query(
        vector=query_embedding,
        top_k=top_k,
        include_metadata=True,
    )
    return [match["metadata"]["chunk_text"] for match in results["matches"]]


def call_runpod(messages: list) -> str:
    run_response = requests.post(
        f"https://api.runpod.ai/v2/{RUNPOD_ENDPOINT_ID}/run",
        headers={
            "Authorization": f"Bearer {RUNPOD_API_KEY}",
            "Content-Type": "application/json",
        },
        json={
            "input": {
                "openai_route": "/v1/chat/completions",
                "openai_input": {
                    "model": "hbalkhafaji/llama3-8b-legal-merged",
                    "messages": messages,
                    "max_tokens": 1024,
                    "temperature": 0.7,
                },
            }
        },
    )
    run_response.raise_for_status()
    job_id = run_response.json()["id"]

    # Poll for completion, max 5 minutes
    for _ in range(150):
        status_response = requests.get(
            f"https://api.runpod.ai/v2/{RUNPOD_ENDPOINT_ID}/status/{job_id}",
            headers={"Authorization": f"Bearer {RUNPOD_API_KEY}"},
        )
        status_response.raise_for_status()
        result = status_response.json()

        if result["status"] == "COMPLETED":
            output = result.get("output", {})

            # Handle both dict and list output formats
            if isinstance(output, list):
                if len(output) > 0 and isinstance(output[0], dict):
                    choices = output[0].get("choices", [])
                else:
                    return str(output)
            else:
                choices = output.get("choices", [])

            if choices:
                return choices[0]["message"]["content"]
            return "No response generated."

        if result["status"] == "FAILED":
            return f"Error: RunPod job failed - {result.get('error', 'unknown error')}"

        time.sleep(2)

    return "Error: Request timed out."


@https_fn.on_call(enforce_app_check=False, timeout_sec=300)
def chat(req: https_fn.CallableRequest) -> dict:
    try:
        prompt = req.data.get("prompt", "")
        chat_history = req.data.get("chat_history", [])
        language = req.data.get("language", "en")

        if not prompt:
            return {"error": "No prompt provided"}


        query_embedding = embed_query(prompt)


        relevant_chunks = query_pinecone(query_embedding, top_k=5)


        context = "\n\n---\n\n".join(relevant_chunks)


        system_message = {
            "role": "system",
            "content": (
                f"You are LexAI, a legal assistant specializing in Michigan legislation. "
                f"Answer the user's question based on the following legislation excerpts. "
                f"If the excerpts don't contain relevant information, say so honestly. "
                f"Respond in {language}.\n\n"
                f"RELEVANT LEGISLATION:\n{context}"
            ),
        }

        messages = [system_message] + chat_history + [{"role": "user", "content": prompt}]


        response_text = call_runpod(messages)

        return {"response": response_text}

    except Exception as e:
        return {"error": str(e)}