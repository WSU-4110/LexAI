import json
import requests
import os
import time

#goes through metadata and stores each bill's data separately in one json, this contains the direct url to text
API_KEY = os.getenv("OPENSTATES_API_KEY")
print("api key: ", API_KEY)

INPUT_FILE = "data/michigan_bills_metadata.json"
OUTPUT_FILE = "data/bill_details.json"

BASE_URL = "https://v3.openstates.org/bills/"

headers = {
    "X-API-KEY": API_KEY
}

def fetch_bill_details():
    with open(INPUT_FILE, "r") as f:
        bills = json.load(f)
    
    bill_details = []

    for bill in bills:
        bill_id = bill["id"]
        print(f"Fetching {bill['identifier']}") #debug print
        url = f"{BASE_URL}{bill_id}?include=versions"
        response = requests.get(url, headers=headers)
        time.sleep(3)

        if response.status_code == 200:
            data = response.json()
            bill_details.append(data)
        else:
            print("Failed:", bill_id)
    with open(OUTPUT_FILE, "w") as f:
        json.dump(bill_details, f, indent=2)

if __name__ == "__main__":
    fetch_bill_details()