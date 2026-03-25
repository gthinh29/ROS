"""Tables module — Restaurant and Table models."""

import uuid

from sqlalchemy import (
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.database import Base
from core.enums import TableStatus


class Restaurant(Base):
    __tablename__ = "restaurants"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    settings: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    created_at: Mapped[str] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Relationships
    tables = relationship("Table", back_populates="restaurant", lazy="selectin")


class Table(Base):
    __tablename__ = "tables"
    __table_args__ = (
        UniqueConstraint("restaurant_id", "zone", "number", name="uq_table_zone_number"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    restaurant_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("restaurants.id"), nullable=False
    )
    zone: Mapped[str] = mapped_column(String(50), nullable=False)
    number: Mapped[int] = mapped_column(Integer, nullable=False)
    qr_code: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[TableStatus] = mapped_column(
        Enum(TableStatus, name="tablestatus", create_constraint=True),
        default=TableStatus.EMPTY,
    )
    created_at: Mapped[str] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Relationships
    restaurant = relationship("Restaurant", back_populates="tables")
