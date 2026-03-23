from sqlalchemy.orm import Session, selectinload
from .models import Category, MenuItem, Variant, Modifier
from uuid import UUID


class CategoryRepository:
    @staticmethod
    def get_category_by_id(db: Session, category_id: UUID) -> Category | None:
        return db.query(Category).filter(Category.id == category_id).first()

    @staticmethod
    def get_category_by_name(db: Session, restaurant_id: UUID, name: str) -> Category | None:
        return db.query(Category).filter(
            Category.restaurant_id == restaurant_id,
            Category.name == name
        ).first()

    @staticmethod
    def get_categories(db: Session, restaurant_id: UUID = None, skip: int = 0, limit: int = 50) -> list[Category]:
        query = db.query(Category)
        if restaurant_id:
            query = query.filter(Category.restaurant_id == restaurant_id)
        query = query.order_by(Category.sort_order).offset(skip).limit(limit)
        return query.all()

    @staticmethod
    def create_category(db: Session, data: dict) -> Category:
        db_obj = Category(**data)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    @staticmethod
    def update_category(db: Session, db_obj: Category, update_data: dict) -> Category:
        for key, value in update_data.items():
            setattr(db_obj, key, value)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    @staticmethod
    def delete_category(db: Session, db_obj: Category) -> None:
        db.delete(db_obj)
        db.commit()


class MenuItemRepository:
    @staticmethod
    def get_menu_item_by_id(db: Session, menu_item_id: UUID) -> MenuItem | None:
        return db.query(MenuItem).options(
            selectinload(MenuItem.variants),
            selectinload(MenuItem.modifiers)
        ).filter(MenuItem.id == menu_item_id).first()

    @staticmethod
    def get_menu_item_by_name(db: Session, category_id: UUID, name: str) -> MenuItem | None:
        return db.query(MenuItem).filter(
            MenuItem.category_id == category_id,
            MenuItem.name == name
        ).first()

    @staticmethod
    def get_menu_items(db: Session, category_id: UUID = None, is_available: bool = None, skip: int = 0, limit: int = 50) -> list[MenuItem]:
        query = db.query(MenuItem).options(
            selectinload(MenuItem.variants),
            selectinload(MenuItem.modifiers)
        )
        if category_id:
            query = query.filter(MenuItem.category_id == category_id)
        if is_available is not None:
            query = query.filter(MenuItem.is_available == is_available)
        return query.offset(skip).limit(limit).all()

    @staticmethod
    def create_menu_item(db: Session, data: dict, variants_data: list = None, modifiers_data: list = None) -> MenuItem:
        db_obj = MenuItem(**data)
        
        if variants_data:
            for v_data in variants_data:
                # Expecting v_data to be a dict or a Pydantic model dump
                db_obj.variants.append(Variant(**v_data))
                
        if modifiers_data:
            for m_data in modifiers_data:
                db_obj.modifiers.append(Modifier(**m_data))
                
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    @staticmethod
    def delete_menu_item(db: Session, db_obj: MenuItem) -> None:
        db.delete(db_obj)
        db.commit()


class VariantRepository:
    @staticmethod
    def get_variants_by_menu_item(db: Session, menu_item_id: UUID) -> list[Variant]:
        return db.query(Variant).filter(Variant.menu_item_id == menu_item_id).all()

    @staticmethod
    def get_variant_by_id(db: Session, variant_id: UUID) -> Variant | None:
        return db.query(Variant).filter(Variant.id == variant_id).first()

    @staticmethod
    def create_variant(db: Session, data: dict) -> Variant:
        db_obj = Variant(**data)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    @staticmethod
    def update_variant(db: Session, db_obj: Variant, update_data: dict) -> Variant:
        for key, value in update_data.items():
            setattr(db_obj, key, value)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    @staticmethod
    def delete_variant(db: Session, db_obj: Variant) -> None:
        db.delete(db_obj)
        db.commit()


class ModifierRepository:
    @staticmethod
    def get_modifiers_by_menu_item(db: Session, menu_item_id: UUID) -> list[Modifier]:
        return db.query(Modifier).filter(Modifier.menu_item_id == menu_item_id).all()

    @staticmethod
    def get_modifier_by_id(db: Session, modifier_id: UUID) -> Modifier | None:
        return db.query(Modifier).filter(Modifier.id == modifier_id).first()

    @staticmethod
    def create_modifier(db: Session, data: dict) -> Modifier:
        db_obj = Modifier(**data)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    @staticmethod
    def update_modifier(db: Session, db_obj: Modifier, update_data: dict) -> Modifier:
        for key, value in update_data.items():
            setattr(db_obj, key, value)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    @staticmethod
    def delete_modifier(db: Session, db_obj: Modifier) -> None:
        db.delete(db_obj)
        db.commit()
