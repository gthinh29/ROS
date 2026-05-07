import uuid

from modules.tables import services as table_services


class FakeDB:
    def __init__(self):
        self.added = []
        self.commits = 0
        self.refreshed = []

    def add(self, obj):
        self.added.append(obj)

    def commit(self):
        self.commits += 1

    def refresh(self, obj):
        self.refreshed.append(obj)

    def query(self, model):
        class Query:
            def order_by(self, *args, **kwargs):
                return self

            def filter(self, *args, **kwargs):
                return self

            def first(self):
                return None

            def all(self):
                return []

        return Query()


def test_create_table_initializes_empty_status():
    fake_db = FakeDB()
    table_in = table_services.TableCreate(
        zone="A",
        number=1,
        restaurant_id=uuid.uuid4(),
    )

    table = table_services.create_table(fake_db, table_in)

    assert table.status == table_services.TableStatus.EMPTY
    assert table.qr_token
    assert fake_db.commits == 1


def test_generate_qr_code_png_returns_png_bytes():
    data = table_services.generate_qr_code_png("token-123")

    assert isinstance(data, bytes)
    assert data.startswith(b"\x89PNG")
