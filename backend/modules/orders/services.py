"""Business logic for the Orders module.

Key design:
- SELECT FOR UPDATE on ingredients to avoid overselling (ACID).
- State machine: PENDING → PREPARING → READY → SERVED (per item).
- After order created, push KDS event to the correct zone via ws_manager.
"""
from __future__ import annotations

import uuid
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from core.enums import OrderItemStatus, OrderStatus, TableStatus
from modules.inventory.models import BOMItem, Ingredient, InventoryLog
from modules.menu.models import MenuItem, Modifier, Variant
from modules.orders.models import Order, OrderItem, OrderModifier
from modules.orders.schemas import OrderCreate, OrderItemStatusUpdate
from modules.tables.models import Table

# Valid state transitions for each order-item status
_ALLOWED_TRANSITIONS: dict[OrderItemStatus, list[OrderItemStatus]] = {
    OrderItemStatus.PENDING: [OrderItemStatus.PREPARING, OrderItemStatus.READY, OrderItemStatus.SERVED],
    OrderItemStatus.PREPARING: [OrderItemStatus.READY, OrderItemStatus.SERVED],
    OrderItemStatus.READY: [OrderItemStatus.SERVED],
    OrderItemStatus.SERVED: [],
    OrderItemStatus.CANCELLED: [],  # terminal state
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def _get_menu_item(db: Session, menu_item_id: uuid.UUID) -> MenuItem:
    item = db.get(MenuItem, menu_item_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"MenuItem {menu_item_id} not found",
        )
    if not item.is_available:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"'{item.name}' is currently unavailable",
        )
    return item


def _get_variant(db: Session, variant_id: uuid.UUID, menu_item_id: uuid.UUID) -> Variant:
    variant = db.get(Variant, variant_id)
    if not variant or variant.menu_item_id != menu_item_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Variant {variant_id} not found for this menu item",
        )
    return variant


def _get_modifiers(db: Session, modifier_ids: list[uuid.UUID], menu_item_id: uuid.UUID) -> list[Modifier]:
    if not modifier_ids:
        return []
    modifiers = db.query(Modifier).filter(Modifier.id.in_(modifier_ids)).all()
    found_ids = {m.id for m in modifiers}
    for mid in modifier_ids:
        if mid not in found_ids:
            raise HTTPException(status_code=404, detail=f"Modifier {mid} not found")
        m = next(m for m in modifiers if m.id == mid)
        if m.menu_item_id != menu_item_id:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Modifier {mid} does not belong to this menu item",
            )
    return modifiers


def _check_and_lock_inventory(
    db: Session, menu_item_id: uuid.UUID, variant_id: uuid.UUID | None, qty: int
) -> None:
    """
    Lock ingredient rows with SELECT FOR UPDATE, then verify sufficient stock.
    Raises 422 if any ingredient is insufficient.
    """
    bom_rows = (
        db.query(BOMItem)
        .filter(
            BOMItem.menu_item_id == menu_item_id,
            BOMItem.variant_id == variant_id,
        )
        .all()
    )
    if not bom_rows:
        return  # no BOM defined → skip inventory check

    ingredient_ids = [row.ingredient_id for row in bom_rows]

    # Lock rows — prevents concurrent requests from reading stale stock
    locked_ingredients: list[Ingredient] = (
        db.execute(
            select(Ingredient)
            .where(Ingredient.id.in_(ingredient_ids))
            .with_for_update()
        )
        .scalars()
        .all()
    )
    ing_map = {ing.id: ing for ing in locked_ingredients}

    for bom in bom_rows:
        ing = ing_map.get(bom.ingredient_id)
        if ing is None:
            raise HTTPException(status_code=500, detail="Ingredient not found in inventory")
        required = Decimal(str(bom.qty_required)) * qty
        if Decimal(str(ing.stock_qty)) < required:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Not enough '{ing.name}': need {required}{ing.unit}, have {ing.stock_qty}{ing.unit}",
            )


def _deduct_inventory_for_served_item(db: Session, order: Order, item: OrderItem) -> None:
    """
    Deduct inventory based on BOM when an order-item is marked as SERVED.
    Uses row-level locks to avoid concurrent over-deduction.
    """
    bom_rows = (
        db.query(BOMItem)
        .filter(
            BOMItem.menu_item_id == item.menu_item_id,
            BOMItem.variant_id == item.variant_id,
        )
        .all()
    )
    if not bom_rows:
        return

    ingredient_ids = [row.ingredient_id for row in bom_rows]
    locked_ingredients: list[Ingredient] = (
        db.execute(
            select(Ingredient)
            .where(Ingredient.id.in_(ingredient_ids))
            .with_for_update()
        )
        .scalars()
        .all()
    )
    ingredient_map = {ing.id: ing for ing in locked_ingredients}

    for bom in bom_rows:
        ingredient = ingredient_map.get(bom.ingredient_id)
        if ingredient is None:
            raise HTTPException(status_code=500, detail="Ingredient not found in inventory")

        required = Decimal(str(bom.qty_required)) * Decimal(str(item.qty))
        if Decimal(str(ingredient.stock_qty)) < required:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Not enough '{ingredient.name}' to serve item: need {required}{ingredient.unit}, have {ingredient.stock_qty}{ingredient.unit}",
            )

        ingredient.stock_qty = Decimal(str(ingredient.stock_qty)) - required
        db.add(InventoryLog(
            ingredient_id=ingredient.id,
            delta=-required,
            reason=f"Auto-deducted {required} for order item {item.id}",
            order_id=order.id,
        ))


# ── Services ──────────────────────────────────────────────────────────────────

async def create_order(db: Session, request: OrderCreate) -> Order:
    """Create a new order with ACID inventory check."""

    # Validate table if provided
    table: Table | None = None
    if request.table_id:
        table = db.get(Table, request.table_id)
        if not table:
            raise HTTPException(status_code=404, detail="Table not found")

    order_total = Decimal("0")
    item_payloads: list[dict] = []

    # ── Phase 1: validate all items & compute prices ───────────
    for item_req in request.items:
        menu_item = _get_menu_item(db, item_req.menu_item_id)
        variant = None
        item_price = Decimal(str(menu_item.base_price))

        if item_req.variant_id:
            variant = _get_variant(db, item_req.variant_id, menu_item.id)
            item_price += Decimal(str(variant.extra_price))

        modifiers = _get_modifiers(db, item_req.modifier_ids, menu_item.id)
        modifier_extra = sum(Decimal(str(m.extra_price)) for m in modifiers)
        item_price += modifier_extra

        item_payloads.append({
            "menu_item": menu_item,
            "variant": variant,
            "modifiers": modifiers,
            "unit_price": item_price,
            "qty": item_req.qty,
            "note": item_req.note,
        })
        order_total += item_price * item_req.qty

    # ── Phase 2: ACID inventory lock (SELECT FOR UPDATE) ──────
    for payload in item_payloads:
        _check_and_lock_inventory(
            db,
            payload["menu_item"].id,
            payload["variant"].id if payload["variant"] else None,
            payload["qty"],
        )

    # ── Phase 3: persist Order ─────────────────────────────────
    order = Order(
        table_id=request.table_id,
        reservation_id=request.reservation_id,
        customer_name=request.customer_name,
        phone=request.phone,
        type=request.type,
        status=OrderStatus.PENDING,
        total=float(order_total),
    )
    db.add(order)
    db.flush()  # get order.id without committing

    kds_events: list[dict] = []
    for payload in item_payloads:
        order_item = OrderItem(
            order_id=order.id,
            menu_item_id=payload["menu_item"].id,
            variant_id=payload["variant"].id if payload["variant"] else None,
            qty=payload["qty"],
            price=float(payload["unit_price"]),
            note=payload["note"],
            status=OrderItemStatus.PENDING,
        )
        db.add(order_item)
        db.flush()

        for modifier in payload["modifiers"]:
            db.add(OrderModifier(
                order_item_id=order_item.id,
                modifier_id=modifier.id,
                price=float(modifier.extra_price),
            ))

        kds_events.append({
            "order_item_id": str(order_item.id),
            "order_id": str(order.id),
            "menu_item_name": payload["menu_item"].name,
            "variant_name": payload["variant"].name if payload["variant"] else None,
            "modifier_names": [m.name for m in payload["modifiers"]],
            "qty": payload["qty"],
            "note": payload["note"],
            "table_id": str(request.table_id) if request.table_id else None,
            "table_number": str(table.number) if table else None,
            "zone": payload["menu_item"].kds_zone,
        })

    # ── Phase 4: update table status ──────────────────────────
    if table and table.status == TableStatus.EMPTY:
        table.status = TableStatus.OCCUPIED

    db.commit()
    db.refresh(order)

    # ── Phase 5: broadcast to KDS (fire-and-forget) ────────────
    try:
        from core.ws_manager import kds_manager
        import asyncio
        asyncio.create_task(kds_manager.broadcast_new_order_items(kds_events))
        
        # Broadcast table status to POS
        if table:
            asyncio.create_task(kds_manager.broadcast_pos_event({
                "type": "TABLE_STATUS", 
                "table_id": str(table.id), 
                "status": TableStatus.OCCUPIED.value
            }))
    except Exception:
        pass  # WS broadcast failure must never break the order response

    return order


async def get_order(db: Session, order_id: uuid.UUID) -> Order:
    order = db.get(Order, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order


async def list_orders_by_table(db: Session, table_id: uuid.UUID) -> list[Order]:
    return (
        db.query(Order)
        .filter(Order.table_id == table_id, Order.status != OrderStatus.COMPLETED)
        .all()
    )


async def update_item_status(
    db: Session, order_id: uuid.UUID, item_id: uuid.UUID, payload: OrderItemStatusUpdate
) -> OrderItem:
    order = db.get(Order, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    item = db.get(OrderItem, item_id)
    if not item or item.order_id != order_id:
        raise HTTPException(status_code=404, detail="Order item not found")

    allowed = _ALLOWED_TRANSITIONS.get(item.status, [])
    if payload.status not in allowed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot transition from '{item.status}' to '{payload.status}'",
        )

    if payload.status == OrderItemStatus.SERVED:
        _deduct_inventory_for_served_item(db, order, item)

    item.status = payload.status
    db.commit()
    db.refresh(item)

    try:
        from core.ws_manager import kds_manager
        import asyncio
        menu_item = db.get(MenuItem, item.menu_item_id)

        # ── Broadcast trạng thái mới lên KDS realtime ────────────
        asyncio.create_task(kds_manager.broadcast_to_zone(
            menu_item.kds_zone if menu_item else "kitchen",
            {
                "event": "item_status_updated",
                "item_id": str(item.id),
                "status": payload.status.value,
            }
        ))

        # ── Thông báo cho Waiter khi món READY ────────────────────
        if payload.status == OrderItemStatus.READY:
            from modules.tables.models import Table
            table = db.get(Table, order.table_id) if order.table_id else None
            asyncio.create_task(kds_manager.broadcast_staff_event({
                "event": "ITEM_READY",
                "table_id": str(order.table_id) if order.table_id else None,
                "table_number": str(table.number) if table else None,
                "menu_item_name": menu_item.name if menu_item else "Unknown",
                "item_id": str(item.id),
                "order_id": str(order.id),
            }))
    except Exception as e:
        import traceback
        print("ERROR IN WS BROADCAST:", traceback.format_exc())

    return item


async def cancel_pending_items_for_order(db: Session, order: Order) -> None:
    """Hủy tất cả món chưa xong khi checkout. Broadcast KDS để bếp tự dọn."""
    import asyncio
    try:
        from core.ws_manager import kds_manager
    except Exception:
        kds_manager = None

    pending_statuses = {
        OrderItemStatus.PENDING,
        OrderItemStatus.PREPARING,
        OrderItemStatus.READY,
    }

    for item in order.items:
        if item.status in pending_statuses:
            item.status = OrderItemStatus.CANCELLED
            if kds_manager:
                menu_item = db.get(MenuItem, item.menu_item_id)
                zone = menu_item.kds_zone if menu_item else "kitchen"
                asyncio.create_task(kds_manager.broadcast_to_zone(
                    zone,
                    {
                        "event": "item_status_updated",
                        "item_id": str(item.id),
                        "status": OrderItemStatus.CANCELLED.value,
                    }
                ))


async def get_active_kds_items(db: Session, zone: str) -> list[dict]:
    from modules.tables.models import Table
    items = (
        db.query(OrderItem, Order, MenuItem, Variant, Table)
        .join(Order, Order.id == OrderItem.order_id)
        .join(MenuItem, MenuItem.id == OrderItem.menu_item_id)
        .outerjoin(Variant, Variant.id == OrderItem.variant_id)
        .outerjoin(Table, Table.id == Order.table_id)
        .filter(
            OrderItem.status.in_([OrderItemStatus.PENDING, OrderItemStatus.PREPARING, OrderItemStatus.READY]),
            MenuItem.kds_zone == zone
        )
        .all()
    )
    
    result = []
    for order_item, order, menu_item, variant, table in items:
        from modules.menu.models import Modifier
        from modules.orders.models import OrderModifier
        modifiers = (
            db.query(Modifier)
            .join(OrderModifier, OrderModifier.modifier_id == Modifier.id)
            .filter(OrderModifier.order_item_id == order_item.id)
            .all()
        )
        result.append({
            "id": str(order_item.id),
            "order_item_id": str(order_item.id),
            "order_id": str(order.id),
            "menu_item_name": menu_item.name,
            "variant_name": variant.name if variant else None,
            "modifier_names": [m.name for m in modifiers],
            "qty": order_item.qty,
            "note": order_item.note,
            "table_id": str(order.table_id) if order.table_id else None,
            "table_number": str(table.number) if table else None,
            "zone": menu_item.kds_zone,
            "status": order_item.status.value,
        })
    return result
