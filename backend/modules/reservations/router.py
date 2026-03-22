from fastapi import APIRouter
from . import models  # Import to register tables with SQLAlchemy Base


router = APIRouter(prefix="/reservations", tags=["Reservations"])

# TODO (TV1/TV2): Implement reservation endpoints
# POST /reservations                 — tạo đặt bàn mới (có thể kèm pre-order)
# POST /reservations/{id}/checkin    — check-in khách, kích hoạt pre-order xuống KDS
# PATCH /reservations/{id}/confirm   — xác nhận reservation PENDING → CONFIRMED
