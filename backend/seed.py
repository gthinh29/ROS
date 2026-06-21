



from decimal import Decimal



from pwdlib import PasswordHash



from core.config import settings  

from core.database import SessionLocal

from core.enums import TableStatus, UserRole

from modules.auth.models import User

from modules.inventory.models import BOMItem, Ingredient

from modules.menu.models import Category, MenuItem, Modifier, Variant

from modules.tables.models import Restaurant, Table





hasher = PasswordHash.recommended()



DEFAULT_PASSWORD = "123456"





def seed():

    db = SessionLocal()

    try:

        

        from modules.auth.models import User as _User

        existing = db.query(_User).first()

        if existing:

            print("⚠️  Seed đã chạy trước đó (users tồn tại). Bỏ qua để tránh duplicate.")

            print("   Nếu muốn seed lại: chạy 'alembic downgrade base && alembic upgrade head' trước.")

            return



        

        restaurant = Restaurant(

            name="Demo Restaurant",

            settings={

                "vat_percent": 8,

                "service_fee_percent": 5,

                "logo_url": "",

            },

        )

        db.add(restaurant)

        db.flush()

        print(f"✓ Restaurant: {restaurant.name} ({restaurant.id})")



        

        pw_hash = hasher.hash(DEFAULT_PASSWORD)

        users_data = [

            {"name": "Admin", "email": "admin@demo.com", "role": UserRole.ADMIN},

            {"name": "Thu Ngân", "email": "cashier@demo.com", "role": UserRole.CASHIER},

            {"name": "Phục Vụ", "email": "waiter@demo.com", "role": UserRole.WAITER},

            {"name": "Bếp Trưởng", "email": "kitchen@demo.com", "role": UserRole.KITCHEN},

        ]

        for u in users_data:

            user = User(

                name=u["name"],

                email=u["email"],

                password_hash=pw_hash,

                role=u["role"],

            )

            db.add(user)

        db.flush()

        print(f"✓ Users: {len(users_data)} tài khoản (password: {DEFAULT_PASSWORD})")



        

        cat_food = Category(

            restaurant_id=restaurant.id, name="Đồ ăn", sort_order=1

        )

        cat_drink = Category(

            restaurant_id=restaurant.id, name="Đồ uống", sort_order=2

        )

        cat_dessert = Category(

            restaurant_id=restaurant.id, name="Tráng miệng", sort_order=3

        )

        db.add_all([cat_food, cat_drink, cat_dessert])

        db.flush()

        print("✓ Categories: Đồ ăn, Đồ uống, Tráng miệng")



        

        

        pho = MenuItem(

            category_id=cat_food.id,

            name="Phở Bò",

            base_price=Decimal("55000"),

            kds_zone="kitchen",

        )

        com_tam = MenuItem(

            category_id=cat_food.id,

            name="Cơm Tấm Sườn",

            base_price=Decimal("45000"),

            kds_zone="kitchen",

        )

        bun_cha = MenuItem(

            category_id=cat_food.id,

            name="Bún Chả Hà Nội",

            base_price=Decimal("50000"),

            kds_zone="kitchen",

        )



        

        cf_sua = MenuItem(

            category_id=cat_drink.id,

            name="Cà Phê Sữa",

            base_price=Decimal("25000"),

            kds_zone="bar",

        )

        tra_dao = MenuItem(

            category_id=cat_drink.id,

            name="Trà Đào Cam Sả",

            base_price=Decimal("35000"),

            kds_zone="bar",

        )

        nuoc_ep = MenuItem(

            category_id=cat_drink.id,

            name="Nước Ép Cam",

            base_price=Decimal("30000"),

            kds_zone="bar",

        )



        

        che = MenuItem(

            category_id=cat_dessert.id,

            name="Chè Thái",

            base_price=Decimal("20000"),

            kds_zone="kitchen",

        )

        banh_flan = MenuItem(

            category_id=cat_dessert.id,

            name="Bánh Flan",

            base_price=Decimal("18000"),

            kds_zone="kitchen",

        )



        all_items = [pho, com_tam, bun_cha, cf_sua, tra_dao, nuoc_ep, che, banh_flan]

        db.add_all(all_items)

        db.flush()

        print(f"✓ Menu Items: {len(all_items)} món")



        

        v_s = Variant(menu_item_id=cf_sua.id, name="Size S", extra_price=Decimal("0"))

        v_m = Variant(menu_item_id=cf_sua.id, name="Size M", extra_price=Decimal("5000"))

        v_l = Variant(menu_item_id=cf_sua.id, name="Size L", extra_price=Decimal("10000"))

        db.add_all([v_s, v_m, v_l])



        

        v_tra_m = Variant(menu_item_id=tra_dao.id, name="Size M", extra_price=Decimal("0"))

        v_tra_l = Variant(menu_item_id=tra_dao.id, name="Size L", extra_price=Decimal("8000"))

        db.add_all([v_tra_m, v_tra_l])

        db.flush()

        print("✓ Variants: 5 biến thể (Cà Phê S/M/L, Trà Đào M/L)")



        

        mod_trung = Modifier(menu_item_id=pho.id, name="Thêm trứng", extra_price=Decimal("5000"))

        mod_hanh = Modifier(menu_item_id=pho.id, name="Không hành", extra_price=Decimal("0"))

        mod_suong = Modifier(

            menu_item_id=cf_sua.id, name="Thêm sương sáo", extra_price=Decimal("8000")

        )

        mod_it_duong = Modifier(

            menu_item_id=cf_sua.id, name="Ít đường", extra_price=Decimal("0")

        )

        db.add_all([mod_trung, mod_hanh, mod_suong, mod_it_duong])

        db.flush()

        print("✓ Modifiers: 4 tùy chọn")



        

        import uuid as _uuid

        tables = []

        for i in range(1, 6):

            tbl_id = _uuid.uuid4()

            tables.append(

                Table(

                    id=tbl_id,

                    restaurant_id=restaurant.id,

                    zone="Zone A",

                    number=i,

                    status=TableStatus.EMPTY,

                )

            )

        for i in range(6, 11):

            tbl_id = _uuid.uuid4()

            tables.append(

                Table(

                    id=tbl_id,

                    restaurant_id=restaurant.id,

                    zone="Zone B",

                    number=i,

                    status=TableStatus.EMPTY,

                )

            )

        db.add_all(tables)

        db.flush()

        print(f"✓ Tables: {len(tables)} bàn (Zone A: 1-5, Zone B: 6-10)")



        

        ing_cf = Ingredient(

            name="Cà phê bột", unit="g", stock_qty=Decimal("5000"), alert_threshold=Decimal("500")

        )

        ing_sua = Ingredient(

            name="Sữa đặc", unit="ml", stock_qty=Decimal("10000"), alert_threshold=Decimal("1000")

        )

        ing_duong = Ingredient(

            name="Đường", unit="g", stock_qty=Decimal("8000"), alert_threshold=Decimal("500")

        )

        ing_bot_mi = Ingredient(

            name="Bột mì", unit="g", stock_qty=Decimal("10000"), alert_threshold=Decimal("1000")

        )

        ing_thit_bo = Ingredient(

            name="Thịt bò", unit="g", stock_qty=Decimal("5000"), alert_threshold=Decimal("500")

        )

        ing_pho = Ingredient(

            name="Bánh phở", unit="g", stock_qty=Decimal("8000"), alert_threshold=Decimal("800")

        )



        all_ings = [ing_cf, ing_sua, ing_duong, ing_bot_mi, ing_thit_bo, ing_pho]

        db.add_all(all_ings)

        db.flush()

        print(f"✓ Ingredients: {len(all_ings)} nguyên liệu")



        

        bom_entries = [

            

            BOMItem(menu_item_id=cf_sua.id, variant_id=v_s.id, ingredient_id=ing_cf.id, qty_required=Decimal("15")),

            BOMItem(menu_item_id=cf_sua.id, variant_id=v_s.id, ingredient_id=ing_sua.id, qty_required=Decimal("20")),

            BOMItem(menu_item_id=cf_sua.id, variant_id=v_s.id, ingredient_id=ing_duong.id, qty_required=Decimal("10")),

            

            BOMItem(menu_item_id=cf_sua.id, variant_id=v_m.id, ingredient_id=ing_cf.id, qty_required=Decimal("20")),

            BOMItem(menu_item_id=cf_sua.id, variant_id=v_m.id, ingredient_id=ing_sua.id, qty_required=Decimal("30")),

            BOMItem(menu_item_id=cf_sua.id, variant_id=v_m.id, ingredient_id=ing_duong.id, qty_required=Decimal("12")),

            

            BOMItem(menu_item_id=pho.id, variant_id=None, ingredient_id=ing_thit_bo.id, qty_required=Decimal("150")),

            BOMItem(menu_item_id=pho.id, variant_id=None, ingredient_id=ing_pho.id, qty_required=Decimal("200")),

        ]

        db.add_all(bom_entries)

        db.flush()

        print(f"✓ BOM: {len(bom_entries)} công thức")



        

        db.commit()

        print("\n🎉 Seed hoàn tất! Tất cả dữ liệu đã được lưu vào DB.")



    except Exception as e:

        db.rollback()

        print(f"\n❌ Lỗi khi seed: {e}")

        raise

    finally:

        db.close()





if __name__ == "__main__":

    seed()

