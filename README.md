# 🍜 Restaurant Ordering System — Hệ thống Đặt món Nhà hàng

> Restaurant Ordering System – hệ thống đặt món nhà hàng

Hệ thống số hóa toàn bộ quy trình vận hành nhà hàng: từ khách quét QR gọi món, điều phối bếp thời gian thực, đến thanh toán và báo cáo kinh doanh.

---

## 📦 Cấu trúc Repository

```
restaurant-system/
├── backend/          # Python 3.12 + FastAPI  (TV1, TV2)
├── customer-app/     # Flutter — App khách hàng  (TV1)
├── staff-app/        # Flutter — App nhân viên phục vụ  (TV3)
├── kds-web/          # TypeScript/React — Kitchen Display System  (TV3)
├── pos-web/          # TypeScript/React — Web POS thu ngân  (TV4)
├── admin-web/        # TypeScript/React — Admin Dashboard  (TV1)
├── docs/             # ERD, API spec, flow diagrams
└── docker-compose.yml
```

---

## 👥 Phân công nhóm

| Thành viên | Phụ trách |
|---|---|
| **TV1 (Lead)** | Backend core: Order/KDS/Billing/Table · Customer App · Admin Web · DevOps · Code Review |
| **TV2** | Backend: Auth/Menu/Inventory/BOM/Reports |
| **TV3** | Staff Flutter App · KDS Web |
| **TV4** | Web POS |

---

## ⚙️ Tech Stack

| Layer | Công nghệ |
|---|---|
| Backend | Python 3.12, FastAPI, SQLAlchemy 2.0, Alembic, Pydantic v2 |
| Database | PostgreSQL 16 |
| Real-time | FastAPI WebSockets (asyncio) |
| Mobile | Flutter 3.x, Riverpod, Dio |
| Web Frontend | TypeScript, React 18, Vite, Tailwind CSS, shadcn/ui |
| Auth | JWT (access + refresh token), bcrypt, RBAC |
| Container | Docker, Docker Compose, Nginx |

---

## 🚀 Chạy dự án (Development)

### Yêu cầu

- Docker & Docker Compose
- Python 3.12+
- Flutter 3.x
- Node.js 20+

### 1. Clone repo

```bash
git clone https://github.com/<org>/restaurant-system.git
cd restaurant-system
```

### 2. Cấu hình environment

```bash
cp backend/.env.example backend/.env
```

> **Lưu ý:** Không cần chỉnh `DATABASE_URL` khi chạy bằng Docker Compose —
> host kết nối DB được tự động override trong `docker-compose.yml`.
> Chỉ sửa `SECRET_KEY` nếu deploy production.

### 3. Khởi động backend + database

```bash
docker-compose up -d postgres
cd backend
pip install -r requirements.txt
alembic upgrade head          # chạy migration
python seed.py                # tạo dữ liệu mẫu
uvicorn main:app --reload     # chạy API tại http://localhost:8000
```

### 4. Chạy từng frontend

```bash
# Customer App / Staff App (Flutter)
cd customer-app   # hoặc staff-app
flutter pub get
flutter run

# KDS Web / POS Web / Admin Web (React)
cd kds-web        # hoặc pos-web / admin-web
npm install
npm run dev
```

### 5. Chạy toàn bộ bằng Docker Compose

```bash
# Lần đầu (hoặc khi có thay đổi code)
docker-compose up --build

# Những lần sau
docker-compose up
```

> Services khởi động theo thứ tự: **postgres** → **api** → **nginx**  
> (healthcheck tự động, không cần chờ thủ công)

| Service | URL |
|---|---|
| Backend API (qua Nginx) | http://localhost |
| API Docs (Swagger) | http://localhost/docs |
| Backend API (trực tiếp) | http://localhost:8000 |
| PostgreSQL | localhost:5432 |

---

## 🗂️ Tài khoản demo (sau khi chạy seed.py)

| Role | Email | Password |
|---|---|---|
| Admin | admin@demo.com | demo1234 |
| Thu ngân | cashier@demo.com | demo1234 |
| Phục vụ | waiter@demo.com | demo1234 |
| Bếp | kitchen@demo.com | demo1234 |

---

## 🔑 Biến môi trường (backend/.env.example)

```env
DATABASE_URL=postgresql://user:password@localhost:5432/restaurant_db
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
```

---

## 🌿 Quy trình Git

| Nhánh | Mục đích |
|---|---|
| `main` | Production — chỉ TV1 merge vào |
| `develop` | Integration — tất cả feature merge vào đây |
| `feat/<tvX>/<tên>` | Nhánh feature của từng người |

**Quy trình hàng ngày:**

```bash
# 1. Sync develop
git checkout develop && git pull origin develop

# 2. Tạo nhánh mới
git checkout -b feat/tvX/tên-task

# 3. Code → commit thường xuyên
git add <file>
git commit -m "feat(scope): mô tả ngắn gọn"

# 4. Rebase trước khi push
git rebase origin/develop
git push origin feat/tvX/tên-task

# 5. Tạo Pull Request → Reviewer: TV1
```

> Xem chi tiết trong file `github-guide.docx`

---

## 🧪 Chạy Tests

```bash
# Backend unit tests
cd backend
pytest -v

# Backend lint
ruff check .

# Frontend lint
cd pos-web && npm run lint
cd kds-web && npm run lint
```

---

## 📡 WebSocket Endpoints

| Endpoint | Mô tả |
|---|---|
| `ws://localhost:8000/ws/kds/{zone}` | KDS nhận thẻ món theo zone (kitchen / bar) |
| `ws://localhost:8000/ws/staff/{user_id}` | Staff nhận push notification khi món READY |
| `ws://localhost:8000/ws/tables` | POS nhận cập nhật trạng thái bàn realtime |

---

## 📋 Các luồng nghiệp vụ chính

```
Luồng 1 — Dine-in (QR)
  Khách quét QR bàn → chọn món → gửi bếp
  → KDS nhận < 1s → Bếp PREPARING → READY
  → Staff nhận notification → Bưng ra → SERVED
  → Trừ kho tự động → Khách yêu cầu TT → POS đóng phiên

Luồng 2 — Split Bill
  POS thấy bàn "Chờ TT" → chọn Split Evenly / Item-based
  → Tạo sub-bills → Từng người quét QR / tiền mặt
  → Tất cả PAID → bàn EMPTY → lưu doanh thu

Luồng 3 — Takeaway
  Khách đặt App → TT online (VNPay/MoMo)
  → POS xác nhận → KDS nấu → Giao Shipper → COMPLETED
```

---

## 📁 Tài liệu tham khảo

- `docs/erd.png` — Sơ đồ cơ sở dữ liệu
- `docs/api-spec.md` — Danh sách API endpoints
- `backend/.env.example` — Template biến môi trường
- `github-guide.docx` — Quy trình làm việc Git cho cả nhóm
- `http://localhost:8000/docs` — Swagger UI (khi chạy local)
