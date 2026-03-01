from models import Bill

#design pattern (factory)

class BillsFactory:
    @staticmethod
    def create_from_api_data(api_data):
        chamber = None
        if api_data.get("from_organization"):
            chamber = api_data["from_organization"].get("name")

        return Bill(
            id=api_data.get("id"),
            identifier=api_data.get("identifier"),
            title=api_data.get("title"),
            session=api_data.get("session"),
            chamber=chamber,
            updated_at=api_data.get("updated_at"),
            url=api_data.get("openstates_url")
        )