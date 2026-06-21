from pydantic import BaseModel
from typing import List

class DailyOverview(BaseModel):
    total_revenue: float
    order_count: int
    active_tables: int

class RevenuePoint(BaseModel):
    date: str
    revenue: float

class TopItem(BaseModel):
    name: str
    quantity: int
