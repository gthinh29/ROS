

from __future__ import annotations



import uuid

from datetime import datetime, timezone, timedelta



from fastapi import HTTPException, status

from sqlalchemy.orm import Session



from core.enums import OrderType, ReservationStatus, TableStatus

from modules.reservations.models import Reservation

from modules.reservations.schemas import CheckinResponse, ReservationCreate, ReservationRead

from modules.tables.models import Table









def _get_reservation_or_404(db: Session, reservation_id: uuid.UUID) -> Reservation:

    res = db.get(Reservation, reservation_id)

    if not res:

        raise HTTPException(status_code=404, detail="Reservation not found")

    return res









async def create_reservation(db: Session, payload: ReservationCreate) -> Reservation:

    



    if payload.table_id:

        table = db.get(Table, payload.table_id)

        if not table:

            raise HTTPException(status_code=404, detail="Table not found")

        

        

        start_dt = payload.reserved_at - timedelta(hours=2)

        end_dt = payload.reserved_at + timedelta(hours=2)

        

        overlapping_res = db.query(Reservation).filter(

            Reservation.table_id == payload.table_id,

            Reservation.status.in_([ReservationStatus.PENDING, ReservationStatus.CONFIRMED, ReservationStatus.CHECKED_IN]),

            Reservation.reserved_at > start_dt,

            Reservation.reserved_at < end_dt

        ).first()

        

        if overlapping_res:

            raise HTTPException(

                status_code=status.HTTP_409_CONFLICT,

                detail="Bàn này đã được đặt trong khoảng thời gian bạn chọn.",

            )



        

        now_vn = datetime.now() + timedelta(hours=7)

        

        res_at_naive = payload.reserved_at.replace(tzinfo=None)

        if res_at_naive < now_vn + timedelta(hours=2):

            if table.status not in (TableStatus.EMPTY,):

                raise HTTPException(

                    status_code=status.HTTP_409_CONFLICT,

                    detail=f"Bàn này hiện tại đang có khách (Trạng thái: {table.status.value}) và không thể nhận khách mới trong 2 tiếng tới.",

                )



    import random

    import string

    import logging

    import asyncio

    from utils.email_sender import send_otp_email



    

    otp_code = "".join(random.choices(string.digits, k=6))

    otp_expires_at = datetime.now(timezone.utc) + timedelta(minutes=5)



    

    logging.info(f"Gửi OTP {otp_code} tới email {payload.email} cho đặt bàn {payload.customer_name}.")

    

    

    asyncio.create_task(

        asyncio.to_thread(send_otp_email, payload.email, otp_code, payload.customer_name)

    )



    

    reservation = Reservation(

        table_id=payload.table_id,

        customer_name=payload.customer_name,

        phone=payload.phone,

        email=payload.email,

        reserved_at=payload.reserved_at,

        party_size=payload.party_size,

        note=payload.note,

        status=ReservationStatus.PENDING,

        otp_code=otp_code,

        otp_expires_at=otp_expires_at,

    )

    db.add(reservation)

    db.flush()  



    

    



    db.commit()

    db.refresh(reservation)

    return reservation





async def checkin(db: Session, reservation_id: uuid.UUID) -> CheckinResponse:

    



    reservation = _get_reservation_or_404(db, reservation_id)



    if reservation.status == ReservationStatus.CHECKED_IN:

        raise HTTPException(status_code=400, detail="Reservation is already checked in")

    if reservation.status == ReservationStatus.CANCELLED:

        raise HTTPException(status_code=400, detail="Reservation has been cancelled")



    

    reservation.status = ReservationStatus.CHECKED_IN



    

    table: Table | None = None

    if reservation.table_id:

        table = db.get(Table, reservation.table_id)

        if table:

            table.status = TableStatus.OCCUPIED



    db.flush()



    db.commit()



    return CheckinResponse(

        reservation_id=reservation.id,  # type: ignore

        table_id=reservation.table_id,  # type: ignore

        customer_name=reservation.customer_name,  # type: ignore

        message="Check-in thành công."

    )





async def list_reservations(

    db: Session,

    phone: str | None = None,

    status_filter: ReservationStatus | None = None,

) -> list[Reservation]:

    

    query = db.query(Reservation)

    if phone:

        query = query.filter(Reservation.phone == phone)

    if status_filter:

        query = query.filter(Reservation.status == status_filter)

    return query.order_by(Reservation.reserved_at).all()





async def cancel_reservation(db: Session, reservation_id: uuid.UUID) -> Reservation:

    

    reservation = _get_reservation_or_404(db, reservation_id)



    if reservation.status in (ReservationStatus.CHECKED_IN,):

        raise HTTPException(

            status_code=400,

            detail="Cannot cancel a reservation that has already been checked in",

        )

    if reservation.status == ReservationStatus.CANCELLED:

        raise HTTPException(status_code=400, detail="Reservation is already cancelled")



    reservation.status = ReservationStatus.CANCELLED



    

    if reservation.table_id:

        table = db.get(Table, reservation.table_id)

        if table and table.status == TableStatus.RESERVED:

            table.status = TableStatus.EMPTY  # type: ignore



    db.commit()

    db.refresh(reservation)

    return reservation



async def verify_otp(db: Session, reservation_id: uuid.UUID, otp_code: str) -> Reservation:

    

    reservation = _get_reservation_or_404(db, reservation_id)



    if reservation.status != ReservationStatus.PENDING:

        raise HTTPException(

            status_code=400,

            detail="Reservation is not pending confirmation",

        )



    if not reservation.otp_code or reservation.otp_code != otp_code:

        raise HTTPException(status_code=400, detail="Mã OTP không hợp lệ")



    if reservation.otp_expires_at and datetime.now(timezone.utc) > reservation.otp_expires_at: # pyright: ignore[reportOperatorIssue]

        raise HTTPException(status_code=400, detail="Mã OTP đã hết hạn")



    reservation.status = ReservationStatus.CONFIRMED  # type: ignore

    db.commit()

    db.refresh(reservation)

    return reservation

