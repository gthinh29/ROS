from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from core.database import get_db
from .schemas import UserCreate, UserUpdate, UserRead
from . import services
from core.denpendencies.role_access import require_role
from core.enums import UserRole
from utils.response_wrapper import ResponseWrapper

router = APIRouter(prefix="/users", tags=["Users"])

# RBAC
IS_ADMIN = UserRole.ADMIN.value

@router.post("", status_code=201, response_model=ResponseWrapper[dict], response_model_exclude_none=True)
async def create_user(request: UserCreate, 
                      db: Session = Depends(get_db), 
                      current_user: dict = require_role(IS_ADMIN)):
    result = await services.create_user(db, request)
    return ResponseWrapper.success_response(result)

@router.get("", response_model=ResponseWrapper[list[UserRead]], response_model_exclude_none=True)
async def get_users(skip: int = 0, limit: int = 50,
                    db: Session = Depends(get_db), 
                    current_user: dict = require_role(IS_ADMIN)):
    result = await services.get_users(db, skip=skip, limit=limit)
    return ResponseWrapper.success_response(result)

@router.get("/{user_id}", response_model=ResponseWrapper[UserRead], response_model_exclude_none=True)
async def get_user(user_id: str, 
                   db: Session = Depends(get_db), 
                   current_user: dict = require_role(IS_ADMIN)):
    result = await services.get_user_by_id(db, user_id)
    return ResponseWrapper.success_response(result)

@router.put("/{user_id}", response_model=ResponseWrapper[dict], response_model_exclude_none=True)
async def update_user(user_id: str, request: UserUpdate, 
                      db: Session = Depends(get_db), 
                      current_user: dict = require_role(IS_ADMIN)):
    result = await services.update_user(db, user_id, request)
    return ResponseWrapper.success_response(result)

@router.delete("/{user_id}", response_model=ResponseWrapper[dict], response_model_exclude_none=True)
async def delete_user(user_id: str, 
                      db: Session = Depends(get_db), 
                      current_user: dict = require_role(IS_ADMIN)):
    result = await services.delete_user(db, user_id)
    return ResponseWrapper.success_response(result)
