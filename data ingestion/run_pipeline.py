from fetch_bill_details import fetch_bill_details
from parse_pdf import extract_bill_text
from chunk_text import store_in_chunks

def run_pipeline():
    print("Step 1: Fetching bill details...")
    fetch_bill_details()

    print("Step 2: Parsing text...")
    extract_bill_text()

    print("Step 3: Chunking text...")
    store_in_chunks()

    #print("Step 4: Embedding and storing in pinecone...")
    #embed_and_store()

    print("pipeline complete!")

if __name__ == "__main__":
    run_pipeline()