"""User module — User model."""

import uuid

from sqlalchemy import Boolean, DateTime, String, Enum, func, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.database import Base
from core.enums import UserRole


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str | None] = mapped_column(
        String(255), unique=True, nullable=True
    )
    phone: Mapped[str | None] = mapped_column(
        String(20), unique=True, nullable=True
    )
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="userrole", create_constraint=True),
        nullable=False,
        default=UserRole.WAITER,
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[str] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[str | None] = mapped_column(
        DateTime(timezone=True), onupdate=func.now(), nullable=True
    )

    refresh_tokens: Mapped[list["RefreshToken"]] = relationship(
        "RefreshToken", back_populates="user", cascade="all, delete-orphan"
    )


# For circular import issues, import the RefreshToken model at the end of the file
from modules.auth.models import RefreshToken