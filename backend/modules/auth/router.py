from fastapi import APIRouter, Depends, HTTPException, status
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


@router.get("/users")
async def get_users(user=require_role(IS_ADMIN),
                    response_model_exclude_none=True):
    return ResponseWrapper.success_response({"message": f"Hello {user['role']}, you are allowed to see users."})