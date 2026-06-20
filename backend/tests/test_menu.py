import uuid
from types import SimpleNamespace

import pytest

from modules.menu import services as menu_services


class FakeMenuItemRepo:
    def __init__(self, category_exists=True, item_exists=False):
        self.category_exists = category_exists
        self.item_exists = item_exists
        self.created_args = None

    def get_category_by_id(self, db, category_id):
        return SimpleNamespace(id=category_id) if self.category_exists else None

    def get_menu_item_by_name(self, db, category_id, name):
        return SimpleNamespace(id=uuid.uuid4()) if self.item_exists else None

    def create_menu_item(self, db, item_data, variants_data, modifiers_data):
        self.created_args = (item_data, variants_data, modifiers_data)
        return SimpleNamespace(id=uuid.uuid4(), **item_data)

    def get_menu_item_by_id(self, db, menu_item_id):
        return SimpleNamespace(
            id=menu_item_id,
            name="Old Name",
            category_id=uuid.uuid4(),
            variants=[],
            modifiers=[],
            restaurant_id=uuid.uuid4(),
        )


def test_create_menu_item_success(monkeypatch):
    repo = FakeMenuItemRepo(category_exists=True, item_exists=False)
    monkeypatch.setattr(menu_services, "CategoryRepository", repo)
    monkeypatch.setattr(menu_services, "MenuItemRepository", repo)

    payload = menu_services.MenuItemCreate(
        category_id=uuid.uuid4(),
        name="Fried Rice",
        base_price=45000,
        variants=[menu_services.VariantCreate(name="Large", extra_price=5000)],
        modifiers=[menu_services.ModifierCreate(name="Egg", extra_price=3000, is_required=False)],
    )

    result = menu_services.create_menu_item(object(), payload)

    assert result.name == "Fried Rice"
    assert repo.created_args[0]["name"] == "Fried Rice"
    assert repo.created_args[1][0]["name"] == "Large"
    assert repo.created_args[2][0]["name"] == "Egg"


def test_create_menu_item_missing_category_raises(monkeypatch):
    repo = FakeMenuItemRepo(category_exists=False)
    monkeypatch.setattr(menu_services, "CategoryRepository", repo)
    monkeypatch.setattr(menu_services, "MenuItemRepository", repo)

    payload = menu_services.MenuItemCreate(
        category_id=uuid.uuid4(),
        name="Fried Rice",
        base_price=45000,
    )

    with pytest.raises(menu_services.HTTPException) as exc_info:
        menu_services.create_menu_item(object(), payload)

    assert exc_info.value.status_code == 400


def test_update_menu_item_updates_fields(monkeypatch):
    db_obj = SimpleNamespace(
        id=uuid.uuid4(),
        name="Old Name",
        category_id=uuid.uuid4(),
        base_price=40000,
        image_url=None,
        is_available=True,
        kds_zone="kitchen",
        variants=[],
        modifiers=[],
    )

    monkeypatch.setattr(
        menu_services,
        "CategoryRepository",
        SimpleNamespace(
            get_category_by_id=lambda db, category_id: SimpleNamespace(id=category_id),
            get_category_by_name=lambda db, restaurant_id, name: None,
        ),
    )
    monkeypatch.setattr(
        menu_services,
        "MenuItemRepository",
        SimpleNamespace(
            get_menu_item_by_id=lambda db, menu_item_id: db_obj,
            get_menu_item_by_name=lambda db, category_id, name: None,
        ),
    )

    class FakeDB:
        def commit(self):
            pass

        def refresh(self, obj):
            pass

    payload = menu_services.MenuItemUpdate(name="New Name", base_price=55000)
    result = menu_services.update_menu_item(FakeDB(), db_obj.id, payload)

    assert result.name == "New Name"
    assert result.base_price == 55000
