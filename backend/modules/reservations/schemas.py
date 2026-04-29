"""Pydantic schemas for the Reservations module."""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field

from core.enums import ReservationStatus


# ── Sub-schemas ────────────────────────────────────────────────────────────────

class ReservationItemCreate(BaseModel):
    """Một món trong danh sách pre-order khi đặt bàn."""
    menu_item_id: uuid.UUID
    variant_id: Optional[uuid.UUID] = None
    modifier_ids: List[uuid.UUID] = Field(default_factory=list)
    qty: int = Field(default=1, ge=1)
    note: Optional[str] = None


# ── Request schemas ────────────────────────────────────────────────────────────

class ReservationCreate(BaseModel):
    """Tạo đặt bàn mới (có thể kèm pre-order)."""
    table_id: Optional[uuid.UUID] = None
    customer_name: str = Field(..., max_length=100)
    phone: str = Field(..., max_length=20)
    reserved_at: datetime = Field(..., description="Thời điểm dự kiến đến (ISO 8601)")
    party_size: int = Field(default=1, ge=1, le=50)
    note: Optional[str] = None
    pre_order_items: List[ReservationItemCreate] = Field(
        default_factory=list,
        description="Danh sách món muốn đặt trước (tuỳ chọn)",
    )


# ── Response schemas ───────────────────────────────────────────────────────────

class ReservationItemRead(BaseModel):
    id: uuid.UUID
    menu_item_id: uuid.UUID
    variant_id: Optional[uuid.UUID]
    modifier_ids: Optional[str]   # stored as comma-separated string
    qty: int
    note: Optional[str]

    model_config = {"from_attributes": True}


class ReservationRead(BaseModel):
    id: uuid.UUID
    table_id: Optional[uuid.UUID]
    customer_name: str
    phone: str
    reserved_at: datetime
    party_size: int
    status: ReservationStatus
    note: Optional[str]
    created_at: datetime
    items: List[ReservationItemRead] = []

    model_config = {"from_attributes": True}


class CheckinResponse(BaseModel):
    """Kết quả trả về sau khi check-in thành công."""
    reservation_id: uuid.UUID
    order_id: Optional[uuid.UUID]          # None nếu không có pre-order items
    table_id: Optional[uuid.UUID]
    customer_name: str
    message: str
