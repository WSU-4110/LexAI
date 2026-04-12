import json
import os
import time
from pinecone import Pinecone, ServerlessSpec

# --- Config ---
PINECONE_API_KEY = os.environ.get("PINECONE_API_KEY") 
INDEX_NAME = "michigan-legislation"
EMBED_MODEL = "multilingual-e5-large"  # Pinecone's embedding model
DIMENSION = 1024                        # output dimension 
BATCH_SIZE = 96                         # max vectors per upsert call

# --- Load cleaned chunks ---
base_dir = os.path.dirname(os.path.abspath(__file__))
file_path = os.path.join(base_dir, "bill_chunks_cleaned.json")

with open(file_path, "r") as f:
    chunks = json.load(f)

pc = Pinecone(api_key=PINECONE_API_KEY)

# create idx
existing_indexes = [idx.name for idx in pc.list_indexes()]

if INDEX_NAME not in existing_indexes:
    print(f"Creating index '{INDEX_NAME}'...")
    pc.create_index(
        name=INDEX_NAME,
        dimension=DIMENSION,
        metric="cosine",
        spec=ServerlessSpec(cloud="aws", region="us-east-1")
    )
    # wait
    while not pc.describe_index(INDEX_NAME).status["ready"]:
        print("Waiting for index to be ready...")
        time.sleep(2)
    print("Index ready.")
else:
    print(f"Index '{INDEX_NAME}' already exists, skipping creation.")

index = pc.Index(INDEX_NAME)

# --- Embed + Upsert in batches ---
def make_vector_id(chunk):
    # Unique ID per chunk: bill_id + chunk index
    safe_bill_id = chunk["bill_id"].replace("/", "_")
    return f"{safe_bill_id}_chunk{chunk['chunk_idx']}"

total = len(chunks)
print(f"Embedding and upserting {total} chunks in batches of {BATCH_SIZE}...")

for i in range(0, total, BATCH_SIZE):
    batch = chunks[i : i + BATCH_SIZE]
    texts = [chunk["chunk_text"] for chunk in batch]

    # Embedding the batch
    embeddings_response = pc.inference.embed(
        model=EMBED_MODEL,
        inputs=texts,
        parameters={"input_type": "passage", "truncate": "END"}
    )

    # Build list of tuples
    vectors = []
    for chunk, embedding in zip(batch, embeddings_response):
        vectors.append({
            "id": make_vector_id(chunk),
            "values": embedding["values"],
            "metadata": {
                "bill_id":    chunk["bill_id"],
                "identifier": chunk["identifier"],
                "chunk_idx":  chunk["chunk_idx"],
                "source_url": chunk["source_url"],
                "chunk_text": chunk["chunk_text"]  # store text for retrieval later
            }
        })

    index.upsert(vectors=vectors)
    print(f"  Upserted chunks {i} – {min(i + BATCH_SIZE, total) - 1}")

print("Done! All chunks embedded and stored in Pinecone.")