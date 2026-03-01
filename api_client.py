import requests
import time

class OpenStatesClient:
    BASE_URL = "https://v3.openstates.org"
    BILLS_ENDPT = "/bills"

    def __init__(self, api_key):
        self.headers = {"X-API-KEY": api_key}
    def fetch_michigan_bills(self):
        page = 1
        all_results = []

        while True:
            params = {
                "jurisdiction": "Michigan",
                "page": page
            }

            response = requests.get(
                self.BASE_URL + self.BILLS_ENDPT,
                headers = self.headers,
                params = params
            )

            if response.status_code != 200:
                break

            data = response.json()
            results = data.get("results",[])

            if not results:
                break
            all_results.extend(results)
            page += 1
            time.sleep(3)
        
        return all_results