import json
import os

def clean_text(text):
    text = text.replace("\r", " ").replace("\n", " ")

    text = " ".join(text.split())
    return text

base_dir = os.path.dirname(os.path.abspath(__file__))
file_path = os.path.join(base_dir, "bill_chunks.json")

# load data
with open(file_path, "r") as f:
    data = json.load(f)

# clean data
for item in data:
    item["chunk_text"] = clean_text(item["chunk_text"])

# save cleaned version
with open("bill_chunks_cleaned.json", "w") as f:
    json.dump(data, f, indent=2)
