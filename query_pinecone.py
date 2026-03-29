import os
from dotenv import load_dotenv
from pinecone import Pinecone

load_dotenv()

PINECONE_API_KEY = os.environ.get("PINECONE_API_KEY")
INDEX_NAME = "michigan-legislation"
EMBED_MODEL = "multilingual-e5-large"

pc = Pinecone(api_key=PINECONE_API_KEY)
index = pc.Index(INDEX_NAME)


def search_legislation(query: str, top_k: int = 5):
    """
    Search the Pinecone index for legislation relevant to the query.
    Returns a list of the top_k most relevant chunks with their metadata.
    """
    # Embed the query
    embedding_response = pc.inference.embed(
        model=EMBED_MODEL,
        inputs=[query],
        parameters={"input_type": "query", "truncate": "END"}
    )
    query_vector = embedding_response[0]["values"]

    # Search Pinecone
    results = index.query(
        vector=query_vector,
        top_k=top_k,
        include_metadata=True
    )

    # Format and return results
    matches = []
    for match in results["matches"]:
        matches.append({
            "score":      match["score"],
            "bill_id":    match["metadata"]["bill_id"],
            "identifier": match["metadata"]["identifier"],
            "chunk_idx":  match["metadata"]["chunk_idx"],
            "source_url": match["metadata"]["source_url"],
            "chunk_text": match["metadata"]["chunk_text"]
        })

    return matches


# --- Test block ---
if __name__ == "__main__":
    test_query = "milk regulations dairy farm" # example topic
    print(f"Searching for: '{test_query}'\n")

    results = search_legislation(test_query, top_k=3)

    for i, r in enumerate(results):
        print(f"Result {i+1} — {r['identifier']} (chunk {r['chunk_idx']}) | score: {r['score']:.4f}")
        print(f"  URL: {r['source_url']}")
        print(f"  Text preview: {r['chunk_text'][:200]}...")
        print()