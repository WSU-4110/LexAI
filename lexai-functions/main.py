"""Firebase callable entrypoint for LexAI chat.

Pipeline: optional translation of user + history into English, embed the English prompt,
retrieve Michigan legislation chunks from Pinecone, call the English-only RunPod legal
model, then translate the assistant reply back to the client's UI language when needed.

Pinecone is initialized lazily so deploy-time import/discovery does not require
``PINECONE_API_KEY`` until a request actually runs.
"""

import os
import time
from typing import Any

import requests
from firebase_functions import https_fn
from firebase_functions.params import SecretParam, StringParam
from firebase_admin import initialize_app
from pinecone import Pinecone
from dotenv import load_dotenv

from openai_translate import (
    normalize_to_english,
    require_openai_if_translating,
    translate_english_to_ui_language,
)

load_dotenv()

# --- Secret Manager (bind in @https_fn.on_call); runtime values appear in os.environ ---
OPENAI_API_KEY = SecretParam("OPENAI_API_KEY")
PINECONE_API_KEY = SecretParam("PINECONE_API_KEY")
RUNPOD_API_KEY = SecretParam("RUNPOD_API_KEY")

# --- Deploy-time / runtime params (non-secret); also read from lexai-functions/.env on deploy ---
RUNPOD_ENDPOINT_ID = StringParam(
    "RUNPOD_ENDPOINT_ID",
    label="RunPod endpoint ID",
    description="Serverless endpoint ID from the RunPod console (v2 API path segment).",
)
OPENAI_TRANSLATION_MODEL = StringParam(
    "OPENAI_TRANSLATION_MODEL",
    default="gpt-5.1",
    label="OpenAI translation model",
    description="Model id for translating non-English UI around RunPod.",
)

INDEX_NAME = "michigan-legislation"
EMBED_MODEL = "multilingual-e5-large"

initialize_app()

_PINECONE_CLIENT: Pinecone | None = None
_PINECONE_INDEX: Any = None


def _get_pinecone() -> tuple[Pinecone, Any]:
    """Lazy Pinecone client so deploy-time discovery does not require API keys at import."""
    global _PINECONE_CLIENT, _PINECONE_INDEX
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


def query_pinecone(query_embedding: list, top_k: int = 5) -> list:
    _, index = _get_pinecone()
    results = index.query(
        vector=query_embedding,
        top_k=top_k,
        include_metadata=True,
    )
    return [match["metadata"]["chunk_text"] for match in results["matches"]]


def call_runpod(messages: list) -> str:
    """POST to RunPod serverless ``/run``, then poll ``/status`` until COMPLETED or timeout."""
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

    # Poll for completion, max 5 minutes
    for _ in range(150):
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
    timeout_sec=300,
    secrets=[OPENAI_API_KEY, PINECONE_API_KEY, RUNPOD_API_KEY],
)
def chat(req: https_fn.CallableRequest) -> dict:
    """HTTPS callable: ``req.data`` may include ``prompt``, ``chat_history``, ``language`` (default ``en``).

    Returns ``{"response": str}`` on success or ``{"error": str}`` on validation/runtime failure.
    """
    try:
        prompt = req.data.get("prompt", "")
        chat_history = req.data.get("chat_history", [])
        language = req.data.get("language", "en")

        if not prompt:
            return {"error": "No prompt provided"}

        require_openai_if_translating(language)

        history_en, prompt_en = normalize_to_english(chat_history, prompt, language)

        query_embedding = embed_query(prompt_en)

        relevant_chunks = query_pinecone(query_embedding, top_k=5)

        context = "\n\n---\n\n".join(relevant_chunks)

        system_message = {
            "role": "system",
            "content": (
                "You are LexAI, a legal assistant specializing in Michigan legislation. "
                "Answer the user's question based on the following legislation excerpts. "
                "If the excerpts don't contain relevant information, say so honestly. "
                "Write your entire answer in clear English.\n\n"
                f"RELEVANT LEGISLATION:\n{context}"
            ),
        }

        messages = [system_message] + history_en + [{"role": "user", "content": prompt_en}]

        response_en = call_runpod(messages)
        response_text = translate_english_to_ui_language(response_en, language)

        return {"response": response_text}

    except Exception as e:
        return {"error": str(e)}
