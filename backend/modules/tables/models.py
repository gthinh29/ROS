



import datetime
import uuid



from sqlalchemy import (

    DateTime,

    Enum,

    ForeignKey,

    Integer,

    Float,

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

    created_at: Mapped[datetime] = mapped_column(

        DateTime(timezone=True), server_default=func.now()

    )



    

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

    status: Mapped[TableStatus] = mapped_column(

        Enum(TableStatus, name="tablestatus", create_constraint=True),

        default=TableStatus.EMPTY,

    )

    capacity: Mapped[int] = mapped_column(Integer, default=4, nullable=False)

    x_pos: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    y_pos: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    created_at: Mapped[datetime] = mapped_column(

        DateTime(timezone=True), server_default=func.now()

    )



    

    restaurant = relationship("Restaurant", back_populates="tables")

