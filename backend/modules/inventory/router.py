from fastapi import APIRouter

router = APIRouter(prefix="/inventory", tags=["Inventory"])

# TODO (TV2): Implement Ingredient CRUD, BOM config, auto-deduct, alerts
