#!/usr/bin/env python3
"""One-off: print Pinecone match metadata keys + sample dict for michigan-legislation.

Run from repo root or lexai-functions:
  cd lexai-functions && python inspect_pinecone_metadata.py

Requires PINECONE_API_KEY in environment or .env in this directory.
"""
from __future__ import annotations

import json
import os
import sys

from dotenv import load_dotenv
from pinecone import Pinecone

load_dotenv()

INDEX_NAME = "michigan-legislation"
EMBED_MODEL = "multilingual-e5-large"
QUERY = "michigan landlord tenant law"


def main() -> int:
    api_key = (os.environ.get("PINECONE_API_KEY") or "").strip()
    if not api_key:
        print("PINECONE_API_KEY is not set", file=sys.stderr)
        return 1

    pc = Pinecone(api_key=api_key)
    index = pc.Index(INDEX_NAME)

    try:
        stats = index.describe_index_stats()
        print("--- describe_index_stats ---")
        print(json.dumps(stats.to_dict() if hasattr(stats, "to_dict") else str(stats), indent=2, default=str))
    except Exception as e:
        print(f"describe_index_stats failed: {e}", file=sys.stderr)

    emb = pc.inference.embed(
        model=EMBED_MODEL,
        inputs=[QUERY],
        parameters={"input_type": "query", "truncate": "END"},
    )
    vector = emb[0]["values"]

    results = index.query(
        vector=vector,
        top_k=5,
        include_metadata=True,
    )

    matches = results.get("matches") or []
    print(f"\n--- query top_k=5 (no filter), matches={len(matches)} ---")
    for i, m in enumerate(matches):
        meta = m.get("metadata")
        keys = sorted(meta.keys()) if isinstance(meta, dict) else []
        print(f"\nmatch[{i}] id={m.get('id')} score={m.get('score')} metadata_keys={keys}")
        if isinstance(meta, dict):
            print(json.dumps(meta, indent=2, default=str)[:4000])
            if len(json.dumps(meta, default=str)) > 4000:
                print("... (truncated)")

    # Same query with chunk filter (matches embed_and_store chunk vectors)
    results2 = index.query(
        vector=vector,
        top_k=5,
        include_metadata=True,
        filter={"chunk_idx": {"$gte": 0}},
    )
    matches2 = results2.get("matches") or []
    print(f"\n--- query with filter chunk_idx>=0, matches={len(matches2)} ---")
    if matches2:
        m0 = matches2[0]
        meta0 = m0.get("metadata") or {}
        print("first match metadata keys:", sorted(meta0.keys()) if isinstance(meta0, dict) else meta0)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
