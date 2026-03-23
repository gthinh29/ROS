from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from uuid import UUID
from typing import List, Optional

from core.database import get_db
from utils.response_wrapper import ResponseWrapper
from .schemas import (
    CategoryCreate, CategoryUpdate, CategoryRead,
    MenuItemCreate, MenuItemUpdate, MenuItemRead,
    VariantCreate, VariantUpdate, VariantRead,
    ModifierCreate, ModifierUpdate, ModifierRead,
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

@router.patch("/categories/{category_id}", response_model=ResponseWrapper[CategoryRead],
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
    result = services.delete_category(db, category_id)
    return ResponseWrapper.success_response(result)

@router.get("/categories/{category_id}/items", response_model=ResponseWrapper[List[MenuItemRead]],
            response_model_exclude_none=True)
def get_items_by_category(category_id: UUID, skip: int = 0, limit: int = 50, db: Session = Depends(get_db)):
    result = services.get_menu_items(db, category_id=category_id, skip=skip, limit=limit)
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
def list_menu_items(
    category_id: Optional[UUID] = None,
    is_available: Optional[bool] = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    result = services.get_menu_items(db, category_id, is_available, skip, limit)
    return ResponseWrapper.success_response(result)

@router.get("/items/{menu_item_id}", response_model=ResponseWrapper[MenuItemRead],
            response_model_exclude_none=True)
def get_menu_item(menu_item_id: UUID, db: Session = Depends(get_db)):
    result = services.get_menu_item_by_id(db, menu_item_id)
    return ResponseWrapper.success_response(result)

@router.patch("/items/{menu_item_id}", response_model=ResponseWrapper[MenuItemRead],
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


@router.post("/items/{menu_item_id}/variants", response_model=ResponseWrapper[VariantRead],
             response_model_exclude_none=True)
def create_variant(
    menu_item_id: UUID,
    data: VariantCreate,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_ADMIN),
):
    result = services.create_variant(db, menu_item_id, data)
    return ResponseWrapper.success_response(result)


@router.get("/items/{menu_item_id}/variants", response_model=ResponseWrapper[List[VariantRead]],
            response_model_exclude_none=True)
def list_variants(menu_item_id: UUID, db: Session = Depends(get_db)):
    result = services.get_variants_by_menu_item(db, menu_item_id)
    return ResponseWrapper.success_response(result)


@router.get("/variants/{variant_id}", response_model=ResponseWrapper[VariantRead],
            response_model_exclude_none=True)
def get_variant(variant_id: UUID, db: Session = Depends(get_db)):
    result = services.get_variant_by_id(db, variant_id)
    return ResponseWrapper.success_response(result)


@router.patch("/variants/{variant_id}", response_model=ResponseWrapper[VariantRead],
              response_model_exclude_none=True)
def update_variant(
    variant_id: UUID,
    data: VariantUpdate,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_ADMIN),
):
    result = services.update_variant(db, variant_id, data)
    return ResponseWrapper.success_response(result)


@router.delete("/variants/{variant_id}", response_model=ResponseWrapper[dict],
               response_model_exclude_none=True)
def delete_variant(
    variant_id: UUID,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_ADMIN),
):
    services.delete_variant(db, variant_id)
    return ResponseWrapper.success_response({"message": "Variant deleted successfully"})


@router.post("/items/{menu_item_id}/modifiers", response_model=ResponseWrapper[ModifierRead],
             response_model_exclude_none=True)
def create_modifier(
    menu_item_id: UUID,
    data: ModifierCreate,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_ADMIN),
):
    result = services.create_modifier(db, menu_item_id, data)
    return ResponseWrapper.success_response(result)


@router.get("/items/{menu_item_id}/modifiers", response_model=ResponseWrapper[List[ModifierRead]],
            response_model_exclude_none=True)
def list_modifiers(menu_item_id: UUID, db: Session = Depends(get_db)):
    result = services.get_modifiers_by_menu_item(db, menu_item_id)
    return ResponseWrapper.success_response(result)


@router.get("/modifiers/{modifier_id}", response_model=ResponseWrapper[ModifierRead],
            response_model_exclude_none=True)
def get_modifier(modifier_id: UUID, db: Session = Depends(get_db)):
    result = services.get_modifier_by_id(db, modifier_id)
    return ResponseWrapper.success_response(result)


@router.patch("/modifiers/{modifier_id}", response_model=ResponseWrapper[ModifierRead],
              response_model_exclude_none=True)
def update_modifier(
    modifier_id: UUID,
    data: ModifierUpdate,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_ADMIN),
):
    result = services.update_modifier(db, modifier_id, data)
    return ResponseWrapper.success_response(result)


@router.delete("/modifiers/{modifier_id}", response_model=ResponseWrapper[dict],
               response_model_exclude_none=True)
def delete_modifier(
    modifier_id: UUID,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_ADMIN),
):
    services.delete_modifier(db, modifier_id)
    return ResponseWrapper.success_response({"message": "Modifier deleted successfully"})
