"""Firebase Cloud Function backend for LexAI.

Implements the RAG pipeline: retrieve legal context from Pinecone and
generate answers through the RunPod-hosted model.
"""

import os
import threading
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
_PINECONE_LOCK = threading.Lock()


def _get_pinecone() -> tuple[Pinecone, Any]:
    """Lazy Pinecone client; thread-safe init for concurrent invocations."""
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
    """Convert user text into an embedding vector.

    Args:
        query_text: Raw query text.
    Returns:
        List of float values for Pinecone search.
    """
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


def _extract_matches(results: Any) -> list[Any]:
    """Support both dict-like and object-like Pinecone query responses."""
    if isinstance(results, dict):
        return results.get("matches", []) or []
    matches = getattr(results, "matches", None)
    if matches is not None:
        return list(matches)
    if hasattr(results, "to_dict"):
        return (results.to_dict() or {}).get("matches", []) or []
    return []


def _extract_metadata(match: Any) -> Any:
    """Support both dict-like and object-like Pinecone match records."""
    if isinstance(match, dict):
        return match.get("metadata")
    metadata = getattr(match, "metadata", None)
    if metadata is not None:
        return metadata
    if hasattr(match, "to_dict"):
        return (match.to_dict() or {}).get("metadata")
    return None


def query_pinecone(query_embedding: list, top_k: int = 5) -> list:
    """Fetch top legislation chunks from Pinecone.

    Args:
        query_embedding: Embedding vector for lookup.
        top_k: Number of matches to retrieve.
    Returns:
        List of chunk text strings from top metadata matches.
    """
    _, index = _get_pinecone()
    # Prefer chunk vectors (embed_and_store sets chunk_idx). If index has no chunk_idx, fall back unfiltered.
    for use_chunk_filter in (True, False):
        kwargs: dict[str, Any] = {
            "vector": query_embedding,
            "top_k": top_k,
            "include_metadata": True,
        }
        if use_chunk_filter:
            kwargs["filter"] = {"chunk_idx": {"$gte": 0}}
        try:
            results = index.query(**kwargs)
        except Exception:
            if use_chunk_filter:
                # Some indexes don't support this metadata filter shape; retry unfiltered.
                continue
            raise
        chunks: list[str] = []
        for match in _extract_matches(results):
            text = _legislation_text_from_metadata(_extract_metadata(match))
            if text:
                chunks.append(text)
        if chunks:
            return chunks
    raise RuntimeError(
        "No usable legislation text in Pinecone results (metadata missing text fields or index empty)."
    )


def call_runpod(messages: list) -> str:
    """Call RunPod chat completion and return generated text.

    Args:
        messages: OpenAI-style role/content messages.
    Returns:
        Generated text or an error string after polling for completion.
    """
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
                    # Fine-tuned LLaMA 3 8B via QLoRA (4-bit NF4 + LoRA adapters)
                    # on Michigan legal Q&A + IDK examples, then merged for RunPod.
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
    """Handle Firebase callable chat requests.

    Args:
        req: Request with `prompt` and optional `chat_history`/`language` in `req.data`.
    Returns:
        `{"response": text}` on success or `{"error": message}` on failure.
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

        # This prompt line reinforces fine-tuned IDK/unlearning behavior so the
        # model declines out-of-scope questions when excerpts are insufficient.
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
