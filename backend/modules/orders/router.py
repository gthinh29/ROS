"""Order CRUD endpoints."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from core.database import get_db
from core.denpendencies.role_access import require_role
from core.enums import UserRole
from modules.orders import services
from modules.orders.schemas import OrderCreate, OrderItemStatusUpdate, OrderRead
from utils.response_wrapper import ResponseWrapper

router = APIRouter(prefix="/orders", tags=["Orders"])

IS_STAFF = [UserRole.ADMIN.value, UserRole.CASHIER.value, UserRole.WAITER.value, UserRole.KITCHEN.value]
IS_KITCHEN_OR_WAITER = [UserRole.KITCHEN.value, UserRole.WAITER.value, UserRole.ADMIN.value]


@router.post("", status_code=201, response_model=ResponseWrapper[OrderRead], response_model_exclude_none=True)
async def create_order(
    request: OrderCreate,
    db: Session = Depends(get_db),
):
    """
    Create a new order. Public endpoint (customer via QR) or Staff.
    Performs ACID inventory check with SELECT FOR UPDATE.
    """
    result = await services.create_order(db, request)
    return ResponseWrapper.success_response(result)


@router.get("/{order_id}", response_model=ResponseWrapper[OrderRead], response_model_exclude_none=True)
async def get_order(
    order_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_STAFF),
):
    """Get a single order by ID."""
    result = await services.get_order(db, order_id)
    return ResponseWrapper.success_response(result)


@router.get("", response_model=ResponseWrapper[list[OrderRead]], response_model_exclude_none=True)
async def list_orders_by_table(
    table_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_STAFF),
):
    """List active orders for a specific table."""
    result = await services.list_orders_by_table(db, table_id)
    return ResponseWrapper.success_response(result)


@router.patch(
    "/{order_id}/items/{item_id}/status",
    response_model=ResponseWrapper[dict],
    response_model_exclude_none=True,
)
async def update_item_status(
    order_id: uuid.UUID,
    item_id: uuid.UUID,
    payload: OrderItemStatusUpdate,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_KITCHEN_OR_WAITER),
):
    """
    Update status of a single order item.
    Allowed transitions: PENDING→PREPARING→READY→SERVED.
    """
    await services.update_item_status(db, order_id, item_id, payload)
    return ResponseWrapper.success_response({"message": "Item status updated"})
