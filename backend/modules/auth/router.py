from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from core.database import get_db
from .schemas import LoginResponse, LoginRequest, RefreshTokenResponse, RefreshTokenRequest
from . import services
from core.denpendencies.role_access import require_role
from core.enums import UserRole
from utils.response_wrapper import ResponseWrapper

router = APIRouter(prefix="/auth", tags=["Auth"])

# RBAC
IS_ADMIN = UserRole.ADMIN.value

"""LOGIN ENDPOINTS"""
@router.post("/login", response_model=ResponseWrapper[LoginResponse],
                        response_model_exclude_none=True)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    """
    Authenticate user and return a JWT access and refresh tokens.
    """   
    result = await services.login_user(db, request)
    return ResponseWrapper.success_response(result)


"""REFRESH TOKEN ENDPOINT"""
@router.post("/refresh-token", response_model=ResponseWrapper[RefreshTokenResponse],
                                response_model_exclude_none=True)
async def refresh_token(request: RefreshTokenRequest, db: Session = Depends(get_db)):
    """
    Refresh JWT access token using a valid refresh token.
    """
    result = await services.refresh_access_token(db, request)
    return ResponseWrapper.success_response(result)

from pydantic import EmailStr
from typing import List
from .schemas import LoginResponse, LoginRequest, RefreshTokenResponse, RefreshTokenRequest, UserCreate, UserUpdate, UserRead

@router.get("/users", response_model=ResponseWrapper[List[UserRead]], response_model_exclude_none=True)
async def get_users_list(skip: int = 0, limit: int = 50, db: Session = Depends(get_db), current_user: dict = require_role([IS_ADMIN])):
    users = await services.get_users(db, skip, limit)
    return ResponseWrapper.success_response(users)

@router.post("/users", response_model=ResponseWrapper[dict], response_model_exclude_none=True)
async def create_new_user(user: UserCreate, db: Session = Depends(get_db), current_user: dict = require_role([IS_ADMIN])):
    res = await services.create_user(db, user)
    return ResponseWrapper.success_response(res)

@router.patch("/users/{user_id}", response_model=ResponseWrapper[dict], response_model_exclude_none=True)
async def update_existing_user(user_id: str, user: UserUpdate, db: Session = Depends(get_db), current_user: dict = require_role([IS_ADMIN])):
    res = await services.update_user(db, user_id, user)
    return ResponseWrapper.success_response(res)

@router.delete("/users/{user_id}", response_model=ResponseWrapper[dict], response_model_exclude_none=True)
async def remove_user(user_id: str, db: Session = Depends(get_db), current_user: dict = require_role([IS_ADMIN])):
    res = await services.delete_user(db, user_id)
    return ResponseWrapper.success_response(res)