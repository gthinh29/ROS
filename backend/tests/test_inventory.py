import uuid
from types import SimpleNamespace

import pytest

from modules.inventory import services as inventory_services
from modules.inventory.schemas import BOMItemCreate


class FakeQuery:
    def __init__(self, rows=None):
        self.rows = rows or []
        self.deleted = False

    def filter(self, *args, **kwargs):
        return self

    def all(self):
        return self.rows

    def delete(self, synchronize_session=False):
        self.deleted = True


class FakeDB:
    def __init__(self):
        self.committed = 0
        self.added = []
        self.queries = []
        self.custom_query = None

    def add(self, obj):
        self.added.append(obj)

    def commit(self):
        self.committed += 1

    def refresh(self, obj):
        return None

    def query(self, model):
        self.queries.append(model)
        if self.custom_query is not None:
            return self.custom_query(model)
        return FakeQuery()


def test_update_ingredient_logs_stock_delta(monkeypatch):
    ingredient = SimpleNamespace(id=uuid.uuid4(), stock_qty=10.0)
    updated = SimpleNamespace(id=ingredient.id, stock_qty=15.0)
    fake_db = FakeDB()

    monkeypatch.setattr(inventory_services.IngredientRepository, "get_by_id", staticmethod(lambda db, ingredient_id: ingredient))
    monkeypatch.setattr(inventory_services.IngredientRepository, "update", staticmethod(lambda db, db_obj, update_data: updated))

    payload = inventory_services.IngredientUpdate(stock_qty=15.0)

    result = inventory_services.update_ingredient(fake_db, ingredient.id, payload)

    assert result.stock_qty == 15.0
    assert fake_db.committed == 1
    assert any(getattr(item, "reason", "") == "Manual stock adjustment via ingredient update" for item in fake_db.added)


def test_get_bom_missing_menu_item_raises(monkeypatch):
    monkeypatch.setattr(inventory_services.MenuItemRepository, "get_menu_item_by_id", staticmethod(lambda db, menu_item_id: None))

    with pytest.raises(inventory_services.HTTPException) as exc_info:
        inventory_services.get_bom(FakeDB(), uuid.uuid4())

    assert exc_info.value.status_code == 404


def test_set_bom_validates_and_replaces(monkeypatch):
    menu_item_id = uuid.uuid4()
    ingredient_id = uuid.uuid4()
    variant_id = uuid.uuid4()
    menu_item = SimpleNamespace(id=menu_item_id, variants=[SimpleNamespace(id=variant_id)])
    fake_db = FakeDB()

    monkeypatch.setattr(inventory_services.MenuItemRepository, "get_menu_item_by_id", staticmethod(lambda db, item_id: menu_item))
    monkeypatch.setattr(inventory_services.BOMRepository, "delete_bom_for_menu_item", staticmethod(lambda db, item_id: None))
    monkeypatch.setattr(inventory_services.BOMRepository, "create_bom_items", staticmethod(lambda db, items: items))
    monkeypatch.setattr(inventory_services.BOMRepository, "get_bom_by_menu_item", staticmethod(lambda db, item_id: []))

    class IngredientIDQuery:
        def filter(self, *args, **kwargs):
            return self

        def all(self):
            return [(ingredient_id,)]

    def query_side_effect(model):
        if model == inventory_services.Ingredient.id:
            return IngredientIDQuery()
        return FakeQuery()

    fake_db.custom_query = query_side_effect

    payload = inventory_services.MenuBOMUpdate(
        bom_items=[
            BOMItemCreate(
                ingredient_id=ingredient_id,
                variant_id=variant_id,
                qty_required=2,
            )
        ]
    )

    result = inventory_services.set_bom(fake_db, menu_item_id, payload)

    assert result == []
