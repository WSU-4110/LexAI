import os
import threading
import time
import requests
from firebase_functions import https_fn
from firebase_functions.params import SecretParam, StringParam
from firebase_admin import initialize_app
from pinecone import Pinecone
from dotenv import load_dotenv
from typing import Any

load_dotenv()

# --- Secret Manager params (injected into os.environ at request time) ---
OPENAI_API_KEY = SecretParam("OPENAI_API_KEY")
PINECONE_API_KEY = SecretParam("PINECONE_API_KEY")
RUNPOD_API_KEY = SecretParam("RUNPOD_API_KEY")

# --- Deploy-time / runtime params ---
RUNPOD_ENDPOINT_ID = StringParam(
    "RUNPOD_ENDPOINT_ID",
    label="RunPod endpoint ID",
    description="Serverless endpoint ID from the RunPod console.",
)

INDEX_NAME = "michigan-legislation"
EMBED_MODEL = "multilingual-e5-large"

initialize_app()

_PINECONE_CLIENT: Pinecone | None = None
_PINECONE_INDEX: Any = None
_PINECONE_LOCK = threading.Lock()


def _get_pinecone() -> tuple[Pinecone, Any]:
    """Lazy Pinecone init so secrets are available at request time, not import time."""
    global _PINECONE_CLIENT, _PINECONE_INDEX
    if _PINECONE_CLIENT is not None and _PINECONE_INDEX is not None:
        return _PINECONE_CLIENT, _PINECONE_INDEX
    with _PINECONE_LOCK:
        if _PINECONE_CLIENT is not None and _PINECONE_INDEX is not None:
            return _PINECONE_CLIENT, _PINECONE_INDEX
        api_key = (os.environ.get("PINECONE_API_KEY") or "").strip()
        if not api_key:
            raise RuntimeError("PINECONE_API_KEY is not set")
        _PINECONE_CLIENT = Pinecone(api_key=api_key)
        _PINECONE_INDEX = _PINECONE_CLIENT.Index(INDEX_NAME)
    return _PINECONE_CLIENT, _PINECONE_INDEX


def embed_query(query_text: str) -> list:
    pc, _ = _get_pinecone()
    embeddings_response = pc.inference.embed(
        model=EMBED_MODEL,
        inputs=[query_text],
        parameters={"input_type": "query", "truncate": "END"},
    )
    return embeddings_response[0]["values"]


def _legislation_text_from_metadata(metadata: Any) -> str:
    """Return first non-empty string from known Pinecone metadata text fields."""
    if not isinstance(metadata, dict):
        return ""
    for key in (
        "chunk_text",
        "text",
        "content",
        "chunk",
        "body",
        "passage",
    ):
        val = metadata.get(key)
        if isinstance(val, str) and val.strip():
            return val.strip()
    return ""


def query_pinecone(query_embedding: list, top_k: int = 5) -> list:
    _, index = _get_pinecone()
    # Prefer chunk vectors (embed_and_store sets chunk_idx). If index has no chunk_idx, fall back to unfiltered query.
    for use_chunk_filter in (True, False):
        kwargs: dict[str, Any] = {
            "vector": query_embedding,
            "top_k": top_k,
            "include_metadata": True,
        }
        if use_chunk_filter:
            kwargs["filter"] = {"chunk_idx": {"$gte": 0}}
        results = index.query(**kwargs)
        chunks: list[str] = []
        for match in results.get("matches", []):
            text = _legislation_text_from_metadata(match.get("metadata"))
            if text:
                chunks.append(text)
        if chunks:
            return chunks
    raise RuntimeError(
        "No usable legislation text in Pinecone results (metadata missing text fields or index empty)."
    )


def call_runpod(messages: list) -> str:
    endpoint_id = (os.environ.get("RUNPOD_ENDPOINT_ID") or "").strip()
    runpod_key = (os.environ.get("RUNPOD_API_KEY") or "").strip()
    if not endpoint_id:
        raise RuntimeError("RUNPOD_ENDPOINT_ID is not set")
    if not runpod_key:
        raise RuntimeError("RUNPOD_API_KEY is not set")

    run_response = requests.post(
        f"https://api.runpod.ai/v2/{endpoint_id}/run",
        headers={
            "Authorization": f"Bearer {runpod_key}",
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

    # Poll for completion, max ~8 minutes (matches timeout_sec=540)
    for _ in range(240):
        status_response = requests.get(
            f"https://api.runpod.ai/v2/{endpoint_id}/status/{job_id}",
            headers={"Authorization": f"Bearer {runpod_key}"},
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


@https_fn.on_call(
    enforce_app_check=False,
    timeout_sec=540,
    secrets=[OPENAI_API_KEY, PINECONE_API_KEY, RUNPOD_API_KEY],
)
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