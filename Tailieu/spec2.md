# TÀI LIỆU ĐẶC TẢ HỆ THỐNG: RESTAURANT ORDERING SYSTEM

## 1. Tổng quan Sản phẩm Cuối cùng

Hệ thống giải quyết toàn bộ vòng đời đặt món tại nhà hàng, từ lúc khách tiếp cận thực đơn đến khi hoàn thành thanh toán. Mục tiêu là xây dựng một sản phẩm thực tế, có thể triển khai cho doanh nghiệp sử dụng.

### 1.1. Ứng dụng Khách hàng (Customer Web)

Đây là ứng dụng chạy trực tiếp trên trình duyệt điện thoại của khách hàng.

- **Không cần cài đặt, siêu nhẹ:** Được tối ưu bằng HTML renderer với kích thước chỉ khoảng 800KB.
- **Gọi món tại bàn qua QR:** Khách quét QR, hệ thống hiển thị menu, cho phép chọn món, chọn biến thể (size) và modifier (topping).
- **Theo dõi trực tiếp (Tracking):** Sau khi gửi đơn, khách hàng thấy trạng thái món thay đổi theo thời gian thực nhờ kết nối WebSocket.
- **Đặt bàn trước & Pre-order:** Khách có thể đặt bàn và chọn sẵn món từ ở nhà.

### 1.2. Ứng dụng Nội bộ (Internal Web)

Một siêu ứng dụng duy nhất dùng CanvasKit renderer, tự động hiển thị giao diện theo quyền hạn của nhân viên:

- **Bếp / Bar (KDS):** Hiển thị thẻ món ăn realtime (độ trễ < 1 giây) trên máy tính bảng. Hỗ trợ âm thanh thông báo và tự động gộp các món giống nhau (batching) để nấu nhanh hơn.
- **Phục vụ (Waiter):** Xem sơ đồ bàn, gọi món hộ khách, và nhận thông báo (push notification) lên thiết bị ngay khi bếp nấu xong.
- **Thu ngân (POS):** Xem chi tiết hóa đơn, tách bill chia đều cho nhiều người (Split Evenly), và xử lý thanh toán Tiền mặt/VietQR.
- **Quản trị (Admin):** Quản lý menu, định lượng nguyên liệu (BOM), và sơ đồ bàn vật lý.

---

## 2. Công nghệ & Cách triển khai

Hệ thống sử dụng kiến trúc **Modular Monolith** cho Backend và **Monorepo** cho Frontend.

### 2.1. Backend (Python)

- **Tech Stack:** Python 3.12, FastAPI, PostgreSQL 16.
- **Bảo vệ dữ liệu (ACID):** Sử dụng SELECT FOR UPDATE của PostgreSQL để khóa (lock) dữ liệu tồn kho, đảm bảo không bao giờ bị lỗi bán âm kho khi nhiều khách đặt cùng một món.
- **Realtime:** Tích hợp FastAPI WebSockets để đẩy thông báo lập tức về KDS, POS và thiết bị khách hàng.

### 2.2. Frontend (Flutter Web)

Để kịp tiến độ trong thời gian ngắn, hệ thống áp dụng chiến lược tái sử dụng code thông minh:

- **Bộ não dùng chung (Shared Package):** Các model dữ liệu, API Client, WebSocket Client và các hàm tính toán phức tạp được viết chung ở thư mục `frontend/shared/`.
- **Giao diện tách biệt (UI Separation):** Customer Web và Internal Web sẽ phát triển giao diện hoàn toàn độc lập. Việc này giúp hai lập trình viên chạy song song mà không phải chờ đợi nhau (không gây bottleneck), đồng thời đáp ứng được yêu cầu dùng HTML renderer cho web khách hàng và CanvasKit cho web nội bộ.

---

## 3. Luồng nghiệp vụ cốt lõi (Business Flows)

### 3.1. Luồng 1: Gọi món tại bàn (Dine-in QR)

- **Bước 1:** Khách quét mã QR trên bàn, mở Customer Web xem menu, chọn món, chọn topping và bấm gửi.
- **Bước 2:** Backend nhận yêu cầu, kiểm tra kho bằng khóa ACID. Nếu đủ nguyên liệu, tạo đơn và lập tức bắn thẻ món xuống màn hình KDS của bếp qua WebSocket.
- **Bước 3:** Bếp nấu xong, bấm READY. Phục vụ nhận được thông báo, mang đồ ăn ra và xác nhận SERVED.
- **Bước 4:** Hệ thống tự động trừ kho nguyên liệu theo định lượng BOM.
- **Bước 5:** Khách yêu cầu thanh toán, Thu ngân xử lý trên máy POS và đóng bàn.

### 3.2. Luồng 2: Đặt bàn & Pre-order

- **Bước 1:** Khách truy cập web, chọn ngày giờ và chọn pre-order món. Phiếu đặt được lưu lại ở trạng thái PENDING.
- **Bước 2:** Khi khách đến nhà hàng, nhân viên tìm số điện thoại và bấm "Check-in".
- **Bước 3:** Tại giây phút Check-in, hệ thống tự động biến danh sách pre-order thành Đơn hàng (Order) và lập tức bắn xuống KDS để bếp bắt đầu nấu.

---

## 4. Phân công & Lịch trình triển khai (14 Ngày)

Dự án kéo dài 2 tuần (~14 ngày lịch) với nhóm 4 thành viên.

### TV1 (Lead - ~38% Khối lượng)

**Trách nhiệm:** Backend cốt lõi, Docker, luồng giao dịch ACID, và hệ thống KDS WebSocket.

- **Tuần 1:** Cài đặt FastAPI, PostgreSQL schema. Viết luồng đặt đơn khóa tồn kho (SELECT FOR UPDATE). Phân luồng WebSocket KDS và viết logic gộp món (batching).
- **Tuần 2:** Thiết lập Docker Compose cho production, viết API Check-in cho đặt bàn trước. Test tải hệ thống (stress test WS) và hỗ trợ viết tài liệu README để demo.

| Ngày | Danh sách Task Cụ thể của TV1 |
|------|-------------------------------|
| **N1** | Scaffold FastAPI, dựng cấu trúc Modular Monolith, schema PostgreSQL, Alembic migration, Docker Compose, và class WebSocket manager. |
| **N2** | Viết API CRUD cho Bàn + zone, sinh QR code bằng qrcode lib, xử lý trạng thái bàn (EMPTY/OCCUPIED/RESERVED), và broadcast WS sơ đồ bàn. |
| **N3** | Cung cấp API contract + Postman collection cho nhóm. Viết API tạo Order với giao dịch ACID, sử dụng SELECT FOR UPDATE để khóa kiểm tra tồn kho. |
| **N4** | Xây dựng Order state machine (PENDING→PREPARING→READY→SERVED). Viết dispatcher cho KDS WS để phân luồng món ăn (kitchen) và đồ uống (bar). |
| **N5** | Viết logic batching cho KDS (gom món giống nhau). Push notification qua WS cho Staff khi món READY. |
| **N6** | Viết Billing API: tạo bill từ order_id, áp VAT + service fee, logic split evenly (chia đều N người) và xử lý số dư. |
| **N7** | Code review, sửa lỗi từ integration test nội bộ. Test ACID flow (2 request đồng thời). |
| **N8** | Viết API Reservation check-in (kích hoạt pre-order). Subscribe WS /ws/pos cho POS. |
| **N9–N10** | Hỗ trợ làm Admin UI (trong Internal Web) cho Menu, Variant/Modifier, Inventory, Bàn, Nhân sự. |
| **N11** | Chạy Integration test toàn hệ thống. Code review lần cuối. |
| **N12** | Thiết lập Docker Compose production (nginx proxy, healthcheck). |
| **N13–N14** | Viết file README hoàn chỉnh. Chuẩn bị kịch bản và tham gia demo trực tiếp cả 3 luồng. |

---

### TV2 - Backend Auth, Menu & Inventory (~25% Khối lượng)

**Trách nhiệm:** Phân quyền Auth, Quản lý Menu, Tồn kho (Inventory), và Đặt bàn.

- **Tuần 1:** Xây dựng JWT login, RBAC. Làm API CRUD cho MenuItem, Modifier. Cấu hình BOM và viết logic tự động trừ kho khi món SERVED.
- **Tuần 2:** Sửa lỗi, viết Integration test bằng Postman Newman. Hỗ trợ TV1 triển khai lên VPS và hỗ trợ xử lý luồng đặt bàn.

| Ngày | Danh sách Task Cụ thể của TV2 |
|------|-------------------------------|
| **N1** | Xây dựng Auth module: JWT login/refresh, bcrypt hash, model user, và RBAC middleware. |
| **N2** | Viết API CRUD cho User, thiết lập role enum, tính năng đổi mật khẩu. |
| **N3** | Viết API CRUD cho MenuItem, Category, tính năng bật/tắt is_available, phân trang, tìm kiếm. |
| **N4** | Viết API CRUD cho Variant, Modifier. Hàm tính tổng giá theo lựa chọn. |
| **N5** | Viết API CRUD cho Ingredient (Nguyên liệu). API cấu hình BOM (định lượng nguyên liệu cho món). |
| **N6** | Viết logic tự động trừ kho (BOM auto-deduct) khi món SERVED. Cảnh báo kho dưới ngưỡng. |
| **N7** | Viết pytest unit test cho BOM deduct (đủ/thiếu kho) và Auth token. Đảm bảo pass ≥ 10 test cases. |
| **N8** | Sửa lỗi hệ thống. Viết integration test Postman Newman cho Auth, Menu, Inventory. |
| **N9** | Chạy Newman test, bổ sung edge case test (modifier bắt buộc, BOM hết kho). |
| **N10** | Đảm bảo toàn bộ backend endpoint pass. Hỗ trợ fix bug UI. |
| **N11** | Stress test WebSocket KDS: mô phỏng 10 order cùng lúc, đảm bảo latency < 1s. |
| **N12** | Hỗ trợ deploy test lên server/VPS. Kiểm tra API trên môi trường prod. |
| **N13–N14** | Submit code. Tham gia demo, chịu trách nhiệm giải thích về BOM auto-deduct. |

---

### TV3 - Giao diện Khách hàng (Customer Web) (~22% Khối lượng)

**Trách nhiệm:** Phát triển độc lập toàn bộ giao diện Khách hàng (Customer Web) sử dụng HTML renderer.

- **Tuần 1:** Dựng trang menu chính, giỏ hàng, và chi tiết sản phẩm (chọn size/topping). Đăng ký lắng nghe WebSocket để hiển thị badge trạng thái món ăn theo thời gian thực.
- **Tuần 2:** Hoàn thiện luồng Đặt bàn nhiều bước (chọn giờ, chọn bàn, pre-order). Kiểm thử trực tiếp UI trên Chrome/Safari di động và chạy luồng quét mã QR thực tế.

| Ngày | Danh sách Task Cụ thể của TV3 |
|------|-------------------------------|
| **N1** | Setup Flutter Web với HTML renderer, cấu trúc thư mục, thư viện Dio, Riverpod, và GoRouter. |
| **N2** | Dựng màn hình menu chính, danh sách category, gọi API GET /menu/items, xử lý loading/empty state. |
| **N3** | Dựng chi tiết sản phẩm: Variant picker, Modifier picker, tính giá động. |
| **N4** | Dựng giỏ hàng (xem/sửa/xóa), form nhập tên + SĐT, gọi API POST /orders. |
| **N5** | Màn hình tracking: subscribe WS, hiển thị badge trạng thái từng món realtime. |
| **N6** | Flow đặt bàn: chọn ngày/giờ/bàn trống, gọi POST /reservations, màn hình xác nhận. |
| **N7** | Tích hợp Pre-order vào flow đặt bàn. Dựng Offline banner khi mất mạng. |
| **N8** | Hoàn thiện UI/UX. Test thật trên điện thoại Android + iOS (Chrome/Safari). |
| **N9** | Chạy Integration test Customer App ↔ Backend (Luồng 1 và 2), log bug. |
| **N10** | Sửa lỗi từ test N9. Tinh chỉnh (polish) các trạng thái loading/error toàn app. |
| **N11** | Đánh bóng lần cuối: test QR scan thực tế, test pre-order flow thực tế. |
| **N12** | Test Customer Web trên môi trường prod (không còn hardcode localhost). |
| **N13–N14** | Submit code, chuẩn bị thiết bị di động quét QR và trình bày luồng khách hàng. |

---

### TV4 - Giao diện Nội bộ (Internal Web) (~15% Khối lượng)

**Trách nhiệm:** Phát triển độc lập giao diện Nội bộ (Internal Web) sử dụng CanvasKit.

- **Tuần 1:** Xây dựng màn hình đăng nhập và tự động điều hướng theo phân quyền. Dựng màn hình POS (sơ đồ bàn, chi tiết hóa đơn, chia bill) và màn hình KDS trên tablet (thẻ món, nút đổi trạng thái, âm thanh).
- **Tuần 2:** Xây dựng giao diện Admin (quản lý nguyên liệu, bàn, nhân sự, BOM). Tích hợp cổng hiển thị VietQR tĩnh và kiểm thử toàn diện trên tablet thực tế chuẩn bị demo.

| Ngày | Danh sách Task Cụ thể của TV4 |
|------|-------------------------------|
| **N1** | Setup Flutter Web CanvasKit, cấu trúc thư mục, màn hình login UI. |
| **N2** | Route tự động theo role sau khi login. Dựng màn hình sơ đồ bàn (grid). |
| **N3** | KDS UI: subscribe WS /ws/kds/{zone}, render thẻ món cơ bản (tên, bàn). |
| **N4** | KDS UI: Nút PREPARING (vàng), READY (xanh lá), đồng hồ đếm ngược. |
| **N5** | KDS UI: Batching UI (gộp x3 Cà phê), tích hợp âm thanh alert, nút mute. |
| **N6** | POS UI: Màn hình đơn pending, chi tiết bill (liệt kê món, đơn giá). |
| **N7** | POS UI: Giao diện Split evenly (nhập số người, preview). Flow thanh toán tiền mặt. |
| **N8** | POS UI: Hiển thị VietQR tĩnh, xác nhận thẻ thủ công, ghi nhận PAID và đóng bàn. |
| **N9** | Admin UI: Quản lý nguyên liệu (tồn kho, cảnh báo), BOM config UI. |
| **N10** | Admin UI: Quản lý bàn (CRUD, xem/tải mã QR), Nhân sự (CRUD, cấp role, đổi pass). |
| **N11** | Tinh chỉnh Internal Web: test tablet KDS thực tế, test flow POS đầy đủ. |
| **N12** | Test Internal Web trên môi trường prod (kết nối đúng WS url prod). |
| **N13–N14** | Submit code, chuẩn bị máy tính/tablet demo. Trình bày tính năng split evenly và KDS batching. |

---

## 5. Tiêu chí Hoàn thành Bắt buộc (Must-have DoD)

Để sản phẩm đủ điều kiện nộp và demo, hệ thống **bắt buộc** phải đạt được các tiêu chí sau:

- **Chạy thông suốt Luồng 1:** Khách quét QR → chọn món → KDS nhận thẻ < 1s → nấu xong READY → bưng ra SERVED → thanh toán POS → bàn trở về trạng thái trống.
- **Xử lý đồng thời (ACID):** Demo thành công việc 2 người cùng đặt món cuối cùng trong kho nhưng chỉ 1 người thành công.
- **Trừ kho chính xác (BOM):** Đặt món không đủ nguyên liệu phải bị từ chối; hệ thống cảnh báo đúng khi tồn kho thấp.
- **Phân quyền chặt chẽ:** Thu ngân chỉ thấy POS, bếp chỉ thấy KDS, admin thấy toàn quyền.
- **Triển khai 1 lệnh:** Chạy được toàn bộ hệ thống bằng một lệnh Docker Compose.
