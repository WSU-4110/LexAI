import os
from dotenv import load_dotenv
from pinecone import Pinecone

load_dotenv()

PINECONE_API_KEY = os.environ.get("PINECONE_API_KEY")
INDEX_NAME = "michigan-legislation"
EMBED_MODEL = "multilingual-e5-large"

pc = Pinecone(api_key=PINECONE_API_KEY)
index = pc.Index(INDEX_NAME)


def get_bill_metadata(bill_id: str):
    """
    Fetch the metadata vector for a given bill_id.
    Returns metadata dict or None if not found.
    """
    safe_id = bill_id.replace("/", "_")
    meta_vector_id = f"{safe_id}_meta"

    result = index.fetch(ids=[meta_vector_id])

    if meta_vector_id in result["vectors"]:
        return result["vectors"][meta_vector_id]["metadata"]
    return None


def search_legislation(query: str, top_k: int = 5):
    """
    Search the Pinecone index for legislation relevant to the query.
    Returns top_k most relevant chunks, each enriched with its bill metadata.
    """
    # Embed the query
    embedding_response = pc.inference.embed(
        model=EMBED_MODEL,
        inputs=[query],
        parameters={"input_type": "query", "truncate": "END"}
    )
    query_vector = embedding_response[0]["values"]

    # Search Pinecone — filter to chunk vectors only
    results = index.query(
        vector=query_vector,
        top_k=top_k,
        include_metadata=True,
        filter={"chunk_idx": {"$gte": 0}}  # excludes metadata vectors
    )

    # Format results and cross-reference metadata
    matches = []
    for match in results["matches"]:
        bill_id = match["metadata"]["bill_id"]

        # Fetch corresponding metadata
        metadata = get_bill_metadata(bill_id)

        matches.append({
            # Chunk info
            "score":      match["score"],
            "bill_id":    bill_id,
            "identifier": match["metadata"]["identifier"],
            "chunk_idx":  match["metadata"]["chunk_idx"],
            "chunk_text": match["metadata"]["chunk_text"],
            "source_url": match["metadata"]["source_url"],
            # Bill metadata (cross-referenced)
            "title":      metadata.get("title")      if metadata else None,
            "session":    metadata.get("session")    if metadata else None,
            "chamber":    metadata.get("chamber")    if metadata else None,
            "updated_at": metadata.get("updated_at") if metadata else None,
            "bill_url":   metadata.get("url")        if metadata else None,
        })

    return matches


# --- Test block ---
if __name__ == "__main__":
    test_query = "milk regulations dairy farm"
    print(f"Searching for: '{test_query}'\n")

    results = search_legislation(test_query, top_k=3)

    for i, r in enumerate(results):
        print(f"Result {i+1} — {r['identifier']} (chunk {r['chunk_idx']}) | score: {r['score']:.4f}")
        print(f"  Title:      {r['title']}")
        print(f"  Chamber:    {r['chamber']} | Session: {r['session']}")
        print(f"  Updated:    {r['updated_at']}")
        print(f"  Bill URL:   {r['bill_url']}")
        print(f"  Source URL: {r['source_url']}")
        print(f"  Preview:    {r['chunk_text'][:200]}...")
        print()