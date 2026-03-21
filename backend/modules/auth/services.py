"""Services for user authentication"""
from .schemas import LoginRequest, LoginResponse, RefreshTokenResponse, RefreshTokenRequest
from modules.user.models import User
from modules.user.repository import UserRepository
from modules.auth.models import RefreshToken
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from pwdlib import PasswordHash
from jose import jwt
from datetime import datetime, timedelta, timezone
from core.config import settings



pwd_context = PasswordHash.recommended()

# Helper functions for authentication and token management
async def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update(
        {"exp": int(expire.timestamp())}
        )
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

async def create_refresh_token(data: dict):
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update(
        {"exp": int(expire.timestamp())}
        )
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

# Helper function to save refresh token in database
async def save_refresh_token(db: Session, user_id: str, refresh_token: str):
    expires_at = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    refresh_token_hash = pwd_context.hash(refresh_token)
    db_token = RefreshToken(user_id=user_id, token=refresh_token_hash, expires_at=expires_at)
    db.add(db_token)
    db.commit()
    db.refresh(db_token)
    return db_token

# Login service
async def login_user(db: Session, request: LoginRequest) -> LoginResponse:
    # Find user by email
    user = UserRepository.get_user_by_email(db, request.email)
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
    
    # Save refresh token in database
    await save_refresh_token(db, user.id, refresh_token)
    
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
        
            
        # Verify that the refresh token is valid and not revoked
        db_tokens = db.query(RefreshToken).filter(RefreshToken.user_id == user_id).all()
        valid_token = None
        for db_token in db_tokens:
            if pwd_context.verify(request.refresh_token, db_token.token):
                valid_token = db_token
                break
                
        if not valid_token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, 
                detail="Invalid refresh token")
                
        if valid_token.is_revoked:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, 
                detail="Refresh token has been revoked")
                
        now = datetime.now(timezone.utc)
        exp = valid_token.expires_at
        from datetime import datetime as dt
        if isinstance(exp, dt):
            exp = exp if exp.tzinfo else exp.replace(tzinfo=timezone.utc)
            if exp < now:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED, 
                    detail="Refresh token has expired")
        elif isinstance(exp, str):
            try:
                exp_dt = dt.fromisoformat(exp)
                exp_dt = exp_dt if exp_dt.tzinfo else exp_dt.replace(tzinfo=timezone.utc)
                if exp_dt < now:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED, 
                        detail="Refresh token has expired")
            except ValueError:
                pass
                
        # Revoke old token
        valid_token.is_revoked = True
        db.commit()
        
        # Generate new access token
        new_access_token = await create_access_token(data={"sub": str(user_id), "role": role})
        new_refresh_token = await create_refresh_token(data={"sub": str(user_id), "role": role})
        
        # Save new refresh token in database
        await save_refresh_token(db, user_id, new_refresh_token)
        
        return RefreshTokenResponse(access_token=new_access_token, refresh_token=new_refresh_token)
    
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token has expired")
    except jwt.JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")