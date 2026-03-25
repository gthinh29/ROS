"""Billing module — Bill model."""

import uuid

from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from core.database import Base
from core.enums import BillStatus, PaymentMethod


class Bill(Base):
    __tablename__ = "bills"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    order_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id"), nullable=False
    )
    subtotal: Mapped[float] = mapped_column(Numeric(14, 2), nullable=False)
    tax: Mapped[float] = mapped_column(Numeric(14, 2), default=0)
    service_fee: Mapped[float] = mapped_column(Numeric(14, 2), default=0)
    discount: Mapped[float] = mapped_column(Numeric(14, 2), default=0)
    total: Mapped[float] = mapped_column(Numeric(14, 2), nullable=False)
    payment_method: Mapped[PaymentMethod | None] = mapped_column(
        Enum(PaymentMethod, name="paymentmethod", create_constraint=True),
        nullable=True,
    )
    status: Mapped[BillStatus] = mapped_column(
        Enum(BillStatus, name="billstatus", create_constraint=True),
        default=BillStatus.PENDING,
    )
    voucher_code: Mapped[str | None] = mapped_column(String(50), nullable=True)
    created_at: Mapped[str] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    paid_at: Mapped[str | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
