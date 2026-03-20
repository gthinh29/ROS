from core.enums import UserRole
from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
from datetime import datetime

class UserBase(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: Optional[str] = Field(None, min_length=11, max_length=255, pattern=r'^\S+@\S+\.\S+$')
    role: UserRole
    phone: Optional[str] = Field(None, min_length=10, max_length=30, pattern=r'^\+?\d{10,30}$')
    is_active: Optional[bool] = True

class UserCreate(UserBase):
    password: str = Field(min_length=6, max_length=128)

class UserRead(UserBase):
    id: UUID
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}

class UserUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    email: Optional[str] = Field(None, min_length=11, max_length=255, pattern=r'^\S+@\S+\.\S+$')
    role: Optional[UserRole] = None
    phone: Optional[str] = Field(None, min_length=10, max_length=30, pattern=r'^\+?\d{10,30}$')
    is_active: Optional[bool] = None
    password: Optional[str] = Field(None, min_length=6, max_length=128)
