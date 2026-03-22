"""Services for auth (login/refresh) and user management."""

from .schemas import (
    LoginRequest, LoginResponse,
    RefreshTokenResponse, RefreshTokenRequest,
    UserCreate, UserUpdate,
)
from .models import User
from .repository import UserRepository
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from pwdlib import PasswordHash
from jose import jwt
from datetime import datetime, timedelta, timezone
from core.config import settings

pwd_context = PasswordHash.recommended()


# ── Token helpers ─────────────────────────────────────────────────────────────

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


# ── Auth services ─────────────────────────────────────────────────────────────

async def login_user(db: Session, request: LoginRequest) -> LoginResponse:
    user = db.query(User).filter(User.email == request.email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )

    if not pwd_context.verify(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )

    access_token = await create_access_token(
        data={"sub": str(user.id), "role": user.role.value}
    )
    refresh_token = await create_refresh_token(
        data={"sub": str(user.id), "role": user.role.value}
    )

    return LoginResponse(access_token=access_token, refresh_token=refresh_token)


async def refresh_access_token(db: Session, request: RefreshTokenRequest) -> RefreshTokenResponse:
    try:
        payload = jwt.decode(request.refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = payload.get("sub")
        role = payload.get("role")
        if user_id is None or role is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

        new_access_token = await create_access_token(data={"sub": str(user_id), "role": role})
        new_refresh_token = await create_refresh_token(data={"sub": str(user_id), "role": role})

        return RefreshTokenResponse(access_token=new_access_token, refresh_token=new_refresh_token)

    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token has expired")
    except jwt.JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")


# ── User CRUD services ────────────────────────────────────────────────────────

async def create_user(db: Session, user: UserCreate):
    db_user = UserRepository.get_user_by_email(db, user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    if user.phone:
        db_phone = UserRepository.get_user_by_phone(db, user.phone)
        if db_phone:
            raise HTTPException(status_code=400, detail="Phone already registered")

    hashed_password = pwd_context.hash(user.password)
    user_data = {
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "role": user.role,
        "is_active": user.is_active,
        "password_hash": hashed_password,
    }
    UserRepository.create_user(db, user_data)
    return {"message": "User created successfully"}


async def get_users(db: Session, skip: int = 0, limit: int = 50):
    return UserRepository.get_users(db, skip, limit)


async def get_user_by_id(db: Session, user_id: str):
    user = UserRepository.get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


async def update_user(db: Session, user_id: str, user_update: UserUpdate):
    db_user = UserRepository.get_user_by_id(db, user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    update_data = user_update.model_dump(exclude_unset=True)

    if "email" in update_data and update_data["email"] != db_user.email:
        if UserRepository.get_user_by_email(db, update_data["email"]):
            raise HTTPException(status_code=400, detail="Email already registered")

    if "phone" in update_data and update_data["phone"] and update_data["phone"] != db_user.phone:
        if UserRepository.get_user_by_phone(db, update_data["phone"]):
            raise HTTPException(status_code=400, detail="Phone already registered")

    if "password" in update_data:
        update_data["password_hash"] = pwd_context.hash(update_data.pop("password"))

    UserRepository.update_user(db, db_user, update_data)
    return {"message": "User updated successfully"}


async def delete_user(db: Session, user_id: str):
    db_user = UserRepository.get_user_by_id(db, user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    UserRepository.delete_user(db, db_user)
    return {"message": "User deleted successfully"}