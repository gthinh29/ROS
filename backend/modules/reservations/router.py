

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

    VerifyOTPRequest,

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

    

    result = await services.cancel_reservation(db, reservation_id)

    return ResponseWrapper.success_response(result)



@router.post(

    "/{reservation_id}/verify-otp",

    response_model=ResponseWrapper[ReservationRead],

    response_model_exclude_none=True,

)

async def verify_otp(

    reservation_id: uuid.UUID,

    payload: VerifyOTPRequest,

    db: Session = Depends(get_db),

):

    

    result = await services.verify_otp(db, reservation_id, payload.otp_code)

    return ResponseWrapper.success_response(result)

