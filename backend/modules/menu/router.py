from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from uuid import UUID
from typing import List, Optional

from core.database import get_db
from utils.response_wrapper import ResponseWrapper
from .schemas import (
    CategoryCreate, CategoryUpdate, CategoryRead,
    MenuItemCreate, MenuItemUpdate, MenuItemRead
)
from . import services
from core.denpendencies.role_access import require_role
from core.enums import UserRole

router = APIRouter(prefix="/menu", tags=["Menu"])
IS_ADMIN = UserRole.ADMIN.value

# ── Category Endpoints ────────────────────────────────────────────────────────

@router.post("/categories", response_model=ResponseWrapper[CategoryRead],
            response_model_exclude_none=True,)
def create_category(data: CategoryCreate, 
                    db: Session = Depends(get_db), 
                    current_user: dict = require_role(IS_ADMIN)):
    result = services.create_category(db, data)
    return ResponseWrapper.success_response(result)

@router.get("/categories/{category_id}", response_model=ResponseWrapper[CategoryRead],
            response_model_exclude_none=True)
def get_category(category_id: UUID, db: Session = Depends(get_db)):
    result = services.get_category_by_id(db, category_id)
    return ResponseWrapper.success_response(result)

@router.get("/categories", response_model=ResponseWrapper[List[CategoryRead]],
            response_model_exclude_none=True)
def list_categories(restaurant_id: Optional[UUID] = None, skip: int = 0, limit: int = 50, db: Session = Depends(get_db)):
    result = services.get_categories(db, restaurant_id, skip, limit)
    return ResponseWrapper.success_response(result)

@router.put("/categories/{category_id}", response_model=ResponseWrapper[CategoryRead],
            response_model_exclude_none=True)
def update_category(category_id: UUID, data: CategoryUpdate, 
                    db: Session = Depends(get_db), 
                    current_user: dict = require_role(IS_ADMIN)):
    result = services.update_category(db, category_id, data)
    return ResponseWrapper.success_response(result)

@router.delete("/categories/{category_id}", response_model=ResponseWrapper[dict],
               response_model_exclude_none=True)
def delete_category(category_id: UUID, 
                    db: Session = Depends(get_db), 
                    current_user: dict = require_role(IS_ADMIN)):
    services.delete_category(db, category_id)
    return ResponseWrapper.success_response({"message": "Category deleted successfully"})

@router.get("/categories/{category_id}/items", response_model=ResponseWrapper[List[MenuItemRead]],
            response_model_exclude_none=True)
def get_items_by_category(category_id: UUID, skip: int = 0, limit: int = 50, db: Session = Depends(get_db)):
    result = services.get_menu_items(db, category_id, skip, limit)
    return ResponseWrapper.success_response(result)

# ── Menu Item Endpoints ────────────────────────────────────────────────────────

@router.post("/items", response_model=ResponseWrapper[MenuItemRead],
            response_model_exclude_none=True,
           )
def create_menu_item(data: MenuItemCreate, 
                     db: Session = Depends(get_db), 
                     current_user: dict = require_role(IS_ADMIN)):
    result = services.create_menu_item(db, data)
    return ResponseWrapper.success_response(result)

@router.get("/items", response_model=ResponseWrapper[List[MenuItemRead]],
            response_model_exclude_none=True)
def list_menu_items(category_id: Optional[UUID] = None, skip: int = 0, limit: int = 50, db: Session = Depends(get_db)):
    result = services.get_menu_items(db, category_id, skip, limit)
    return ResponseWrapper.success_response(result)

@router.get("/items/{menu_item_id}", response_model=ResponseWrapper[MenuItemRead],
            response_model_exclude_none=True)
def get_menu_item(menu_item_id: UUID, db: Session = Depends(get_db)):
    result = services.get_menu_item_by_id(db, menu_item_id)
    return ResponseWrapper.success_response(result)

@router.put("/items/{menu_item_id}", response_model=ResponseWrapper[MenuItemRead],
            response_model_exclude_none=True)
def update_menu_item(menu_item_id: UUID, data: MenuItemUpdate, 
                    db: Session = Depends(get_db), 
                    current_user: dict = require_role(IS_ADMIN)):
    result = services.update_menu_item(db, menu_item_id, data)
    return ResponseWrapper.success_response(result)

@router.delete("/items/{menu_item_id}", response_model=ResponseWrapper[dict],
               response_model_exclude_none=True)
def delete_menu_item(menu_item_id: UUID, 
                    db: Session = Depends(get_db),
                    current_user: dict = require_role(IS_ADMIN)):
    result = services.delete_menu_item(db, menu_item_id)
    return ResponseWrapper.success_response(result)
