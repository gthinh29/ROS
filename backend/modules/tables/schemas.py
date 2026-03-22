import uuid
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
    qr_token: str
    status: TableStatus

    model_config = ConfigDict(from_attributes=True)
