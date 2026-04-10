import json
import requests
from firebase_functions import https_fn
from firebase_admin import initialize_app
import os
from dotenv import load_dotenv

load_dotenv()

# --- Config ---
PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")
PINECONE_INDEX_HOST = os.getenv("PINECONE_INDEX_HOST")
RUNPOD_API_KEY = os.getenv("RUNPOD_API_KEY")
RUNPOD_ENDPOINT_ID = os.getenv("RUNPOD_ENDPOINT_ID")
EMBED_MODEL = "multilingual-e5-large"

initialize_app()


def embed_query(query_text: str) -> list:
    """Embed the user's query using Pinecone's inference API."""
    response = requests.post(
        "https://api.pinecone.io/embed",
        headers={
            "Api-Key": PINECONE_API_KEY,
            "Content-Type": "application/json",
        },
        json={
            "model": EMBED_MODEL,
            "inputs": [{"text": query_text}],
            "parameters": {"input_type": "query", "truncate": "END"},
        },
    )
    response.raise_for_status()
    return response.json()["data"][0]["values"]


def query_pinecone(query_embedding: list, top_k: int = 5) -> list:
    """Query Pinecone for the most relevant legislation chunks."""
    response = requests.post(
        f"https://{PINECONE_INDEX_HOST}/query",
        headers={
            "Api-Key": PINECONE_API_KEY,
            "Content-Type": "application/json",
        },
        json={
            "vector": query_embedding,
            "topK": top_k,
            "includeMetadata": True,
        },
    )
    response.raise_for_status()
    matches = response.json().get("matches", [])
    return [match["metadata"]["chunk_text"] for match in matches]


def call_runpod(messages: list) -> str:
    """Send the full prompt to RunPod and wait for the response."""
    # Use the /run endpoint (async) and poll for result
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

    # Poll for completion (max ~60 seconds)
    import time

    for _ in range(30):
        status_response = requests.get(
            f"https://api.runpod.ai/v2/{RUNPOD_ENDPOINT_ID}/status/{job_id}",
            headers={"Authorization": f"Bearer {RUNPOD_API_KEY}"},
        )
        status_response.raise_for_status()
        result = status_response.json()

        if result["status"] == "COMPLETED":
            # Extract the assistant's message from the OpenAI-format response
            output = result.get("output", {})
            choices = output.get("choices", [])
            if choices:
                return choices[0]["message"]["content"]
            return "No response generated."

        if result["status"] == "FAILED":
            return f"Error: RunPod job failed - {result.get('error', 'unknown error')}"

        time.sleep(2)

    return "Error: Request timed out."


@https_fn.on_call()
def chat(req: https_fn.CallableRequest) -> dict:
    """
    Main endpoint called by the iOS app.

    Expects:
        req.data = {
            "prompt": "user's question",
            "chat_history": [
                {"role": "user", "content": "..."},
                {"role": "assistant", "content": "..."}
            ],
            "language": "en"  # optional
        }
    """
    try:
        prompt = req.data.get("prompt", "")
        chat_history = req.data.get("chat_history", [])
        language = req.data.get("language", "en")

        if not prompt:
            return {"error": "No prompt provided"}

        # 1. Embed the user's query
        query_embedding = embed_query(prompt)

        # 2. Query Pinecone for relevant legislation
        relevant_chunks = query_pinecone(query_embedding, top_k=5)

        # 3. Build the context string
        context = "\n\n---\n\n".join(relevant_chunks)

        # 4. Build the full message list
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

        # 5. Call RunPod
        response_text = call_runpod(messages)

        return {"response": response_text}

    except Exception as e:
        return {"error": str(e)}