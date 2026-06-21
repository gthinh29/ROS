



from datetime import datetime
import uuid



from sqlalchemy import DateTime, Enum, ForeignKey, Integer, Numeric, String, Text, func

from sqlalchemy.dialects.postgresql import UUID

from sqlalchemy.orm import Mapped, mapped_column, relationship



from core.database import Base

from core.enums import ReservationStatus





class Reservation(Base):

    __tablename__ = "reservations"



    id: Mapped[uuid.UUID] = mapped_column(

        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4

    )

    table_id: Mapped[uuid.UUID | None] = mapped_column(

        UUID(as_uuid=True), ForeignKey("tables.id"), nullable=True

    )

    customer_name: Mapped[str] = mapped_column(String(100), nullable=False)

    phone: Mapped[str] = mapped_column(String(20), nullable=False)

    email: Mapped[str] = mapped_column(String(255), nullable=False)

    reserved_at: Mapped[datetime] = mapped_column(

        DateTime(timezone=True), nullable=False

    )

    party_size: Mapped[int] = mapped_column(Integer, nullable=False, default=1)

    status: Mapped[ReservationStatus] = mapped_column(

        Enum(ReservationStatus, name="reservationstatus", create_constraint=True),

        default=ReservationStatus.PENDING,

    )

    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    otp_code: Mapped[str | None] = mapped_column(String(10), nullable=True)

    otp_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    created_at: Mapped[datetime] = mapped_column(

        DateTime(timezone=True), server_default=func.now()

    )



