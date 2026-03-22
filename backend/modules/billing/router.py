"""Billing endpoints — Cashier only."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from core.database import get_db
from core.denpendencies.role_access import require_role
from core.enums import UserRole
from modules.billing import services
from modules.billing.schemas import (
    BillCreate,
    BillRead,
    CheckoutRequest,
    CheckoutResponse,
    SplitBillRequest,
    SplitBillResponse,
)
from utils.response_wrapper import ResponseWrapper

router = APIRouter(prefix="/billing", tags=["Billing"])

IS_CASHIER = [UserRole.CASHIER.value, UserRole.ADMIN.value]


@router.post(
    "/create",
    status_code=201,
    response_model=ResponseWrapper[BillRead],
    response_model_exclude_none=True,
)
async def create_bill(
    payload: BillCreate,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_CASHIER),
):
    """Create a bill for an order. Calculates subtotal, VAT and service fee automatically."""
    result = await services.create_bill(db, payload)
    return ResponseWrapper.success_response(result)


@router.post(
    "/split",
    response_model=ResponseWrapper[SplitBillResponse],
    response_model_exclude_none=True,
)
async def split_bill(
    payload: SplitBillRequest,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_CASHIER),
):
    """Preview how a bill would be split evenly among N people."""
    result = await services.split_bill_evenly(db, payload.bill_id, payload.split_count)
    return ResponseWrapper.success_response(result)


@router.post(
    "/checkout",
    response_model=ResponseWrapper[CheckoutResponse],
    response_model_exclude_none=True,
)
async def checkout(
    payload: CheckoutRequest,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_CASHIER),
):
    """Record payment, mark bill as PAID, close order and return table to EMPTY."""
    result = await services.checkout(db, payload)
    return ResponseWrapper.success_response(result)
