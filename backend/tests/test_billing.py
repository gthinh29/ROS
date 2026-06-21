import asyncio
import uuid
from types import SimpleNamespace

import pytest

from core.enums import BillStatus, OrderItemStatus, PaymentMethod
from modules.billing import services as billing_services


class FakeQuery:
    def __init__(self, result=None):
        self.result = result

    def filter(self, *args, **kwargs):
        return self

    def first(self):
        return self.result


class FakeDB:
    def __init__(self, order=None, existing_pending=None, existing_paid=None, bill=None, restaurant=None, table=None):
        self.order = order
        self.existing_pending = existing_pending
        self.existing_paid = existing_paid
        self.bill = bill
        self.restaurant = restaurant
        self.table = table
        self.commits = 0
        self.refreshed = []
        self.added = []

    def get(self, model, obj_id):
        if model.__name__ == "Order":
            return self.order
        if model.__name__ == "Bill":
            return self.bill
        if model.__name__ == "Table":
            return self.table
        if model.__name__ == "Restaurant":
            return self.restaurant
        return None

    def query(self, model):
        if model.__name__ == "Bill":
            if self.existing_pending is not None:
                return FakeQuery(self.existing_pending)
            if self.existing_paid is not None:
                return FakeQuery(self.existing_paid)
        return FakeQuery()

    def add(self, obj):
        self.added.append(obj)

    def commit(self):
        self.commits += 1

    def refresh(self, obj):
        self.refreshed.append(obj)


def test_create_bill_applies_settings_and_totals():
    order = SimpleNamespace(
        id=uuid.uuid4(),
        table_id=uuid.uuid4(),
        items=[
            SimpleNamespace(status=OrderItemStatus.READY, price=100.0, qty=2),
            SimpleNamespace(status=OrderItemStatus.SERVED, price=50.0, qty=1),
            SimpleNamespace(status=OrderItemStatus.PENDING, price=999.0, qty=1),
        ],
    )
    table = SimpleNamespace(id=order.table_id, restaurant_id=uuid.uuid4())
    restaurant = SimpleNamespace(settings={"vat_rate": 0.1, "service_fee_rate": 0.05})
    fake_db = FakeDB(order=order, restaurant=restaurant, table=table)

    bill = asyncio.run(billing_services.create_bill(fake_db, billing_services.BillCreate(order_id=order.id)))

    assert bill.subtotal == 250.0
    assert bill.tax == 25.0
    assert bill.service_fee == 12.5
    assert bill.total == 287.5


def test_split_bill_evenly_keeps_remainder_last_person():
    bill = SimpleNamespace(id=uuid.uuid4(), total=100001, status=BillStatus.PENDING)
    fake_db = FakeDB(bill=bill)

    result = asyncio.run(billing_services.split_bill_evenly(fake_db, bill.id, 3))

    assert result.split_count == 3
    assert result.parts[0].amount == 33333.67
    assert round(sum(part.amount for part in result.parts), 2) == 100001.00


def test_checkout_cash_insufficient_raises():
    bill = SimpleNamespace(id=uuid.uuid4(), order_id=uuid.uuid4(), total=100.0, status=BillStatus.PENDING)
    fake_db = FakeDB(bill=bill)

    payload = billing_services.CheckoutRequest(
        bill_id=bill.id,
        payment_method=PaymentMethod.CASH,
        paid_amount=50.0,
    )

    with pytest.raises(billing_services.HTTPException) as exc_info:
        asyncio.run(billing_services.checkout(fake_db, payload))

    assert exc_info.value.status_code == 422
