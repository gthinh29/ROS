import asyncio
import uuid
from datetime import datetime, timezone
from types import SimpleNamespace

import pytest

from core.enums import OrderType, ReservationStatus, TableStatus
from modules.reservations import services as reservation_services
from modules.reservations.schemas import ReservationItemCreate


class FakeDB:
    def __init__(self, reservation=None, table=None):
        self.reservation = reservation
        self.table = table
        self.added = []
        self.commits = 0
        self.refreshes = []
        self.flushed = 0

    def get(self, model, obj_id):
        if model.__name__ == "Reservation":
            return self.reservation
        if model.__name__ == "Table":
            return self.table
        return None

    def add(self, obj):
        self.added.append(obj)

    def flush(self):
        self.flushed += 1

    def commit(self):
        self.commits += 1

    def refresh(self, obj):
        self.refreshes.append(obj)


def test_create_reservation_marks_table_reserved():
    table = SimpleNamespace(id=uuid.uuid4(), status=TableStatus.EMPTY)
    fake_db = FakeDB(table=table)

    payload = reservation_services.ReservationCreate(
        table_id=table.id,
        customer_name="An",
        phone="0900000000",
        reserved_at=datetime.now(timezone.utc),
        party_size=2,
        pre_order_items=[
            ReservationItemCreate(
                menu_item_id=uuid.uuid4(),
                qty=1,
            )
        ],
    )

    reservation = asyncio.run(reservation_services.create_reservation(fake_db, payload))

    assert table.status == TableStatus.RESERVED
    assert reservation.status == ReservationStatus.PENDING
    assert len(fake_db.added) == 2


def test_checkin_with_preorder_invokes_order_creation(monkeypatch):
    reservation = SimpleNamespace(
        id=uuid.uuid4(),
        table_id=uuid.uuid4(),
        customer_name="An",
        phone="0900000000",
        status=ReservationStatus.PENDING,
        items=[
            SimpleNamespace(
                menu_item_id=uuid.uuid4(),
                variant_id=None,
                modifier_ids=None,
                qty=1,
                note=None,
            )
        ],
    )
    table = SimpleNamespace(id=reservation.table_id, status=TableStatus.RESERVED)
    fake_db = FakeDB(reservation=reservation, table=table)

    created_payloads = []

    async def fake_create_order(db, order_payload):
        created_payloads.append(order_payload)
        return SimpleNamespace(id=uuid.uuid4())

    import modules.orders.services as orders_services

    monkeypatch.setattr(orders_services, "create_order", fake_create_order)
    monkeypatch.setattr(reservation_services, "OrderCreate", lambda **kwargs: SimpleNamespace(**kwargs), raising=False)
    monkeypatch.setattr(reservation_services, "OrderItemCreate", lambda **kwargs: SimpleNamespace(**kwargs), raising=False)

    result = asyncio.run(reservation_services.checkin(fake_db, reservation.id))

    assert table.status == TableStatus.OCCUPIED
    assert result.table_id == table.id
    assert created_payloads[0].type == OrderType.PRE_ORDER


def test_cancel_checked_in_reservation_raises():
    reservation = SimpleNamespace(id=uuid.uuid4(), table_id=None, status=ReservationStatus.CHECKED_IN)
    fake_db = FakeDB(reservation=reservation)

    with pytest.raises(reservation_services.HTTPException) as exc_info:
        asyncio.run(reservation_services.cancel_reservation(fake_db, reservation.id))

    assert exc_info.value.status_code == 400
