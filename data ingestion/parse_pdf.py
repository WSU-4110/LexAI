import json
import requests
from bs4 import BeautifulSoup

INPUT_FILE = "data/bill_details.json"
OUTPUT_FILE = "data/bill_text.json"

#takes bill_details json and uses BeautifulSoup to parse the bill contents text and store in another json.

def extract_bill_text():
    with open(INPUT_FILE, "r") as f:
        bills = json.load(f)

    all_bills_text = []

    for bill in bills:
        identifier = bill['identifier']
        links = bill.get("versions", [])
        html_link = next(
            (link["url"]
            for version in bill.get("versions", [])
            for link in version.get("links", [])
            if link["media_type"] == "text/html"), None)
    
        if not html_link:
            print(f"No HTML link found for {identifier}, skipping")
            continue
        print(f"Parsing {identifier} from HTML page")

        response = requests.get(html_link)
        if response.status_code != 200:
            print(f"Failed to fetch {html_link}")
            continue
        soup = BeautifulSoup(response.text, "html.parser")

        #getting the text from the page 
        text = soup.get_text(separator= " ", strip = True)

        all_bills_text.append({
            "id": bill["id"],
            "identifier": identifier,
            "text": text,
            "source_url": html_link
        })

    with open(OUTPUT_FILE, "w") as f:
        json.dump(all_bills_text, f, indent=2)
    print(f"Extracted text for {len(all_bills_text)} bills, saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    extract_bill_text()