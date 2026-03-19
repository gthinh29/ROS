"""Services for user authentication and management"""
from .schemas import UserBase, LoginRequest, LoginResponse, RefreshTokenResponse, RefreshTokenRequest
from .models import User
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from pwdlib import PasswordHash
from jose import jwt
from datetime import datetime, timedelta, timezone
from core.config import settings

pwd_context = PasswordHash.recommended()

"""AUTH SERVICES"""
async def create_user(db: Session, user: UserBase):
    pass

# Helper functions for authentication and token management
async def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

async def create_refresh_token(data: dict):
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

# Login service
async def login_user(db: Session, request: LoginRequest) -> LoginResponse:
    # Find user by email
    user = db.query(User).filter(User.email == request.email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    # Verify password
    if not pwd_context.verify(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
        
    # Generate token (Currently only have userID in token, can add more claims later if needed)
    access_token = await create_access_token(
        data={"sub": str(user.id), "role": user.role.value}
    )
    
    refresh_token = await create_refresh_token(
        data={"sub": str(user.id), "role": user.role.value}
    )
    
    return LoginResponse(access_token=access_token, refresh_token=refresh_token)


# Refresh token service
async def refresh_access_token(db: Session, request: RefreshTokenRequest) -> RefreshTokenResponse:
    try:
        payload = jwt.decode(request.refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = payload.get("sub")
        role = payload.get("role")
        if user_id is None or role is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, 
                detail="Invalid refresh token")
        
        # Verify and make sure that the user still exists
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, 
                detail="User not found")
        
        # Generate new access token
        new_access_token = await create_access_token(data={"sub": str(user_id), "role": role})
        new_refresh_token = await create_refresh_token(data={"sub": str(user_id), "role": role})
        
        return RefreshTokenResponse(access_token=new_access_token, refresh_token=new_refresh_token)
    
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token has expired")
    except jwt.JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")