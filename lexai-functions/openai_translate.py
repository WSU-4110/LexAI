"""OpenAI translation: chat → English for RunPod; RunPod reply → UI language."""

from __future__ import annotations

import json
import os
from typing import Any

from openai import OpenAI

_BATCH_SYSTEM = """You translate legal app chat fragments to English for a downstream English-only legal model.

Rules:
- Output ONLY one JSON object. No markdown code fences. No commentary before or after JSON.
- Exact shape: {"items":[{"i":<int>,"t":"<english text>"}]}
- The same integer keys `i`, same count, and same order as in the input.
- Preserve statute identifiers, MCL / Michigan references, section numbers, docket-style numbers, and party names.
- Do not add legal analysis or advice — translation only.
"""

_OUT_SYSTEM_TEMPLATE = """Translate the assistant message from English into {target_language}.

Rules:
- Preserve citations, statute and section numbers, lists, and paragraph breaks where possible.
- Output only the translated text — no preamble, no quotes, no markdown wrapper."""


def is_ui_english(language: str | None) -> bool:
    s = (language or "").strip().lower()
    return s in ("english", "en", "")


def _client() -> OpenAI:
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY is not set")
    return OpenAI(api_key=api_key)


def translation_model() -> str:
    return os.environ.get("OPENAI_TRANSLATION_MODEL", "gpt-5.1").strip()


def require_openai_if_translating(ui_language: str) -> None:
    if is_ui_english(ui_language):
        return
    if not os.environ.get("OPENAI_API_KEY"):
        raise RuntimeError("OPENAI_API_KEY is required when the UI language is not English")


def _chat_complete(
    client: OpenAI,
    *,
    messages: list[dict[str, str]],
    json_object: bool,
) -> str:
    model = translation_model()
    kwargs: dict[str, Any] = {
        "model": model,
        "messages": messages,
        "temperature": 0.2,
    }
    if json_object:
        kwargs["response_format"] = {"type": "json_object"}
    try:
        resp = client.chat.completions.create(**kwargs, max_completion_tokens=8192)
    except TypeError:
        resp = client.chat.completions.create(**kwargs, max_tokens=8192)
    content = resp.choices[0].message.content
    return (content or "").strip()


def normalize_to_english(
    chat_history: list[Any],
    current_prompt: str,
    ui_language: str,
) -> tuple[list[dict[str, str]], str]:
    """Return (chat_history with English contents, English current user prompt)."""
    history: list[dict[str, str]] = []
    for m in chat_history:
        if not isinstance(m, dict):
            continue
        role = str(m.get("role", "user"))
        content = str(m.get("content", ""))
        history.append({"role": role, "content": content})

    prompt = str(current_prompt)

    if is_ui_english(ui_language):
        return history, prompt

    client = _client()
    payloads: list[dict[str, Any]] = []
    idx = 0
    for m in history:
        payloads.append({"i": idx, "role": m["role"], "t": m["content"]})
        idx += 1
    payloads.append({"i": idx, "role": "user", "t": prompt})
    last_i = idx

    user_payload = json.dumps({"items": payloads}, ensure_ascii=False)
    raw = _chat_complete(
        client,
        messages=[
            {"role": "system", "content": _BATCH_SYSTEM},
            {"role": "user", "content": user_payload},
        ],
        json_object=True,
    )
    data = json.loads(raw or "{}")
    items = data.get("items")
    if not isinstance(items, list) or len(items) != len(payloads):
        raise RuntimeError("OpenAI translation returned invalid items length")

    by_i: dict[int, str] = {}
    for x in items:
        if not isinstance(x, dict) or "i" not in x:
            continue
        by_i[int(x["i"])] = str(x.get("t", ""))

    if len(by_i) != len(payloads):
        raise RuntimeError("OpenAI translation missing segment keys")

    history_en: list[dict[str, str]] = []
    for p in payloads:
        if p["i"] == last_i:
            break
        history_en.append({"role": str(p["role"]), "content": by_i[p["i"]]})
    prompt_en = by_i[last_i]
    return history_en, prompt_en


def translate_english_to_ui_language(text: str, ui_language: str) -> str:
    if is_ui_english(ui_language):
        return text
    client = _client()
    target = (ui_language or "English").strip()
    system = _OUT_SYSTEM_TEMPLATE.format(target_language=target)
    return _chat_complete(
        client,
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": text},
        ],
        json_object=False,
    )
