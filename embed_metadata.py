import json
import os
from dotenv import load_dotenv
from pinecone import Pinecone

load_dotenv()

PINECONE_API_KEY = os.environ.get("PINECONE_API_KEY")
INDEX_NAME = "michigan-legislation"
EMBED_MODEL = "multilingual-e5-large"
BATCH_SIZE = 96

pc = Pinecone(api_key=PINECONE_API_KEY)
index = pc.Index(INDEX_NAME)

# --- Load metadata JSON ---
base_dir = os.path.dirname(os.path.abspath(__file__))
file_path = os.path.join(base_dir, "data", "michigan_bills_metadata.json")  # update filename if different

with open(file_path, "r") as f:
    bills = json.load(f)

print(f"Loaded {len(bills)} bill metadata records.")

# --- Embed + Upsert in batches ---
for i in range(0, len(bills), BATCH_SIZE):
    batch = bills[i : i + BATCH_SIZE]
    texts = [bill["title"] for bill in batch]

    embeddings_response = pc.inference.embed(
        model=EMBED_MODEL,
        inputs=texts,
        parameters={"input_type": "passage", "truncate": "END"}
    )

    vectors = []
    for bill, embedding in zip(batch, embeddings_response):
        safe_id = bill["id"].replace("/", "_")
        vectors.append({
            "id": f"{safe_id}_meta",  # _meta suffix avoids collision with chunk vectors
            "values": embedding["values"],
            "metadata": {
                "type":         "bill_metadata",  # lets you distinguish from chunk vectors later
                "bill_id":      bill["id"],
                "identifier":   bill["identifier"],
                "title":        bill["title"],
                "session":      bill["session"],
                "chamber":      bill["chamber"],
                "updated_at":   bill["updated_at"],
                "url":          bill["url"]
            }
        })

    index.upsert(vectors=vectors)
    print(f"Upserted records {i} – {min(i + BATCH_SIZE, len(bills)) - 1}")

print("Done! All bill metadata stored in Pinecone.")