from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from core.database import get_db
from .schemas import LoginResponse, LoginRequest
from . import services

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/login", response_model=LoginResponse)
async def login(login_request: LoginRequest, db: Session = Depends(get_db)):
    """
    Authenticate user and return a JWT access and refresh tokens.
    """
    try:
        return await services.login_user(db, login_request)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )

@router.get("/users")
async def get_users():
    return {"message": "This is a protected route to get users. Implement user retrieval logic here."}