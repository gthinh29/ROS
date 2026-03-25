from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status
from uuid import UUID
from typing import List

from .repository import BOMRepository, IngredientRepository
from .models import BOMItem, Ingredient, InventoryLog
from .schemas import MenuBOMUpdate, IngredientCreate, IngredientUpdate
from modules.menu.repository import MenuItemRepository


def create_ingredient(db: Session, data: IngredientCreate) -> Ingredient:
    return IngredientRepository.create(db, data.model_dump())


def get_ingredient(db: Session, ingredient_id: UUID) -> Ingredient:
    ingredient = IngredientRepository.get_by_id(db, ingredient_id)
    if not ingredient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ingredient not found.")
    return ingredient


def list_ingredients(db: Session, skip: int = 0, limit: int = 50) -> List[Ingredient]:
    return IngredientRepository.get_all(db, skip, limit)


def update_ingredient(db: Session, ingredient_id: UUID, data: IngredientUpdate) -> Ingredient:
    ingredient = IngredientRepository.get_by_id(db, ingredient_id)
    if not ingredient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ingredient not found.")

    update_data = data.model_dump(exclude_unset=True)
    if not update_data:
        return ingredient

    old_stock_qty = float(ingredient.stock_qty)
    updated = IngredientRepository.update(db, ingredient, update_data)

    if "stock_qty" in update_data:
        new_stock_qty = float(update_data["stock_qty"])
        delta = new_stock_qty - old_stock_qty
        if delta != 0:
            log = InventoryLog(
                ingredient_id=updated.id,
                delta=delta,
                reason="Manual stock adjustment via ingredient update",
            )
            db.add(log)
            db.commit()
    return updated


def delete_ingredient(db: Session, ingredient_id: UUID) -> None:
    ingredient = IngredientRepository.get_by_id(db, ingredient_id)
    if not ingredient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ingredient not found.")

    try:
        # Cleanup dependent rows first to avoid FK violations on hard delete.
        db.query(BOMItem).filter(BOMItem.ingredient_id == ingredient_id).delete(synchronize_session=False)
        db.query(InventoryLog).filter(InventoryLog.ingredient_id == ingredient_id).delete(synchronize_session=False)

        db.delete(ingredient)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete ingredient due to existing related records.",
        )


def get_bom(db: Session, menu_item_id: UUID) -> List[BOMItem]:
    """Retrieve full Bill of Materials for a Menu Item."""
    menu_item = MenuItemRepository.get_menu_item_by_id(db, menu_item_id)
    if not menu_item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="MenuItem not found.")
    
    return BOMRepository.get_bom_by_menu_item(db, menu_item_id)


def set_bom(db: Session, menu_item_id: UUID, data: MenuBOMUpdate) -> List[BOMItem]:
    """
    Set/Replace Bill of Materials for a Menu Item.
    Enforces strict foreign key validation.
    """
    # Validation 1: Check Menu Item exists
    menu_item = MenuItemRepository.get_menu_item_by_id(db, menu_item_id)
    if not menu_item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="MenuItem not found.")
        
    # Keep valid variants in memory to check
    valid_variant_ids = {v.id for v in menu_item.variants}
    
    # Validation 2: Pre-check all ingredients
    ingredient_ids = [item.ingredient_id for item in data.bom_items]
    if ingredient_ids:
        found_ingredients = db.query(Ingredient.id).filter(Ingredient.id.in_(ingredient_ids)).all()
        found_ingredient_ids = {row[0] for row in found_ingredients}
    else:
        found_ingredient_ids = set()
        
    bom_entities = []
    
    for item in data.bom_items:
        # Strict validation checks
        if item.ingredient_id not in found_ingredient_ids:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, 
                detail=f"Ingredient ID {item.ingredient_id} not found."
            )
                                
        if item.variant_id is not None and item.variant_id not in valid_variant_ids:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, 
                detail=f"Variant ID {item.variant_id} does not belong to Menu Item."
            )
                                
        bom_entities.append(BOMItem(
            menu_item_id=menu_item_id,
            variant_id=item.variant_id,
            ingredient_id=item.ingredient_id,
            qty_required=item.qty_required
        ))
        
    # Full replace algorithm
    BOMRepository.delete_bom_for_menu_item(db, menu_item_id)
    
    if bom_entities:
        BOMRepository.create_bom_items(db, bom_entities)
        
    return BOMRepository.get_bom_by_menu_item(db, menu_item_id)
