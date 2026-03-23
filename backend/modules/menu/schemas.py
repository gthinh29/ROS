from pydantic import BaseModel, ConfigDict, Field
from typing import Optional, List
from uuid import UUID
from datetime import datetime


# ── Category schemas ──────────────────────────────────────────────────────────

class CategoryBase(BaseModel):
    restaurant_id: UUID
    name: str = Field(..., max_length=100)

class CategoryCreate(CategoryBase):
    pass

class CategoryUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    sort_order: Optional[int] = None

class CategoryRead(CategoryBase):
    id: UUID

    model_config = ConfigDict(from_attributes=True)


# ── Variant schemas ───────────────────────────────────────────────────────────

class VariantBase(BaseModel):
    name: str = Field(..., max_length=100)
    extra_price: float = 0.0

class VariantCreate(VariantBase):
    pass

class VariantUpdate(BaseModel):
    id: Optional[UUID] = None
    name: Optional[str] = Field(None, max_length=100)
    extra_price: Optional[float] = None

class VariantRead(VariantBase):
    id: UUID
    menu_item_id: UUID

    model_config = ConfigDict(from_attributes=True)


# ── Modifier schemas ──────────────────────────────────────────────────────────

class ModifierBase(BaseModel):
    name: str = Field(..., max_length=100)
    extra_price: float = 0.0
    is_required: bool = False

class ModifierCreate(ModifierBase):
    pass

class ModifierUpdate(BaseModel):
    id: Optional[UUID] = None
    name: Optional[str] = Field(None, max_length=100)
    extra_price: Optional[float] = None
    is_required: Optional[bool] = None

class ModifierRead(ModifierBase):
    id: UUID
    menu_item_id: UUID

    model_config = ConfigDict(from_attributes=True)


# ── MenuItem schemas ──────────────────────────────────────────────────────────

class MenuItemBase(BaseModel):
    category_id: UUID
    name: str = Field(..., max_length=200)
    base_price: float
    image_url: Optional[str] = None
    is_available: bool = True
    kds_zone: str = Field(default="kitchen", max_length=20)

class MenuItemCreate(MenuItemBase):
    variants: List[VariantCreate] = []
    modifiers: List[ModifierCreate] = []

class MenuItemUpdate(BaseModel):
    category_id: Optional[UUID] = None
    name: Optional[str] = Field(None, max_length=200)
    base_price: Optional[float] = None
    image_url: Optional[str] = None
    is_available: Optional[bool] = None
    kds_zone: Optional[str] = Field(None, max_length=20)
    variants: Optional[List[VariantUpdate]] = None
    modifiers: Optional[List[ModifierUpdate]] = None

class MenuItemRead(MenuItemBase):
    id: UUID
    created_at: datetime
    variants: List[VariantRead] = []
    modifiers: List[ModifierRead] = []

    model_config = ConfigDict(from_attributes=True)
