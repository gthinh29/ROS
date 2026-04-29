"""Reservations API endpoints."""
from __future__ import annotations

import uuid
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from core.database import get_db
from core.denpendencies.role_access import require_role
from core.enums import ReservationStatus, UserRole
from modules.reservations import services
from modules.reservations.schemas import (
    CheckinResponse,
    ReservationCreate,
    ReservationRead,
)
from utils.response_wrapper import ResponseWrapper

router = APIRouter(prefix="/reservations", tags=["Reservations"])

IS_STAFF = [UserRole.ADMIN.value, UserRole.CASHIER.value, UserRole.WAITER.value]


@router.post(
    "",
    status_code=201,
    response_model=ResponseWrapper[ReservationRead],
    response_model_exclude_none=True,
)
async def create_reservation(
    payload: ReservationCreate,
    db: Session = Depends(get_db),
):
    """
    Tạo đặt bàn trước (có thể kèm pre-order).

    - **Public endpoint** — khách hàng gọi từ Customer Web.
    - Nếu chỉ định `table_id`, bàn sẽ chuyển sang trạng thái RESERVED.
    - Các món trong `pre_order_items` được lưu lại và kích hoạt khi check-in.
    """
    result = await services.create_reservation(db, payload)
    return ResponseWrapper.success_response(result)


@router.get(
    "",
    response_model=ResponseWrapper[list[ReservationRead]],
    response_model_exclude_none=True,
)
async def list_reservations(
    phone: Optional[str] = Query(None, description="Lọc theo số điện thoại"),
    status: Optional[ReservationStatus] = Query(None, description="Lọc theo trạng thái"),
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_STAFF),
):
    """
    Lấy danh sách đặt bàn — Nhân viên tìm kiếm theo SĐT khách.
    """
    result = await services.list_reservations(db, phone=phone, status_filter=status)
    return ResponseWrapper.success_response(result)


@router.get(
    "/{reservation_id}",
    response_model=ResponseWrapper[ReservationRead],
    response_model_exclude_none=True,
)
async def get_reservation(
    reservation_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_STAFF),
):
    """Lấy chi tiết một đặt bàn."""
    from modules.reservations.services import _get_reservation_or_404
    result = _get_reservation_or_404(db, reservation_id)
    return ResponseWrapper.success_response(result)


@router.post(
    "/{reservation_id}/checkin",
    response_model=ResponseWrapper[CheckinResponse],
    response_model_exclude_none=True,
)
async def checkin_reservation(
    reservation_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_STAFF),
):
    """
    Check-in khách đến nhà hàng.

    Tại thời điểm check-in, hệ thống tự động:
    1. Chuyển Reservation → **CHECKED_IN**
    2. Chuyển bàn → **OCCUPIED**
    3. Tạo **Order** từ danh sách pre-order items (nếu có)
    4. Bắn thẻ món xuống **KDS** qua WebSocket ngay lập tức

    Trả về `order_id` của đơn hàng vừa tạo (hoặc `null` nếu không có pre-order).
    """
    result = await services.checkin(db, reservation_id)
    return ResponseWrapper.success_response(result)


@router.patch(
    "/{reservation_id}/cancel",
    response_model=ResponseWrapper[ReservationRead],
    response_model_exclude_none=True,
)
async def cancel_reservation(
    reservation_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_STAFF),
):
    """
    Hủy đặt bàn (chỉ áp dụng khi trạng thái là PENDING hoặc CONFIRMED).
    Bàn đã RESERVED sẽ được trả về EMPTY.
    """
    result = await services.cancel_reservation(db, reservation_id)
    return ResponseWrapper.success_response(result)
