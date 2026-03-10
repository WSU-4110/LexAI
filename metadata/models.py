class Bill:
    def __init__(self, id, identifier, title, session, chamber, updated_at, url):
        self.id = id
        self.identifier = identifier
        self.title = title
        self.session = session
        self.chamber = chamber
        self.updated_at = updated_at
        self.url = url

    def to_dict(self):
        return {
            "id": self.id,
            "identifier": self.identifier,
            "title": self.title,
            "session": self.session,
            "chamber": self.chamber,
            "updated_at": self.updated_at,
            "url": self.url
        }