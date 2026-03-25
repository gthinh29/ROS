from fastapi import FastAPI, HTTPException

from core.config import settings
from modules.auth.router import router as auth_router
from modules.auth.users import router as users_router
from modules.billing.router import router as billing_router
from modules.inventory.router import router as inventory_router
from modules.kds.router import router as kds_router
from modules.menu.router import router as menu_router
from modules.orders.router import router as orders_router
from modules.reservations.router import router as reservations_router
from modules.tables.router import router as tables_router

# Middlewares
from middlewares.auth import JWTAuthenticationMiddleware
# Exception handlers
from utils.exception_handler import http_exception_handler, generic_exception_handler

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── Register module routers ───────────────────────────────────────────
app.include_router(auth_router)
app.include_router(users_router)
app.include_router(menu_router)
app.include_router(inventory_router)
app.include_router(tables_router)
app.include_router(orders_router)
app.include_router(kds_router)
app.include_router(billing_router)
app.include_router(reservations_router)

# ── Register middlewares ───────────────────────────────────────────
app.add_middleware(JWTAuthenticationMiddleware)

# ── Register handlers ─────────────────────────────────────────────────
app.add_exception_handler(HTTPException, http_exception_handler)
app.add_exception_handler(Exception, generic_exception_handler)

@app.get("/health", tags=["System"])
def health_check():
    """Liveness probe — used by Docker Compose healthcheck and CI."""
    return {"status": "ok", "version": settings.VERSION}