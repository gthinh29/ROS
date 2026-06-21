"""Pydantic schemas for the Reservations module."""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field

from core.enums import ReservationStatus




class ReservationCreate(BaseModel):
    """Tạo đặt bàn mới."""
    table_id: Optional[uuid.UUID] = None
    customer_name: str = Field(..., max_length=100)
    phone: str = Field(..., max_length=20)
    email: str = Field(..., max_length=255)
    reserved_at: datetime = Field(..., description="Thời điểm dự kiến đến (ISO 8601)")
    party_size: int = Field(default=1, ge=1, le=50)
    note: Optional[str] = None




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

    model_config = {"from_attributes": True}


class CheckinResponse(BaseModel):
    """Kết quả trả về sau khi check-in thành công."""
    reservation_id: uuid.UUID
    table_id: Optional[uuid.UUID]
    customer_name: str
    message: str


class VerifyOTPRequest(BaseModel):
    otp_code: str = Field(..., description="6 digit OTP code")
