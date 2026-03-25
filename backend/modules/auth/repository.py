from sqlalchemy.orm import Session
from .models import User


class UserRepository:
    @staticmethod
    def get_user_by_email(db: Session, email: str) -> User | None:
        return db.query(User).filter(User.email == email).first()

    @staticmethod
    def get_user_by_phone(db: Session, phone: str) -> User | None:
        return db.query(User).filter(User.phone == phone).first()

    @staticmethod
    def get_user_by_id(db: Session, user_id: str) -> User | None:
        return db.query(User).filter(User.id == user_id).first()

    @staticmethod
    def get_users(db: Session, skip: int = 0, limit: int = 50) -> list[User]:
        return db.query(User).offset(skip).limit(limit).all()

    @staticmethod
    def create_user(db: Session, user_data: dict) -> User:
        db_user = User(**user_data)
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user

    @staticmethod
    def update_user(db: Session, db_user: User, update_data: dict) -> User:
        for key, value in update_data.items():
            setattr(db_user, key, value)
        db.commit()
        db.refresh(db_user)
        return db_user

    @staticmethod
    def delete_user(db: Session, db_user: User) -> None:
        db.delete(db_user)
        db.commit()
