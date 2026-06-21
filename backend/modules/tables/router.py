import uuid

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status

from sqlalchemy.orm import Session



from core.database import get_db

from core.denpendencies.role_access import require_role

from core.enums import UserRole

from modules.tables import schemas, services



router = APIRouter(prefix="/tables", tags=["Tables"])



IS_ADMIN = UserRole.ADMIN.value

IS_STAFF = [UserRole.ADMIN.value, UserRole.CASHIER.value, UserRole.WAITER.value]



@router.get("", response_model=List[schemas.TableRead])

async def list_tables(

    db: Session = Depends(get_db),

    current_user: dict = require_role(IS_STAFF),

):

    

    return services.get_tables(db)



import datetime

from fastapi import Query



@router.get("/available", response_model=List[schemas.TableRead])

async def list_available_tables(

    date: datetime.date = Query(..., description="Target date for reservation"),

    time: datetime.time = Query(..., description="Target time for reservation"),

    db: Session = Depends(get_db),

):

    

    return services.get_available_tables(db, date, time)



@router.post("", response_model=schemas.TableRead, status_code=status.HTTP_201_CREATED)

async def create_table(

    table_in: schemas.TableCreate,

    db: Session = Depends(get_db),

    current_user: dict = require_role(IS_ADMIN),

):

    

    return services.create_table(db, table_in)



@router.patch("/{table_id}", response_model=schemas.TableRead)

async def update_table(

    table_id: uuid.UUID,

    data: schemas.TableUpdate,

    db: Session = Depends(get_db),

    current_user: dict = require_role(IS_ADMIN),

):

    

    return services.update_table(db, table_id, data)

