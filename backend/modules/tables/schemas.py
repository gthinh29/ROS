import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict
from core.enums import TableStatus

class TableBase(BaseModel):
    zone: str
    number: int
    restaurant_id: uuid.UUID
    
class TableCreate(TableBase):
    pass

class TableRead(TableBase):
    id: uuid.UUID
    status: TableStatus
    upcoming_reservation_time: datetime | None = None

    model_config = ConfigDict(from_attributes=True)
