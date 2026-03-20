"""Services for user management"""
from .schemas import UserCreate, UserUpdate
from .models import User
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from fastapi.responses import JSONResponse
from pwdlib import PasswordHash

pwd_context = PasswordHash.recommended()

# Create a new user
async def create_user(db: Session, user: UserCreate):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    if user.phone:
        db_phone = db.query(User).filter(User.phone == user.phone).first()
        if db_phone:
            raise HTTPException(status_code=400, detail="Phone already registered")
            
    hashed_password = pwd_context.hash(user.password)
    
    db_user = User(
        name=user.name,
        email=user.email,
        phone=user.phone,
        role=user.role,
        is_active=user.is_active,
        password_hash=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return {
        "message": "User created successfully"
    }

# Get all users with pagination
async def get_users(db: Session, skip: int = 0, limit: int = 50):
    return db.query(User).offset(skip).limit(limit).all()

# Get user by ID
async def get_user_by_id(db: Session, user_id: str):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return user

# Update user by ID
async def update_user(db: Session, user_id: str, user_update: UserUpdate):
    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
        
    update_data = user_update.model_dump(exclude_unset=True)
    
    if "email" in update_data and update_data["email"] != db_user.email:
        existing_email = db.query(User).filter(User.email == update_data["email"]).first()
        if existing_email:
            raise HTTPException(status_code=400, detail="Email already registered")
            
    if "phone" in update_data and update_data["phone"] and update_data["phone"] != db_user.phone:
        existing_phone = db.query(User).filter(User.phone == update_data["phone"]).first()
        if existing_phone:
            raise HTTPException(status_code=400, detail="Phone already registered")
            
    if "password" in update_data:
        hashed_password = pwd_context.hash(update_data["password"])
        update_data["password_hash"] = hashed_password
        del update_data["password"]

    for key, value in update_data.items():
        setattr(db_user, key, value)
        
    db.commit()
    db.refresh(db_user)
    
    return {
        "message": "User updated successfully"
    }

# Delete user by ID
async def delete_user(db: Session, user_id: str):
    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(db_user)
    db.commit()
    
    return {
        "message": "User deleted successfully"
    }
