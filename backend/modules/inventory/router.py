from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from uuid import UUID
from typing import List

from core.database import get_db
from utils.response_wrapper import ResponseWrapper
from .schemas import (
    MenuBOMUpdate,
    BOMItemRead,
    IngredientCreate,
    IngredientUpdate,
    IngredientRead,
)
from . import services

from core.denpendencies.role_access import require_role
from core.enums import UserRole

router = APIRouter(prefix="/inventory", tags=["Inventory"])

# ── BOM Endpoints ─────────────────────────────────────────────────────────────
IS_ADMIN = UserRole.ADMIN.value


@router.post("/ingredients",
             status_code=status.HTTP_201_CREATED,
             response_model=ResponseWrapper[IngredientRead],
             response_model_exclude_none=True)
def create_ingredient(
    data: IngredientCreate,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_ADMIN),
):
    result = services.create_ingredient(db, data)
    return ResponseWrapper.success_response(result)


@router.get("/ingredients",
            response_model=ResponseWrapper[List[IngredientRead]],
            response_model_exclude_none=True)
def list_ingredients(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    result = services.list_ingredients(db, skip, limit)
    return ResponseWrapper.success_response(result)


@router.get("/ingredients/{ingredient_id}",
            response_model=ResponseWrapper[IngredientRead],
            response_model_exclude_none=True)
def get_ingredient(ingredient_id: UUID, db: Session = Depends(get_db)):
    result = services.get_ingredient(db, ingredient_id)
    return ResponseWrapper.success_response(result)


@router.patch("/ingredients/{ingredient_id}",
            response_model=ResponseWrapper[IngredientRead],
            response_model_exclude_none=True)
def update_ingredient(
    ingredient_id: UUID,
    data: IngredientUpdate,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_ADMIN),
):
    result = services.update_ingredient(db, ingredient_id, data)
    return ResponseWrapper.success_response(result)


@router.delete("/ingredients/{ingredient_id}",
               response_model=ResponseWrapper[dict],
               response_model_exclude_none=True)
def delete_ingredient(
    ingredient_id: UUID,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_ADMIN),
):
    services.delete_ingredient(db, ingredient_id)
    return ResponseWrapper.success_response({"message": "Ingredient deleted successfully"})

@router.get("/bom/menu-items/{menu_item_id}", 
            response_model=ResponseWrapper[List[BOMItemRead]],
            response_model_exclude_none=True)
def get_menu_item_bom(menu_item_id: UUID, db: Session = Depends(get_db)):
    """Retrieve full Bill of Materials for a Menu Item."""
    result = services.get_bom(db, menu_item_id)
    return ResponseWrapper.success_response(result)

@router.put("/bom/menu-items/{menu_item_id}", 
            response_model=ResponseWrapper[List[BOMItemRead]],
            response_model_exclude_none=True)
def set_menu_item_bom(menu_item_id: UUID, 
                      data: MenuBOMUpdate, 
                      db: Session = Depends(get_db),
                      current_user: dict = require_role(IS_ADMIN)):
    """Set/Replace Bill of Materials for a Menu Item."""
    result = services.set_bom(db, menu_item_id, data)
    return ResponseWrapper.success_response(result)
