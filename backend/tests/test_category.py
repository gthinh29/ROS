import uuid
from types import SimpleNamespace

import pytest

from modules.menu import services as menu_services


class DummyCategoryRepo:
    def __init__(self):
        self.created_payload = None

    def get_category_by_name(self, db, restaurant_id, name):
        return None

    def create_category(self, db, data):
        self.created_payload = data
        return SimpleNamespace(id=uuid.uuid4(), **data)


def test_create_category_success(monkeypatch):
    repo = DummyCategoryRepo()
    monkeypatch.setattr(menu_services, "CategoryRepository", repo)

    payload = menu_services.CategoryCreate(
        restaurant_id=uuid.uuid4(),
        name="Main Dishes",
    )

    result = menu_services.create_category(object(), payload)

    assert result.name == "Main Dishes"
    assert repo.created_payload["restaurant_id"] == payload.restaurant_id


def test_create_category_duplicate_raises(monkeypatch):
    restaurant_id = uuid.uuid4()

    monkeypatch.setattr(
        menu_services.CategoryRepository,
        "get_category_by_name",
        staticmethod(lambda db, rid, name: object()),
    )

    payload = menu_services.CategoryCreate(
        restaurant_id=restaurant_id,
        name="Main Dishes",
    )

    with pytest.raises(menu_services.HTTPException) as exc_info:
        menu_services.create_category(object(), payload)

    assert exc_info.value.status_code == 400


def test_get_categories_not_found(monkeypatch):
    monkeypatch.setattr(
        menu_services.CategoryRepository,
        "get_categories",
        staticmethod(lambda db, restaurant_id, skip, limit: []),
    )

    with pytest.raises(menu_services.HTTPException) as exc_info:
        menu_services.get_categories(object())

    assert exc_info.value.status_code == 404
