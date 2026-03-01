import os
import json
from api_client import OpenStatesClient
from factory import BillsFactory

#main file

API_KEY = os.getenv("OPENSTATES_API_KEY")

if not API_KEY:
    raise RuntimeError("API key not set in environment variables.")

client = OpenStatesClient(API_KEY)
raw_bills = client.fetch_michigan_bills()
print("Number of raw bills: ", len(raw_bills))

bill_objects = []

for raw in raw_bills:
    bill = BillsFactory.create_from_api_data(raw)
    bill_objects.append(bill.to_dict())

with open("michigan_bills_metadata.json", "w", encoding = "utf-8") as f:
    json.dump(bill_objects, f, indent=2)

print("saved structured bill metadata. ")

