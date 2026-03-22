from core.database import SessionLocal
from modules.menu.models import MenuItem
from modules.tables.models import Restaurant, Table
from modules.auth.models import User

def main():
    db = SessionLocal()
    try:
        # Get Restaurant
        restaurant = db.query(Restaurant).first()
        if restaurant:
            print("\n===== MÃ NHÀ HÀNG (Restaurant) =====")
            print(f"{restaurant.name:<15} | ID: {restaurant.id}")

        # Get Users
        print("\n===== MÃ NHÂN VIÊN (Users) =========")
        users = db.query(User).limit(4).all()
        for u in users:
            print(f"[{u.role.value}] {u.name:<15} | ID: {u.id}")

        # Get Tables
        print("\n===== MÃ BÀN (Tables) ==============")
        tables = db.query(Table).limit(3).all()
        for t in tables:
            print(f"Bàn {t.number:<11} | ID: {t.id}")

        # Get Menu Items
        print("\n===== MÃ MÓN DÙNG THỬ (Menu) =======")
        items = db.query(MenuItem).limit(5).all()
        for item in items:
            print(f"{item.name:<15} | ID: {item.id}")
            print(f"    Zone: {item.kds_zone}")
            
    finally:
        db.close()

if __name__ == "__main__":
    main()
