"""Services for user management"""
from .schemas import UserCreate, UserUpdate
from .models import User
from .repository import UserRepository
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from fastapi.responses import JSONResponse
from pwdlib import PasswordHash

pwd_context = PasswordHash.recommended()

# Create a new user
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
        "password_hash": hashed_password
    }
    UserRepository.create_user(db, user_data)
    
    return {
        "message": "User created successfully"
    }

# Get all users with pagination
async def get_users(db: Session, skip: int = 0, limit: int = 50):
    return UserRepository.get_users(db, skip, limit)

# Get user by ID
async def get_user_by_id(db: Session, user_id: str):
    user = UserRepository.get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return user

# Update user by ID
async def update_user(db: Session, user_id: str, user_update: UserUpdate):
    db_user = UserRepository.get_user_by_id(db, user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
        
    update_data = user_update.model_dump(exclude_unset=True)
    
    if "email" in update_data and update_data["email"] != db_user.email:
        existing_email = UserRepository.get_user_by_email(db, update_data["email"])
        if existing_email:
            raise HTTPException(status_code=400, detail="Email already registered")
            
    if "phone" in update_data and update_data["phone"] and update_data["phone"] != db_user.phone:
        existing_phone = UserRepository.get_user_by_phone(db, update_data["phone"])
        if existing_phone:
            raise HTTPException(status_code=400, detail="Phone already registered")
            
    if "password" in update_data:
        hashed_password = pwd_context.hash(update_data["password"])
        update_data["password_hash"] = hashed_password
        del update_data["password"]

    UserRepository.update_user(db, db_user, update_data)
    
    return {
        "message": "User updated successfully"
    }

# Delete user by ID
async def delete_user(db: Session, user_id: str):
    db_user = UserRepository.get_user_by_id(db, user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    UserRepository.delete_user(db, db_user)
    
    return {
        "message": "User deleted successfully"
    }
