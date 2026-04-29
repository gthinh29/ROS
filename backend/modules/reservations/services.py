"""Business logic for the Reservations module.

Key flows:
- create_reservation: Lưu đặt bàn + pre-order items, bàn → RESERVED.
- checkin: Kích hoạt reservation, tạo Order từ pre-order items, bắn KDS.
- list_reservations: Tìm kiếm theo phone cho nhân viên.
- cancel_reservation: Hủy đặt bàn PENDING.
"""
from __future__ import annotations

import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from core.enums import OrderType, ReservationStatus, TableStatus
from modules.reservations.models import Reservation, ReservationItem
from modules.reservations.schemas import CheckinResponse, ReservationCreate, ReservationRead
from modules.tables.models import Table


# ── Helpers ───────────────────────────────────────────────────────────────────

def _get_reservation_or_404(db: Session, reservation_id: uuid.UUID) -> Reservation:
    res = db.get(Reservation, reservation_id)
    if not res:
        raise HTTPException(status_code=404, detail="Reservation not found")
    return res


# ── Services ──────────────────────────────────────────────────────────────────

async def create_reservation(db: Session, payload: ReservationCreate) -> Reservation:
    """Tạo đặt bàn mới. Nếu chọn bàn, chuyển trạng thái bàn → RESERVED."""

    # Validate table nếu có
    table: Table | None = None
    if payload.table_id:
        table = db.get(Table, payload.table_id)
        if not table:
            raise HTTPException(status_code=404, detail="Table not found")
        if table.status not in (TableStatus.EMPTY,):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Table is currently '{table.status.value}' and cannot be reserved",
            )

    # Tạo Reservation
    reservation = Reservation(
        table_id=payload.table_id,
        customer_name=payload.customer_name,
        phone=payload.phone,
        reserved_at=payload.reserved_at,
        party_size=payload.party_size,
        note=payload.note,
        status=ReservationStatus.PENDING,
    )
    db.add(reservation)
    db.flush()  # get reservation.id

    # Lưu pre-order items
    for item_req in payload.pre_order_items:
        modifier_str = ",".join(str(mid) for mid in item_req.modifier_ids) if item_req.modifier_ids else None
        db.add(ReservationItem(
            reservation_id=reservation.id,
            menu_item_id=item_req.menu_item_id,
            variant_id=item_req.variant_id,
            modifier_ids=modifier_str,
            qty=item_req.qty,
            note=item_req.note,
        ))

    # Đánh dấu bàn là RESERVED
    if table:
        table.status = TableStatus.RESERVED

    db.commit()
    db.refresh(reservation)
    return reservation


async def checkin(db: Session, reservation_id: uuid.UUID) -> CheckinResponse:
    """Check-in khách: Reservation → CHECKED_IN, tạo Order từ pre-order items, bắn KDS."""

    reservation = _get_reservation_or_404(db, reservation_id)

    if reservation.status == ReservationStatus.CHECKED_IN:
        raise HTTPException(status_code=400, detail="Reservation is already checked in")
    if reservation.status == ReservationStatus.CANCELLED:
        raise HTTPException(status_code=400, detail="Reservation has been cancelled")

    # ── Cập nhật trạng thái ───────────────────────────────────────────────────
    reservation.status = ReservationStatus.CHECKED_IN

    # Bàn → OCCUPIED
    table: Table | None = None
    if reservation.table_id:
        table = db.get(Table, reservation.table_id)
        if table:
            table.status = TableStatus.OCCUPIED

    db.flush()

    # ── Tạo Order từ pre-order items (nếu có) ─────────────────────────────────
    order_id: uuid.UUID | None = None

    if reservation.items:
        from modules.orders.schemas import OrderCreate, OrderItemCreate
        from modules.orders.services import create_order

        order_items = []
        for ri in reservation.items:
            modifier_ids: list[uuid.UUID] = []
            if ri.modifier_ids:
                modifier_ids = [uuid.UUID(mid) for mid in ri.modifier_ids.split(",") if mid]

            order_items.append(OrderItemCreate(
                menu_item_id=ri.menu_item_id,
                variant_id=ri.variant_id,
                modifier_ids=modifier_ids,
                qty=ri.qty,
                note=ri.note,
            ))

        order_payload = OrderCreate(
            table_id=reservation.table_id,
            reservation_id=reservation.id,
            customer_name=reservation.customer_name,
            phone=reservation.phone,
            type=OrderType.PRE_ORDER,
            items=order_items,
        )

        # create_order xử lý ACID lock + WS broadcast → dùng lại hoàn toàn
        # Phải commit trạng thái hiện tại trước vì create_order tự commit
        db.commit()
        order = await create_order(db, order_payload)
        order_id = order.id
    else:
        db.commit()

    return CheckinResponse(
        reservation_id=reservation.id,
        order_id=order_id,
        table_id=reservation.table_id,
        customer_name=reservation.customer_name,
        message=(
            "Check-in thành công. Đơn hàng đã được gửi xuống bếp."
            if order_id
            else "Check-in thành công. Không có pre-order."
        ),
    )


async def list_reservations(
    db: Session,
    phone: str | None = None,
    status_filter: ReservationStatus | None = None,
) -> list[Reservation]:
    """Lấy danh sách đặt bàn — có thể lọc theo SĐT và trạng thái."""
    query = db.query(Reservation)
    if phone:
        query = query.filter(Reservation.phone == phone)
    if status_filter:
        query = query.filter(Reservation.status == status_filter)
    return query.order_by(Reservation.reserved_at).all()


async def cancel_reservation(db: Session, reservation_id: uuid.UUID) -> Reservation:
    """Hủy đặt bàn. Chỉ cho phép khi còn PENDING hoặc CONFIRMED."""
    reservation = _get_reservation_or_404(db, reservation_id)

    if reservation.status in (ReservationStatus.CHECKED_IN,):
        raise HTTPException(
            status_code=400,
            detail="Cannot cancel a reservation that has already been checked in",
        )
    if reservation.status == ReservationStatus.CANCELLED:
        raise HTTPException(status_code=400, detail="Reservation is already cancelled")

    reservation.status = ReservationStatus.CANCELLED

    # Trả bàn về EMPTY nếu đang là RESERVED
    if reservation.table_id:
        table = db.get(Table, reservation.table_id)
        if table and table.status == TableStatus.RESERVED:
            table.status = TableStatus.EMPTY

    db.commit()
    db.refresh(reservation)
    return reservation
