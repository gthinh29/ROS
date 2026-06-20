from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from core.database import get_db
from core.denpendencies.role_access import require_role
from core.enums import UserRole
from modules.analytics import schemas, services

router = APIRouter(prefix="/analytics", tags=["analytics"])

IS_ADMIN = [UserRole.ADMIN.value]

@router.get("/daily-overview", response_model=schemas.DailyOverview)
def get_daily_overview(
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_ADMIN)
):
    return services.get_daily_overview(db)

@router.get("/revenue-chart", response_model=List[schemas.RevenuePoint])
def get_revenue_chart(
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_ADMIN)
):
    return services.get_revenue_chart(db)

@router.get("/top-items", response_model=List[schemas.TopItem])
def get_top_items(
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_ADMIN)
):
    return services.get_top_items(db)
