import os
import requests
import time
import json

API_KEY = os.getenv("OPENSTATES_API_KEY")

if not API_KEY:
    raise RuntimeError("API key not set in environment variables.")

BASE_URL = "https://v3.openstates.org"
BILLS_ENDPT = "/bills"
url = BASE_URL + BILLS_ENDPT

HEADERS = {"X-API-KEY": API_KEY}

page = 1
all_bills = []

print("Fetching Michigan's legislative data..")

while True:
    params = {
        "jurisdiction": "Michigan",
        "page": page
    }

    response = requests.get(url, headers = HEADERS, params = params)

    if response.status_code != 200:
        print(f"Error on page {page}: {response.status_code}")
        break

    data = response.json()
    results = data.get("results",[])

    if not results:
        break
    all_bills.extend(results)
    print(f"Fetched page {page} ({len(results)} bills)")
    page +=1

    time.sleep(3)
print(f"\nTotal bills fetched: {len(all_bills)}")
with open("michigan_bills.json","w",encoding="utf-8") as f:
    json.dump(all_bills, f, indent = 2)

# saves metadata to json file, not actual bill documents
print("Saved data to michigan_bills.json")
