"""Pydantic schemas for the Orders module."""
from __future__ import annotations

import uuid
from typing import List, Optional

from pydantic import BaseModel, Field

from core.enums import OrderItemStatus, OrderStatus, OrderType




class OrderModifierCreate(BaseModel):
    modifier_id: uuid.UUID


class OrderItemCreate(BaseModel):
    menu_item_id: uuid.UUID
    variant_id: Optional[uuid.UUID] = None
    qty: int = Field(default=1, ge=1)
    note: Optional[str] = None
    modifier_ids: List[uuid.UUID] = Field(default_factory=list)


class OrderCreate(BaseModel):
    table_id: Optional[uuid.UUID] = None
    reservation_id: Optional[uuid.UUID] = None
    customer_name: Optional[str] = Field(None, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    type: OrderType = OrderType.DINE_IN
    items: List[OrderItemCreate] = Field(..., min_length=1)


class OrderItemStatusUpdate(BaseModel):
    status: OrderItemStatus




class OrderModifierRead(BaseModel):
    id: uuid.UUID
    modifier_id: uuid.UUID
    price: float

    model_config = {"from_attributes": True}


class OrderItemRead(BaseModel):
    id: uuid.UUID
    order_id: Optional[uuid.UUID] = None
    menu_item_id: uuid.UUID
    menu_item_name: Optional[str] = None  
    variant_id: Optional[uuid.UUID] = None
    variant_name: Optional[str] = None    
    qty: int
    price: float
    note: Optional[str] = None
    status: OrderItemStatus
    modifiers: List[OrderModifierRead] = []
    created_at: Optional[str] = None

    model_config = {"from_attributes": True}

class OrderItemTrackingRead(BaseModel):
    id: uuid.UUID
    menu_item_id: uuid.UUID
    name: str
    image_url: str
    quantity: int
    price: float
    status: str

    model_config = {"from_attributes": True}


class OrderRead(BaseModel):
    id: uuid.UUID
    table_id: Optional[uuid.UUID]
    reservation_id: Optional[uuid.UUID]
    customer_name: Optional[str]
    phone: Optional[str]
    type: OrderType
    status: OrderStatus
    total: float
    items: List[OrderItemRead] = []

    model_config = {"from_attributes": True}

class OrderTrackingRead(BaseModel):
    id: uuid.UUID
    status: str
    items: List[OrderItemTrackingRead] = []

    model_config = {"from_attributes": True}

