"""initial_schema

Revision ID: 0001_initial_schema
Revises:
Create Date: 2026-03-21
"""
from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

# revision identifiers, used by Alembic
revision: str = "0001_initial_schema"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── 1. users ─────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("email", sa.String(255), unique=True, nullable=True),
        sa.Column("phone", sa.String(20), unique=True, nullable=True),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("role", sa.Enum("ADMIN", "CASHIER", "KITCHEN", "WAITER", name="userrole"), nullable=False),
        sa.Column("is_active", sa.Boolean(), default=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
    )

    # ── 2. refresh_tokens ────────────────────────────────────────────────
    op.create_table(
        "refresh_tokens",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("token", sa.Text(), nullable=False, unique=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("is_revoked", sa.Boolean(), default=False, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_refresh_tokens_user_id", "refresh_tokens", ["user_id"])

    # ── 3. restaurants ───────────────────────────────────────────────────
    op.create_table(
        "restaurants",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("settings", postgresql.JSONB(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # ── 4. tables ────────────────────────────────────────────────────────
    op.create_table(
        "tables",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("restaurant_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("restaurants.id"), nullable=False),
        sa.Column("zone", sa.String(50), nullable=False),
        sa.Column("number", sa.Integer(), nullable=False),
        sa.Column("qr_token", sa.Text(), nullable=True, unique=True),
        sa.Column("status", sa.Enum("EMPTY", "OCCUPIED", "RESERVED", "CLEANING", name="tablestatus"), default="EMPTY"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint("restaurant_id", "zone", "number", name="uq_table_zone_number"),
    )

    # ── 5. categories ────────────────────────────────────────────────────
    op.create_table(
        "categories",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("restaurant_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("restaurants.id"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("sort_order", sa.Integer(), default=0),
    )

    # ── 6. menu_items ────────────────────────────────────────────────────
    op.create_table(
        "menu_items",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("category_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("categories.id"), nullable=False),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("base_price", sa.Numeric(12, 2), nullable=False),
        sa.Column("image_url", sa.Text(), nullable=True),
        sa.Column("is_available", sa.Boolean(), default=True),
        sa.Column("kds_zone", sa.String(20), default="kitchen", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # ── 7. variants ──────────────────────────────────────────────────────
    op.create_table(
        "variants",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("menu_item_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("menu_items.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("extra_price", sa.Numeric(12, 2), default=0),
    )

    # ── 8. modifiers ─────────────────────────────────────────────────────
    op.create_table(
        "modifiers",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("menu_item_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("menu_items.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("extra_price", sa.Numeric(12, 2), default=0),
        sa.Column("is_required", sa.Boolean(), default=False),
    )

    # ── 9. ingredients ───────────────────────────────────────────────────
    op.create_table(
        "ingredients",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("unit", sa.String(20), nullable=False),
        sa.Column("stock_qty", sa.Numeric(12, 2), default=0),
        sa.Column("alert_threshold", sa.Numeric(12, 2), default=0),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # ── 10. bom_items ────────────────────────────────────────────────────
    op.create_table(
        "bom_items",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("menu_item_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("menu_items.id"), nullable=False),
        sa.Column("variant_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("variants.id"), nullable=True),
        sa.Column("ingredient_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("ingredients.id"), nullable=False),
        sa.Column("qty_required", sa.Numeric(12, 4), nullable=False),
        sa.UniqueConstraint("menu_item_id", "variant_id", "ingredient_id", name="uq_bom_item_variant_ingredient"),
    )

    # ── 11. reservations ─────────────────────────────────────────────────
    op.create_table(
        "reservations",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("table_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("tables.id"), nullable=True),
        sa.Column("customer_name", sa.String(100), nullable=False),
        sa.Column("phone", sa.String(20), nullable=False),
        sa.Column("reserved_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("party_size", sa.Integer(), nullable=False, default=1),
        sa.Column("status", sa.Enum("PENDING", "CONFIRMED", "CHECKED_IN", "CANCELLED", name="reservationstatus"), default="PENDING"),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # ── 12. orders ───────────────────────────────────────────────────────
    op.create_table(
        "orders",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("table_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("tables.id"), nullable=True),
        sa.Column("reservation_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("reservations.id"), nullable=True),
        sa.Column("customer_name", sa.String(100), nullable=True),
        sa.Column("phone", sa.String(20), nullable=True),
        sa.Column("type", sa.Enum("DINE_IN", "PRE_ORDER", name="ordertype"), nullable=False),
        sa.Column("status", sa.Enum("PENDING", "PREPARING", "READY", "COMPLETED", "CANCELLED", name="orderstatus"), default="PENDING"),
        sa.Column("total", sa.Numeric(14, 2), default=0),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
    )

    # ── 13. order_items ──────────────────────────────────────────────────
    op.create_table(
        "order_items",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("order_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("orders.id", ondelete="CASCADE"), nullable=False),
        sa.Column("menu_item_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("menu_items.id"), nullable=False),
        sa.Column("variant_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("variants.id"), nullable=True),
        sa.Column("qty", sa.Integer(), nullable=False, default=1),
        sa.Column("price", sa.Numeric(12, 2), nullable=False),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("status", sa.Enum("PENDING", "PREPARING", "READY", "SERVED", name="orderitemstatus"), default="PENDING"),
    )

    # ── 14. order_modifiers ──────────────────────────────────────────────
    op.create_table(
        "order_modifiers",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("order_item_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("order_items.id", ondelete="CASCADE"), nullable=False),
        sa.Column("modifier_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("modifiers.id"), nullable=False),
        sa.Column("price", sa.Numeric(12, 2), nullable=False),
    )

    # ── 15. bills ────────────────────────────────────────────────────────
    op.create_table(
        "bills",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("order_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("orders.id"), nullable=False),
        sa.Column("subtotal", sa.Numeric(14, 2), nullable=False),
        sa.Column("tax", sa.Numeric(14, 2), default=0),
        sa.Column("service_fee", sa.Numeric(14, 2), default=0),
        sa.Column("discount", sa.Numeric(14, 2), default=0),
        sa.Column("total", sa.Numeric(14, 2), nullable=False),
        sa.Column("payment_method", sa.Enum("CASH", "VIETQR", "CARD", name="paymentmethod"), nullable=True),
        sa.Column("paid_amount", sa.Numeric(14, 2), nullable=True),
        sa.Column("change_amount", sa.Numeric(14, 2), nullable=True),
        sa.Column("status", sa.Enum("PENDING", "PAID", name="billstatus"), default="PENDING"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("paid_at", sa.DateTime(timezone=True), nullable=True),
    )

    # ── 16. inventory_logs ───────────────────────────────────────────────
    op.create_table(
        "inventory_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("ingredient_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("ingredients.id"), nullable=False),
        sa.Column("delta", sa.Numeric(12, 4), nullable=False),
        sa.Column("reason", sa.String(200), nullable=False),
        sa.Column("order_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("orders.id"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )


def downgrade() -> None:
    op.drop_table("inventory_logs")
    op.drop_table("bills")
    op.drop_table("order_modifiers")
    op.drop_table("order_items")
    op.drop_table("orders")
    op.drop_table("reservations")
    op.drop_table("bom_items")
    op.drop_table("ingredients")
    op.drop_table("modifiers")
    op.drop_table("variants")
    op.drop_table("menu_items")
    op.drop_table("categories")
    op.drop_table("tables")
    op.drop_table("restaurants")
    op.drop_table("refresh_tokens")
    op.drop_table("users")

    bind = op.get_bind()
    for enum_name in [
        "billstatus", "paymentmethod", "orderitemstatus",
        "orderstatus", "ordertype", "reservationstatus",
        "tablestatus", "userrole",
    ]:
        sa.Enum(name=enum_name).drop(bind, checkfirst=True)
