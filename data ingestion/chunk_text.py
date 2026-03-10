import json

INPUT_FILE = "data/bill_text.json"
OUTPUT_FILE = "data/bill_chunks.json"
#takes json with bill text and breaks it up into chunks, easier to store in pinecone db. each chunk has overlap so ai doesn't lose context

def store_in_chunks():
    with open(INPUT_FILE, "r") as f:
        bills = json.load(f)
    
    all_chunks = []

    for bill in bills:
        text = bill["text"]
        bill_id = bill["id"]

        chunk_size = 2000
        overlap = 200
        start = 0
        chunk_idx = 0

        while start < len(text):
            end = start + chunk_size
            chunk_text = text[start:end]
            
            all_chunks.append({
                "bill_id": bill_id,
                "identifier": bill["identifier"],
                "chunk_idx": chunk_idx,
                "chunk_text": chunk_text,
                "source_url": bill["source_url"]
            })

            start += chunk_size - overlap
            chunk_idx += 1
    
    with open(OUTPUT_FILE, "w") as f:
        json.dump(all_chunks, f, indent=2)

if __name__ == "__main__":
    store_in_chunks()