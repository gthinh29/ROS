"""Business logic for the Billing module.

Responsibilities:
- Create a bill for an order, applying VAT and service fee from restaurant settings.
- Split the bill evenly across N people (last person covers the remainder).
- Checkout: record payment, mark bill as PAID, close table to EMPTY.
"""
from __future__ import annotations

import math
import uuid
from datetime import datetime, timezone
from decimal import ROUND_HALF_UP, Decimal

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from core.enums import BillStatus, OrderStatus, TableStatus
from modules.billing.models import Bill
from modules.billing.schemas import (
    BillCreate,
    CheckoutRequest,
    CheckoutResponse,
    SplitBillPart,
    SplitBillResponse,
)
from modules.orders.models import Order, OrderItem
from modules.tables.models import Restaurant, Table

_DEFAULT_VAT = Decimal("0.08")        # 8%
_DEFAULT_SERVICE_FEE = Decimal("0.05")  # 5%


def _get_restaurant_settings(db: Session, order: Order) -> tuple[Decimal, Decimal]:
    """Return (vat_rate, service_fee_rate) from restaurant.settings JSONB.

    Falls back to the module-level defaults if no settings are found.
    """
    if not order.table_id:
        return _DEFAULT_VAT, _DEFAULT_SERVICE_FEE

    table: Table | None = db.get(Table, order.table_id)
    if not table:
        return _DEFAULT_VAT, _DEFAULT_SERVICE_FEE

    restaurant: Restaurant | None = db.get(Restaurant, table.restaurant_id)
    if not restaurant or not restaurant.settings:
        return _DEFAULT_VAT, _DEFAULT_SERVICE_FEE

    settings = restaurant.settings
    vat = Decimal(str(settings.get("vat_rate", _DEFAULT_VAT)))
    svc = Decimal(str(settings.get("service_fee_rate", _DEFAULT_SERVICE_FEE)))
    return vat, svc


# ── Services ──────────────────────────────────────────────────────────────────

async def create_bill(db: Session, payload: BillCreate) -> Bill:
    """Create a bill for an order, computing subtotal, VAT, and service fee."""
    order: Order | None = db.get(Order, payload.order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    # Check no existing PENDING or PAID bill for this order
    existing = db.query(Bill).filter(Bill.order_id == payload.order_id).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A bill already exists for this order",
        )

    # Subtotal = sum of (price × qty) for all order items
    items: list[OrderItem] = order.items
    subtotal = sum(Decimal(str(item.price)) * item.qty for item in items)

    vat_rate, svc_rate = _get_restaurant_settings(db, order)
    tax = (subtotal * vat_rate).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    service_fee = (subtotal * svc_rate).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    total = subtotal + tax + service_fee

    bill = Bill(
        order_id=order.id,
        subtotal=float(subtotal),
        tax=float(tax),
        service_fee=float(service_fee),
        discount=0.0,
        total=float(total),
        status=BillStatus.PENDING,
    )
    db.add(bill)
    db.commit()
    db.refresh(bill)
    return bill


async def split_bill_evenly(
    db: Session, bill_id: uuid.UUID, split_count: int
) -> SplitBillResponse:
    """Compute split amounts — last person pays the remainder."""
    bill: Bill | None = db.get(Bill, bill_id)
    if not bill:
        raise HTTPException(status_code=404, detail="Bill not found")
    if bill.status == BillStatus.PAID:
        raise HTTPException(status_code=400, detail="Bill is already paid")

    total = Decimal(str(bill.total))
    per_person = (total / split_count).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    last_person = total - per_person * (split_count - 1)

    parts = [
        SplitBillPart(part_index=i + 1, amount=float(per_person))
        for i in range(split_count - 1)
    ]
    parts.append(SplitBillPart(part_index=split_count, amount=float(last_person)))

    return SplitBillResponse(
        bill_id=bill_id,
        split_count=split_count,
        total=float(total),
        parts=parts,
    )


async def checkout(db: Session, payload: CheckoutRequest) -> CheckoutResponse:
    """Record payment, mark bill PAID, close order and return table to EMPTY."""
    bill: Bill | None = db.get(Bill, payload.bill_id)
    if not bill:
        raise HTTPException(status_code=404, detail="Bill not found")
    if bill.status == BillStatus.PAID:
        raise HTTPException(status_code=400, detail="Bill is already paid")

    total = Decimal(str(bill.total))

    # For CASH we require a paid_amount and compute change
    paid_amount = Decimal(str(payload.paid_amount or "0"))
    if payload.payment_method.value == "CASH":
        if paid_amount < total:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Insufficient cash: need {total}, received {paid_amount}",
            )
    else:
        # Card / VietQR — cashier confirms manually; paid_amount = total
        paid_amount = total

    change = max(paid_amount - total, Decimal("0"))

    # Update bill
    bill.status = BillStatus.PAID
    bill.payment_method = payload.payment_method
    bill.paid_amount = float(paid_amount)
    bill.change_amount = float(change)
    bill.paid_at = datetime.now(timezone.utc)

    # Close order
    order: Order | None = db.get(Order, bill.order_id)
    if order:
        order.status = OrderStatus.COMPLETED

        # Return table to EMPTY
        if order.table_id:
            table: Table | None = db.get(Table, order.table_id)
            if table:
                table.status = TableStatus.EMPTY

    db.commit()

    return CheckoutResponse(
        bill_id=bill.id,
        status=BillStatus.PAID,
        payment_method=payload.payment_method,
        paid_amount=float(paid_amount),
        change_amount=float(change),
        message="Payment recorded. Table is now available.",
    )
