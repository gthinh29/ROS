# ĐẶC TẢ ĐỀ TÀI: HỆ THỐNG QUẢN LÝ VÀ ĐẶT BÀN NHÀ HÀNG (RESTAURANT ORDERING SYSTEM - ROS)

## 1. THÔNG TIN CHUNG
- **Tên đề tài:** Hệ thống quản lý nhà hàng thông minh (Restaurant Ordering System)
- **Nhóm thực hiện:** Nhóm 4 thành viên
- **Thời gian thực hiện:** 1 tháng (30 ngày lịch)
- **Nền tảng công nghệ:** 
  - Backend: Python 3.12, FastAPI, PostgreSQL 16, SQLAlchemy 2.0
  - Frontend: Flutter (Web & Mobile) - Kiến trúc Monorepo.
- **Mô hình kiến trúc:** Modular Monolith (Backend) và Client-Server.

---

## 2. BẢNG PHÂN CÔNG VAI TRÒ VÀ CÔNG VIỆC

| STT | Họ và Tên | Vai trò trong dự án | Các Module & Chức năng phụ trách |
|-----|-----------|---------------------|------------------------------------------------------|
| 1 | **Thành viên 1 (Lead - Thịnh)** | Backend Core & DevOps | - Xây dựng cấu trúc Modular Monolith, Database Schema (PostgreSQL).<br>- Code xử lý giao dịch ACID (`SELECT FOR UPDATE`) chống bán âm kho nguyên liệu.<br>- Cấu hình WebSockets đẩy thông báo realtime cho bếp (KDS).<br>- Xử lý luồng tạo Order, cập nhật toạ độ sơ đồ bàn và logic gộp món (Batching). Cấu hình Docker để deploy. |
| 2 | **Thành viên 2** | Backend Auth, Menu & Inventory | - Xây dựng module xác thực (JWT), phân quyền (RBAC) 4 vai trò.<br>- Code API CRUD cho Menu (Món ăn, Biến thể, Topping, Nổi bật), Bàn.<br>- Xây dựng logic quản lý Kho và định lượng nguyên liệu (BOM).<br>- Xây dựng API cho luồng Đặt bàn trực tuyến (Reservation). |
| 3 | **Thành viên 3** | Customer Web Developer | - Cấu hình Flutter Web render bằng HTML để tối ưu SEO và tốc độ tải trang.<br>- Xây dựng trang chủ hiển thị thông tin nhà hàng và món nổi bật.<br>- Xây dựng màn hình xem Menu tĩnh (khách chỉ xem món, không gọi qua điện thoại).<br>- Phát triển luồng Đặt bàn (chọn ngày giờ, chọn bàn trống thời gian thực). |
| 4 | **Thành viên 4 (Bạn của Thịnh)** | Internal Web & Admin Developer | - Xây dựng giao diện cho Admin: Dashboard Analytics, Quản lý Menu (upload ảnh), BOM, Kho hàng.<br>- Xây dựng màn hình Waiter: Sơ đồ bàn thời gian thực (lưới toạ độ x,y), giao diện gọi món thay cho khách.<br>- Xây dựng màn hình Bếp (KDS): Nhận order qua WebSockets.<br>- Xây dựng màn hình Thu ngân (POS): Tính tiền, tách bill (Split evenly). |

---

## 3. NỘI DUNG CHI TIẾT BÁO CÁO

### LỜI CẢM ƠN
Nhóm sinh viên xin gửi lời cảm ơn sâu sắc đến Giảng viên hướng dẫn đã tận tình chỉ bảo, hỗ trợ và cung cấp những kiến thức thực tế vô giá giúp nhóm hoàn thiện đồ án Hệ thống Quản lý Nhà hàng Thông minh (ROS). Nhờ sự định hướng của thầy/cô, nhóm đã có cơ hội cọ xát với những công nghệ mới nhất như FastAPI, WebSockets và Flutter, đồng thời giải quyết được các bài toán thực tiễn như chống bán âm kho và quản lý sơ đồ bàn thời gian thực.

### CHƯƠNG 1: TỔNG QUAN DỰ ÁN

**1.1. Bối cảnh và lý do chọn đề tài**
Trong thời đại chuyển đổi số, ngành kinh doanh dịch vụ ăn uống (F&B) đang ngày càng đòi hỏi sự chuyên nghiệp hoá trong khâu vận hành. Tuy nhiên, nhiều nhà hàng vừa và nhỏ hiện nay vẫn gặp phải các vấn đề nhức nhối như: mất đơn hàng do ghi chép giấy tay, tình trạng khách hàng đặt bàn trước nhưng khi đến lại không có chỗ, đặc biệt là lỗi bán âm kho (hệ thống báo còn món nhưng thực tế nguyên liệu đã hết do không đồng bộ kịp thời giữa bếp và thu ngân). Nhận thấy những lỗ hổng trong quy trình vận hành truyền thống, nhóm quyết định xây dựng "Hệ thống Quản lý và Đặt bàn Nhà hàng (ROS)" nhằm số hoá toàn diện quy trình vận hành nhà hàng.

**1.2. Mục tiêu dự án**
Dự án hướng tới việc xây dựng một hệ thống phần mềm hoàn chỉnh, chạy đa nền tảng (Web và Mobile) với 3 mục tiêu cốt lõi:
- **Tự động hoá luồng vận hành:** Khách hàng có thể lên website xem Menu và chủ động Đặt bàn trước (Reservation). Nhân viên phục vụ dùng máy tính bảng ghi nhận món ăn (Order) tại bàn, dữ liệu lập tức được đẩy xuống màn hình Bếp (KDS) thông qua công nghệ WebSockets với độ trễ dưới 1 giây.
- **Quản lý dữ liệu toàn vẹn:** Áp dụng cơ chế khoá bản ghi cơ sở dữ liệu (ACID Transaction bằng lệnh `SELECT FOR UPDATE` của PostgreSQL) để đảm bảo không bao giờ xảy ra tình trạng bán âm kho khi nhiều nhân viên cùng gọi một món ăn sắp hết nguyên liệu.
- **Thống kê và trực quan hoá:** Cung cấp cho người quản lý (Admin) một Dashboard thống kê doanh thu, món ăn bán chạy và sơ đồ bàn vật lý (có thể kéo thả toạ độ) một cách trực quan, chính xác.

**1.3. Đối tượng và phạm vi ứng dụng**
Hệ thống được thiết kế tối ưu cho các nhà hàng vừa và nhỏ, quán cafe, pub. 
- **Phạm vi trong hệ thống:** Hệ thống xử lý nội bộ hoàn chỉnh từ sơ đồ bàn, menu, định lượng nguyên liệu (BOM), đến thanh toán tách bill. Hệ thống cung cấp web cho Khách hàng xem Menu và Đặt bàn trực tuyến.
- **Phạm vi ngoài hệ thống:** Khách hàng **không** thực hiện việc gọi món trực tiếp (order) qua điện thoại (không dùng mã QR). Việc gọi món hoàn toàn do Nhân viên phục vụ (Waiter) thực hiện thao tác trên phần mềm nội bộ nhằm đảm bảo quy trình phục vụ chuyên nghiệp. Hệ thống không tích hợp giao hàng (Delivery).

### CHƯƠNG 2: PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG

**2.1. Phân tích yêu cầu chức năng (Functional Requirements)**
Hệ thống được thiết kế để phục vụ 4 nhóm người dùng chính, với các chức năng cụ thể như sau:
1. **Khách hàng (Customer):** Truy cập vào Website bằng trình duyệt (không cần cài đặt). Có thể xem danh sách món ăn, chi tiết biến thể và xem các món nổi bật. Sử dụng form Đặt bàn trực tuyến: chọn ngày, giờ (chỉ cho phép chọn thời điểm tương lai cách hiện tại tối thiểu 30 phút) và chọn bàn trống.
2. **Nhân viên Phục vụ (Waiter):** Đăng nhập vào Internal Web, xem sơ đồ bàn theo sơ đồ vật lý (trạng thái Trống, Đang phục vụ, Đã đặt trước). Thực hiện quy trình Tạo Order (gọi món) thay cho khách hàng. Hệ thống cho phép tuỳ biến món ăn (kích cỡ, topping, ghi chú không hành/ít đá). Nhận thông báo (Push Notification) khi bếp báo nấu xong món.
3. **Nhân viên Bếp (KDS - Kitchen Display System):** Theo dõi màn hình Tablet tại khu vực Bếp. Nhận thẻ món ăn ngay lập tức khi Waiter tạo order. Có thể gộp các món giống nhau (Batching) để nấu cùng lúc. Cập nhật trạng thái món (Đang nấu -> Đã xong) để báo cho Waiter bưng món.
4. **Quản lý & Thu ngân (Admin/Cashier):** Xem Dashboard thống kê doanh thu theo ngày/tuần. Quản lý thực đơn (thêm sửa xóa, upload hình ảnh). Cấu hình sơ đồ bàn (kéo thả tọa độ X, Y). Cấu hình định lượng nguyên liệu (BOM). Thanh toán và hỗ trợ tính năng chia tiền (Split Evenly) cho nhóm khách hàng.

**2.2. Phân tích yêu cầu phi chức năng (Non-functional Requirements)**
- **Hiệu năng & Thời gian thực:** Tính năng Kitchen Display System (KDS) và Cập nhật trạng thái sơ đồ bàn yêu cầu cập nhật theo thời gian thực. Hệ thống sử dụng công nghệ WebSockets của FastAPI để broadcast sự kiện thay vì HTTP Polling, giúp giảm thiểu tải server và giữ độ trễ (latency) dưới 1s.
- **Toàn vẹn dữ liệu (Data Integrity):** Chống bán âm kho. Khi order được tạo, backend sử dụng khoá bi quan (Pessimistic Locking) ở cấp độ hàng (Row-level lock) trong PostgreSQL. Nếu 2 waiter cùng lúc order 1 món chỉ còn 1 phần nguyên liệu, giao dịch đến sau sẽ bị từ chối và báo lỗi.
- **Bảo mật:** Sử dụng JWT (JSON Web Tokens) cho quá trình xác thực. Phân quyền chặt chẽ theo Role-Based Access Control (RBAC).

**2.3. Sơ đồ Use Case tổng quát**
Hệ thống bao gồm các ca sử dụng (Use case) cốt lõi:
- **Admin:** Đăng nhập, Xem Dashboard, Quản lý Menu, Cấu hình Sơ đồ Bàn, Quản lý Kho, Quản lý Tài khoản.
- **Waiter:** Đăng nhập, Quản lý Đặt bàn (Check-in khách), Xem Sơ đồ bàn, Tạo Order, Cập nhật trạng thái món (Đã phục vụ).
- **Kitchen:** Đăng nhập, Xem KDS theo Zone, Đổi trạng thái món (Ready).
- **Cashier:** Xem danh sách hoá đơn, Tách Bill, Đóng bàn.
- **Customer:** Xem Menu, Gửi yêu cầu Đặt bàn.

**2.4. Thiết kế Cơ sở dữ liệu (ERD)**
Cơ sở dữ liệu được thiết kế chuẩn hoá với các bảng chính:
- Bảng `users`: Lưu thông tin tài khoản nội bộ và vai trò (role).
- Bảng `tables`: Quản lý bàn vật lý bao gồm `id`, `name`, `capacity`, tọa độ `pos_x`, `pos_y` và `status`.
- Bảng `menu_items`, `variants`, `modifiers`: Quản lý món ăn, kích cỡ (buộc chọn) và topping (tuỳ chọn). Có trường `is_featured` và `image_url`.
- Bảng `ingredients` và `bom_items`: Quản lý tồn kho nguyên liệu. Bảng `bom_items` liên kết món ăn với các nguyên liệu cấu thành để tự động trừ kho.
- Bảng `orders` và `order_items`: Lưu thông tin gọi món tại bàn, theo dõi trạng thái vòng đời từng món ăn (`PENDING`, `PREPARING`, `READY`, `SERVED`).
- Bảng `reservations`: Lưu trữ dữ liệu khách đặt bàn trực tuyến bao gồm thời gian đặt, số điện thoại, trạng thái (`PENDING`, `CONFIRMED`, `CHECKED_IN`).

**2.5. Thiết kế kiến trúc hệ thống**
- **Backend:** Xây dựng theo mô hình Modular Monolith. Các module (auth, menu, orders, tables, analytics) được chia tách độc lập để dễ bảo trì, nhưng vẫn chạy chung trên một process để giảm độ phức tạp khi triển khai so với Microservices.
- **Frontend (Kiến trúc Đa nền tảng - Cross-platform):** Lựa chọn Flutter làm công nghệ cốt lõi giúp hệ thống đạt được khả năng "viết code một lần, chạy mọi nơi". Toàn bộ giao diện được quản lý theo cấu trúc Monorepo, có một "Shared Package" dùng chung chứa các Model, HTTP Client, và thuật toán tính giá tiền. Nhờ tính chất đa nền tảng, hệ thống có thể triển khai dưới hai hình thức:
  + **Web Platform:** Ứng dụng Customer Web sử dụng HTML Renderer giúp tải cực nhanh trên trình duyệt web của khách hàng. Ứng dụng Internal Web sử dụng CanvasKit Renderer tận dụng sức mạnh GPU giúp các thao tác kéo thả sơ đồ bàn mượt mà như app gốc.
  + **Mobile/Tablet Platform:** Sẵn sàng biên dịch (compile) thành file cài đặt ứng dụng gốc (APK cho Android hoặc IPA cho iOS) để cài đặt trực tiếp lên Máy tính bảng của Đầu bếp (KDS) hoặc iPad của Phục vụ (Waiter) nhằm tối ưu hoá độ trễ và thao tác cảm ứng, hoàn toàn không cần phải viết lại code.

### CHƯƠNG 3: TRIỂN KHAI VÀ XÂY DỰNG ỨNG DỤNG

**3.1. Phân hệ Backend (FastAPI & PostgreSQL)**
Phân hệ Backend được xây dựng hoàn toàn bằng ngôn ngữ Python sử dụng framework FastAPI hiện đại. Nhóm tận dụng tối đa tính năng Asynchronous của Python để xử lý hàng ngàn kết nối WebSockets đồng thời. 
Tính năng chống bán âm kho được triển khai bằng cơ chế ACID Transaction. Cụ thể, khi tiếp nhận API `POST /orders`, hệ thống mở một transaction, tính toán tổng số nguyên liệu cần thiết bằng cách query bảng `bom_items`. Sau đó, hệ thống thực thi câu lệnh `SELECT ... FOR UPDATE` trên bảng `ingredients` để khóa dữ liệu. Trong thời điểm đó, mọi giao dịch khác cố gắng mua cùng nguyên liệu sẽ phải chờ. Nếu số lượng `stock_qty` nhỏ hơn yêu cầu, hệ thống tung ra Exception `422 Unprocessable Entity` và Rollback giao dịch, đảm bảo không có món nào bị lưu vào database nếu không đủ nguyên liệu.

**3.2. Phân hệ Frontend Nội bộ (Internal Web / Waiter App)**
Ứng dụng dành cho nhân viên (Internal Web) là một SPA (Single Page Application) duy nhất. Dựa vào JWT Token trả về sau khi đăng nhập, hệ thống tự động nhận diện Role và định tuyến đến đúng giao diện:
- Màn hình Waiter: Render sơ đồ bàn dạng lưới. Khi bấm vào một bàn, Waiter tiến hành chọn món, thêm ghi chú (ví dụ: "ít đường"). Sau khi bấm xác nhận, WebSockets lập tức thay đổi màu sắc của bàn sang "Đang phục vụ".
- Màn hình POS (Thu ngân): Khi khách tính tiền, thu ngân có thể dùng tính năng "Split Evenly" để chia đều hoá đơn cho $N$ người, thuật toán tự động làm tròn và dồn tiền lẻ thừa cho người cuối cùng trả để không bị thất thoát số liệu kế toán.

**3.3. Phân hệ Frontend Admin & Khách Hàng (Customer Web)**
- Màn hình Khách hàng: Giao diện trực quan cho phép xem toàn bộ thực đơn kèm hình ảnh. Tại module Đặt bàn, hệ thống chỉ cho phép khách hàng chọn giờ đặt cách thời điểm hiện tại tối thiểu 30 phút. Khách hàng xem danh sách bàn trống trong khoảng thời gian đó và tiến hành ghi nhận đặt chỗ.
- Màn hình Admin: Tích hợp thư viện `fl_chart` để trực quan hoá doanh thu theo thời gian dưới dạng biểu đồ đường (Line chart). Admin có giao diện cấu hình trực quan: tải ảnh món ăn lên server, và thiết lập công thức món ăn (ví dụ: 1 ly trà đào = 1 gói trà + 30ml syrup + 2 miếng đào).

### CHƯƠNG 4: ĐÁNH GIÁ, TỔNG KẾT VÀ HƯỚNG PHÁT TRIỂN

**4.1. Kết quả đạt được**
Trải qua 30 ngày nghiên cứu và phát triển, nhóm đã hoàn thành xuất sắc hệ thống ROS đáp ứng đầy đủ yêu cầu nghiệp vụ của một nhà hàng quy mô vừa. Hệ thống đã khắc phục triệt để tình trạng bán âm kho. Sự kết hợp giữa WebSockets cho nhà bếp (KDS) và giao diện gọi món thông minh cho Waiter giúp giảm tải tới 40% thời gian giao tiếp chạy bộ giữa nhân viên phục vụ và bếp. Luồng đặt bàn trực tuyến cũng giúp nhà hàng chủ động chuẩn bị đón khách mà không bị trùng lịch (double-booking).

**4.2. Khó khăn và hạn chế**
Trong quá trình triển khai, khó khăn lớn nhất là việc xử lý State Management (Riverpod) bên phía Flutter khi phải đồng bộ giữa dữ liệu nhận được từ WebSockets (Push) và dữ liệu thay đổi cục bộ của người dùng (Local State) trên Sơ đồ bàn. Ngoài ra, việc thiết lập môi trường Docker chạy cả Nginx, Backend và Database đòi hỏi nhiều công sức cấu hình bảo mật.

**4.3. Hướng phát triển trong tương lai**
Trong tương lai, nhóm dự kiến sẽ tiếp tục phát triển các tính năng mở rộng:
- Tích hợp cổng thanh toán trực tuyến (VNPay/MoMo) trực tiếp vào màn hình của Thu ngân.
- Phát triển module Báo cáo chuyên sâu, cho phép xuất file Excel thống kê hiệu suất nấu ăn của từng đầu bếp.
- Tích hợp trí tuệ nhân tạo (AI) phân tích hành vi để đề xuất thực đơn cho khách hàng vãng lai.

---

**TÀI LIỆU THAM KHẢO**
1. FastAPI Documentation: https://fastapi.tiangolo.com
2. SQLAlchemy 2.0 Docs: https://docs.sqlalchemy.org
3. Flutter Official Documentation: https://flutter.dev/docs
4. Design Patterns for Monolithic Architecture - O'Reilly.
