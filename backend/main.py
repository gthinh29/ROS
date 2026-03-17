from fastapi import FastAPI

from core.config import settings
from modules.auth.router import router as auth_router
from modules.billing.router import router as billing_router
from modules.inventory.router import router as inventory_router
from modules.kds.router import router as kds_router
from modules.menu.router import router as menu_router
from modules.orders.router import router as orders_router
from modules.reports.router import router as reports_router
from modules.tables.router import router as tables_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── Register module routers ───────────────────────────────────────────
app.include_router(auth_router)
app.include_router(menu_router)
app.include_router(inventory_router)
app.include_router(tables_router)
app.include_router(orders_router)
app.include_router(kds_router)
app.include_router(billing_router)
app.include_router(reports_router)


@app.get("/health", tags=["System"])
def health_check():
    """Liveness probe — used by Docker Compose healthcheck and CI."""
    return {"status": "ok", "version": settings.VERSION}
