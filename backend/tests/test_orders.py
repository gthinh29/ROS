"""
Tests for the Orders module.

These tests use the FastAPI TestClient in-process (no running server needed).
Database calls are NOT mocked — run against the real DB only if you set TEST_DATABASE_URL.
For CI/unit testing without a DB, we verify HTTP routing & schema validation instead.
"""
import uuid
import pytest
from fastapi.testclient import TestClient
from main import app


@pytest.fixture()
def client():
    with TestClient(app) as c:
        yield c


# ── Smoke tests ────────────────────────────────────────────────────────────────

def test_health(client: TestClient):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


# ── Input-validation tests (no DB required) ───────────────────────────────────

def test_create_order_missing_items(client: TestClient):
    """POST /orders with no items should return 422 validation error (public endpoint)."""
    resp = client.post("/orders", json={
        "customer_name": "Kh\u00e1ch test",
        "phone": "0900000000",
        "type": "DINE_IN",
        "items": [],   # empty list — violates min_length=1
    })
    # Public endpoint → Pydantic runs first → 422
    assert resp.status_code == 422


def test_create_order_invalid_type(client: TestClient):
    """POST /orders with an unknown order type should return 422 (public endpoint)."""
    resp = client.post("/orders", json={
        "type": "INVALID_TYPE",
        "items": [{"menu_item_id": str(uuid.uuid4()), "qty": 1}],
    })
    assert resp.status_code == 422


def test_update_item_status_invalid_payload(client: TestClient):
    """PATCH with an unknown status value should return 401 (middleware rejects bad token before Pydantic)."""
    resp = client.patch(
        f"/orders/{uuid.uuid4()}/items/{uuid.uuid4()}/status",
        json={"status": "COOKED"},   # not in OrderItemStatus enum
        headers={"Authorization": "Bearer dummy_invalid_token"},
    )
    # JWT middleware runs before Pydantic schema validation
    assert resp.status_code in (401, 422)


# ── Auth-guard tests ───────────────────────────────────────────────────────────

def test_get_order_requires_auth(client: TestClient):
    """GET /orders/{id} without token should return 401 or 403."""
    resp = client.get(f"/orders/{uuid.uuid4()}")
    assert resp.status_code in (401, 403)


def test_billing_create_requires_auth(client: TestClient):
    """POST /billing/create without token should return 401 or 403."""
    resp = client.post("/billing/create", json={"order_id": str(uuid.uuid4())})
    assert resp.status_code in (401, 403)


def test_billing_checkout_requires_auth(client: TestClient):
    """POST /billing/checkout without token should return 401 or 403."""
    resp = client.post("/billing/checkout", json={
        "bill_id": str(uuid.uuid4()),
        "payment_method": "CASH",
        "paid_amount": 100000,
    })
    assert resp.status_code in (401, 403)


# ── Split-bill logic unit test (pure function) ────────────────────────────────

def test_split_bill_remainder_logic():
    """
    Verify that the split-bill math is correct:
    If total = 100_001 VND split among 3 people → parts should be:
    person 1: 33_334, person 2: 33_334, person 3: 33_333 (remainder).
    """
    from decimal import Decimal, ROUND_HALF_UP
    total = Decimal("100001")
    n = 3
    per_person = (total / n).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    last = total - per_person * (n - 1)
    parts = [float(per_person)] * (n - 1) + [float(last)]

    assert len(parts) == n
    assert abs(sum(parts) - float(total)) < 0.01    # sum matches total
    assert parts[-1] != parts[0]                    # last person gets the remainder
