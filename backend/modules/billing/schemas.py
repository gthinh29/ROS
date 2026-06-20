"""Pydantic schemas for the Billing module."""
from __future__ import annotations

import uuid
from typing import Optional

from pydantic import BaseModel, Field

from core.enums import BillStatus, PaymentMethod


# ── Request schemas ────────────────────────────────────────────────────────────

class BillCreate(BaseModel):
    order_id: uuid.UUID


class SplitBillRequest(BaseModel):
    bill_id: uuid.UUID
    split_count: int = Field(..., ge=2, description="Number of people to split the bill among")


class CheckoutRequest(BaseModel):
    bill_id: uuid.UUID
    payment_method: PaymentMethod
    paid_amount: Optional[float] = Field(
        None, description="Amount paid by customer (required for CASH)"
    )


# ── Response schemas ───────────────────────────────────────────────────────────

class BillRead(BaseModel):
    id: uuid.UUID
    order_id: uuid.UUID
    subtotal: float
    tax: float
    service_fee: float
    discount: float
    total: float
    payment_method: Optional[PaymentMethod]
    paid_amount: Optional[float]
    change_amount: Optional[float]
    status: BillStatus
    # Thông tin khách hàng + bàn (dung để hiển thị phíeu)
    customer_name: Optional[str] = None
    phone: Optional[str] = None
    table_number: Optional[str] = None

    model_config = {"from_attributes": True}


class SplitBillPart(BaseModel):
    """Represents one person's portion of a split bill."""
    part_index: int
    amount: float


class SplitBillResponse(BaseModel):
    bill_id: uuid.UUID
    split_count: int
    total: float
    parts: list[SplitBillPart]


class CheckoutResponse(BaseModel):
    bill_id: uuid.UUID
    order_id: uuid.UUID
    status: BillStatus
    payment_method: PaymentMethod
    paid_amount: float
    change_amount: float
    message: str
    # Thông tin hiển thị phíeu
    customer_name: Optional[str] = None
    phone: Optional[str] = None
    table_number: Optional[str] = None
