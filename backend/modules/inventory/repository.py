from sqlalchemy.orm import Session

from .models import BOMItem, Ingredient, InventoryLog

from uuid import UUID

from typing import List, Set





class IngredientRepository:

    @staticmethod

    def create(db: Session, data: dict) -> Ingredient:

        db_obj = Ingredient(**data)

        db.add(db_obj)

        db.commit()

        db.refresh(db_obj)

        return db_obj



    @staticmethod

    def get_by_id(db: Session, ingredient_id: UUID) -> Ingredient | None:

        return db.query(Ingredient).filter(Ingredient.id == ingredient_id).first()



    @staticmethod

    def get_all(db: Session, skip: int = 0, limit: int = 50) -> List[Ingredient]:

        return db.query(Ingredient).offset(skip).limit(limit).all()



    @staticmethod

    def update(db: Session, db_obj: Ingredient, update_data: dict) -> Ingredient:

        for key, value in update_data.items():

            setattr(db_obj, key, value)

        db.commit()

        db.refresh(db_obj)

        return db_obj



    @staticmethod

    def delete(db: Session, db_obj: Ingredient) -> None:

        db.delete(db_obj)

        db.commit()

    @staticmethod
    def delete_with_relations(db: Session, db_obj: Ingredient) -> None:
        db.query(BOMItem).filter(BOMItem.ingredient_id == db_obj.id).delete(synchronize_session=False)
        db.query(InventoryLog).filter(InventoryLog.ingredient_id == db_obj.id).delete(synchronize_session=False)
        db.delete(db_obj)
        db.commit()

    @staticmethod
    def get_existing_ids(db: Session, ingredient_ids: List[UUID]) -> Set[UUID]:
        rows = db.query(Ingredient.id).filter(Ingredient.id.in_(ingredient_ids)).all()
        return {row[0] for row in rows}



class InventoryLogRepository:
    @staticmethod
    def create(db: Session, data: dict) -> InventoryLog:
        db_obj = InventoryLog(**data)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

class BOMRepository:

    @staticmethod

    def get_bom_by_menu_item(db: Session, menu_item_id: UUID) -> List[BOMItem]:

        return db.query(BOMItem).filter(BOMItem.menu_item_id == menu_item_id).all()

        

    @staticmethod

    def delete_bom_for_menu_item(db: Session, menu_item_id: UUID) -> None:

        db.query(BOMItem).filter(BOMItem.menu_item_id == menu_item_id).delete()

        db.commit()

        

    @staticmethod

    def create_bom_items(db: Session, items: List[BOMItem]) -> List[BOMItem]:

        db.add_all(items)

        db.commit()

        for item in items:

            db.refresh(item)

        return items

