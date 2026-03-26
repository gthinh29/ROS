"""Billing endpoints — Cashier only."""
from __future__ import annotations


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


def _enrich_bill_read(bill, db: Session) -> BillRead:
    """Tạo BillRead có thêm thông tin khách hàng và số bàn từ Order/Table."""
    from modules.orders.models import Order
    from modules.tables.models import Table

    bill_data = BillRead.model_validate(bill)
    order = db.get(Order, bill.order_id)
    if order:
        bill_data = bill_data.model_copy(update={
            "customer_name": order.customer_name,
            "phone": order.phone,
        })
        if order.table_id:
            table = db.get(Table, order.table_id)
            if table:
                bill_data = bill_data.model_copy(update={"table_number": str(table.number)})
    return bill_data


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
    """Tạo bill cho order. Chỉ tính các món READY/SERVED. Trả về kèm thông tin khách."""
    result = await services.create_bill(db, payload)
    return ResponseWrapper.success_response(_enrich_bill_read(result, db))


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
    """Xem trước cách chia đều bill cho N người."""
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
    """Ghi nhận thanh toán, mark PAID, hủy món chưa xong, đóng bàn."""
    result = await services.checkout(db, payload)
    return ResponseWrapper.success_response(result)

