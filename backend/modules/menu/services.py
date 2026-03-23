from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from uuid import UUID
from typing import List

from .repository import (
    CategoryRepository,
    MenuItemRepository,
    VariantRepository,
    ModifierRepository,
)
from .models import Category, MenuItem, Variant, Modifier
from .schemas import (
    CategoryCreate,
    CategoryUpdate,
    MenuItemCreate, MenuItemUpdate,
    VariantCreate,
    VariantUpdate,
    ModifierCreate,
    ModifierUpdate,
)
# We will need OrderItem from orders to check dependencies
# Since we didn't do orders fully, we can import the model directly if possible.
from modules.orders.models import OrderItem
from modules.inventory.models import BOMItem


# ── Category Services ─────────────────────────────────────────────────────────

# Create category
def create_category(db: Session, data: CategoryCreate) -> Category:
    existing_cat = CategoryRepository.get_category_by_name(db, data.restaurant_id, data.name)
    if existing_cat:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, 
                            detail="Category name already exists for this restaurant.")
    return CategoryRepository.create_category(db, data.model_dump())

# Get categories with optional restaurant filter and pagination
def get_categories(db: Session, restaurant_id: UUID = None, skip: int = 0, limit: int = 50) -> List[Category]:
    list_categories = CategoryRepository.get_categories(db, restaurant_id, skip, limit)
    if not list_categories:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No categories found.")
    return list_categories

# Get category by ID
def get_category_by_id(db: Session, category_id: UUID) -> Category:
    existing_cat = CategoryRepository.get_category_by_id(db, category_id)
    if not existing_cat:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found.")
    return existing_cat

# Update category
def update_category(db: Session, category_id: UUID, data: CategoryUpdate) -> Category:
    db_obj = CategoryRepository.get_category_by_id(db, category_id)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found.")
    
    if data.name and data.name != db_obj.name:
        existing_cat = CategoryRepository.get_category_by_name(db, db_obj.restaurant_id, data.name)
        if existing_cat:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Category name already exists for this restaurant.")
    
    update_data = data.model_dump(exclude_unset=True)
    return CategoryRepository.update_category(db, db_obj, update_data)

# Delete category only if it has no menu items. Otherwise, return an error message.
def delete_category(db: Session, category_id: UUID) -> None:
    db_obj = CategoryRepository.get_category_by_id(db, category_id)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found.")
    
    # Check if category has any menu items
    menu_items = MenuItemRepository.get_menu_items(db, category_id=category_id, limit=1)
    if menu_items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Cannot delete category containing menu items. Please remove or reassign the menu items first."
        )
        
    CategoryRepository.delete_category(db, db_obj)
    return {"message": "Category deleted successfully."}


# ── MenuItem Services ─────────────────────────────────────────────────────────

def create_menu_item(db: Session, data: MenuItemCreate) -> MenuItem:
    # Validate category exists
    cat = CategoryRepository.get_category_by_id(db, data.category_id)
    if not cat:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Provided category_id does not exist.")
        
    # Check if item name already exists in the same category
    existing_item = MenuItemRepository.get_menu_item_by_name(db, data.category_id, data.name)
    if existing_item:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Menu item name already exists in this category.")
        
    item_data = data.model_dump(exclude={"variants", "modifiers"})
    variants_data = [v.model_dump() for v in data.variants]
    modifiers_data = [m.model_dump() for m in data.modifiers]
    
    return MenuItemRepository.create_menu_item(db, item_data, variants_data, modifiers_data)


def get_menu_items(
    db: Session,
    category_id: UUID = None,
    is_available: bool = None,
    skip: int = 0,
    limit: int = 50,
) -> List[MenuItem]:
    list_menu_items = MenuItemRepository.get_menu_items(db, category_id, is_available, skip, limit)
    if not list_menu_items:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No menu items found.")
    return list_menu_items


def get_menu_item_by_id(db: Session, menu_item_id: UUID) -> MenuItem:
    obj = MenuItemRepository.get_menu_item_by_id(db, menu_item_id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Menu Item not found.")
    return obj


def update_menu_item(db: Session, menu_item_id: UUID, data: MenuItemUpdate) -> MenuItem:
    db_obj = MenuItemRepository.get_menu_item_by_id(db, menu_item_id)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Menu Item not found.")
        
    target_category_id = data.category_id if data.category_id else db_obj.category_id
        
    if data.category_id:
        cat = CategoryRepository.get_category_by_id(db, data.category_id)
        if not cat:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Provided category does not exist.")

    # Check for name uniqueness if name or category is being updated
    if data.name and (data.name != db_obj.name or data.category_id):
        existing_item = MenuItemRepository.get_menu_item_by_name(db, target_category_id, data.name)
        if existing_item and existing_item.id != db_obj.id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Menu item name already exists in the target category.")

    # Update simple fields
    update_data = data.model_dump(exclude={"variants", "modifiers"}, exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_obj, key, value)
        
    # Nested Sync for Variants
    if data.variants is not None:
        incoming_variants = {v.id: v for v in data.variants if v.id is not None}
        existing_variants = {v.id: v for v in db_obj.variants}
        
        # 1. Delete removed variants
        for existing_id, existing_v in list(existing_variants.items()):
            if existing_id not in incoming_variants:
                db_obj.variants.remove(existing_v)
                
        # 2. Update existing and Insert new
        for incoming_v in data.variants:
            if incoming_v.id and incoming_v.id in existing_variants:
                existing_variant = existing_variants[incoming_v.id]
                existing_variant.name = incoming_v.name if incoming_v.name is not None else existing_variant.name
                existing_variant.extra_price = incoming_v.extra_price if incoming_v.extra_price is not None else existing_variant.extra_price
            else:
                db_obj.variants.append(Variant(
                    name=incoming_v.name,
                    extra_price=incoming_v.extra_price if incoming_v.extra_price is not None else 0.0
                ))

    # Nested Sync for Modifiers
    if data.modifiers is not None:
        incoming_modifiers = {m.id: m for m in data.modifiers if m.id is not None}
        existing_modifiers = {m.id: m for m in db_obj.modifiers}
        
        # 1. Delete removed modifiers
        for existing_id, existing_m in list(existing_modifiers.items()):
            if existing_id not in incoming_modifiers:
                db_obj.modifiers.remove(existing_m)
                
        # 2. Update existing and Insert new
        for incoming_m in data.modifiers:
            if incoming_m.id and incoming_m.id in existing_modifiers:
                existing_modifier = existing_modifiers[incoming_m.id]
                existing_modifier.name = incoming_m.name if incoming_m.name is not None else existing_modifier.name
                existing_modifier.extra_price = incoming_m.extra_price if incoming_m.extra_price is not None else existing_modifier.extra_price
                existing_modifier.is_required = incoming_m.is_required if incoming_m.is_required is not None else existing_modifier.is_required
            else:
                db_obj.modifiers.append(Modifier(
                    name=incoming_m.name,
                    extra_price=incoming_m.extra_price if incoming_m.extra_price is not None else 0.0,
                    is_required=incoming_m.is_required if incoming_m.is_required is not None else False
                ))

    db.commit()
    db.refresh(db_obj)
    return db_obj


def delete_menu_item(db: Session, menu_item_id: UUID) -> dict:
    db_obj = MenuItemRepository.get_menu_item_by_id(db, menu_item_id)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Menu Item not found.")
        
    # Validation Rule: Check if MenuItem has ever been ordered
    order_count = db.query(OrderItem).filter(OrderItem.menu_item_id == menu_item_id).count()
    if order_count > 0:
        # Soft delete: just make it unavailable
        db_obj.is_available = False
        db.commit()
        return {"message": "Menu Item has associated orders and was soft-deleted (is_available = False).", "soft_deleted": True}
        
    # If no orders, proceed with Hard Delete
    # 1. Clean up BOMItems to fix foreign key constraints
    # (Because BOMItem.menu_item_id does not have ondelete=CASCADE)
    db.query(BOMItem).filter(BOMItem.menu_item_id == menu_item_id).delete(synchronize_session=False)
    
    # 2. Hard delete MenuItem (Variants and Modifiers will drop due to cascade)
    MenuItemRepository.delete_menu_item(db, db_obj)
    return {"message": "Menu Item and related items successfully hard-deleted.", "soft_deleted": False}


# ── Variant Services ─────────────────────────────────────────────────────────
def get_variants_by_menu_item(db: Session, menu_item_id: UUID) -> List[Variant]:
    menu_item = MenuItemRepository.get_menu_item_by_id(db, menu_item_id)
    if not menu_item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Menu Item not found.")
    return VariantRepository.get_variants_by_menu_item(db, menu_item_id)


def get_variant_by_id(db: Session, variant_id: UUID) -> Variant:
    variant = VariantRepository.get_variant_by_id(db, variant_id)
    if not variant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variant not found.")
    return variant


# Create variant for a menu item
def create_variant(db: Session, menu_item_id: UUID, data: VariantCreate) -> Variant:
    menu_item = MenuItemRepository.get_menu_item_by_id(db, menu_item_id)
    if not menu_item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Menu Item not found.")

    return VariantRepository.create_variant(
        db,
        {
            "menu_item_id": menu_item_id,
            "name": data.name,
            "extra_price": data.extra_price,
        },
    )

# Update variant
def update_variant(db: Session, variant_id: UUID, data: VariantUpdate) -> Variant:
    variant = VariantRepository.get_variant_by_id(db, variant_id)
    if not variant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variant not found.")

    update_data = data.model_dump(exclude_unset=True, exclude={"id"})
    if not update_data:
        return variant
    return VariantRepository.update_variant(db, variant, update_data)

# Delete variant
def delete_variant(db: Session, variant_id: UUID) -> None:
    variant = VariantRepository.get_variant_by_id(db, variant_id)
    if not variant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variant not found.")
    VariantRepository.delete_variant(db, variant)
    return {"message": "Variant deleted successfully."}

# ── Modifier Services ─────────────────────────────────────────────────────────
def get_modifiers_by_menu_item(db: Session, menu_item_id: UUID) -> List[Modifier]:
    menu_item = MenuItemRepository.get_menu_item_by_id(db, menu_item_id)
    if not menu_item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Menu Item not found.")
    return ModifierRepository.get_modifiers_by_menu_item(db, menu_item_id)


def get_modifier_by_id(db: Session, modifier_id: UUID) -> Modifier:
    modifier = ModifierRepository.get_modifier_by_id(db, modifier_id)
    if not modifier:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Modifier not found.")
    return modifier


# Create modifier for a menu item
def create_modifier(db: Session, menu_item_id: UUID, data: ModifierCreate) -> Modifier:
    menu_item = MenuItemRepository.get_menu_item_by_id(db, menu_item_id)
    if not menu_item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Menu Item not found.")

    return ModifierRepository.create_modifier(
        db,
        {
            "menu_item_id": menu_item_id,
            "name": data.name,
            "extra_price": data.extra_price,
            "is_required": data.is_required,
        },
    )

# Update modifier
def update_modifier(db: Session, modifier_id: UUID, data: ModifierUpdate) -> Modifier:
    modifier = ModifierRepository.get_modifier_by_id(db, modifier_id)
    if not modifier:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Modifier not found.")

    update_data = data.model_dump(exclude_unset=True, exclude={"id"})
    if not update_data:
        return modifier
    return ModifierRepository.update_modifier(db, modifier, update_data)

# Delete modifier
def delete_modifier(db: Session, modifier_id: UUID) -> None:
    modifier = ModifierRepository.get_modifier_by_id(db, modifier_id)
    if not modifier:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Modifier not found.")
    ModifierRepository.delete_modifier(db, modifier)
    return {"message": "Modifier deleted successfully."}
