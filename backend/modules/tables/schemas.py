import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict
from core.enums import TableStatus

class TableBase(BaseModel):
    zone: str
    number: int
    restaurant_id: uuid.UUID
    capacity: int = 4
    x_pos: float = 0.0
    y_pos: float = 0.0
    
class TableCreate(TableBase):
    pass

class TableUpdate(BaseModel):
    zone: str | None = None
    number: int | None = None
    capacity: int | None = None
    x_pos: float | None = None
    y_pos: float | None = None

class TableRead(TableBase):
    id: uuid.UUID
    status: TableStatus
    upcoming_reservation_time: datetime | None = None

    model_config = ConfigDict(from_attributes=True)
