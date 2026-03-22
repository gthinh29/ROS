**TÀI LIỆU ĐẶC TẢ HỆ THỐNG**

**Restaurant Ordering System**

  ---------------------- ------------------------------------------------------
  **Tên đề tài**         **Restaurant Ordering System**

  **Phiên bản**          v1.0 --- Tháng 3/2026

  **Nhóm thực hiện**     Nhóm 4 thành viên

  **Thời gian**          2 tuần (14 ngày lịch --- \~7 ngày làm việc hiệu quả)

  **Backend**            Python 3.12 + FastAPI + PostgreSQL 16

  **Frontend**           Flutter Web (Dart) --- 2 ứng dụng web
  ---------------------- ------------------------------------------------------

Mục lục

1\. Tổng quan dự án

1.1. Tên đề tài và mục tiêu

**Đề tài: Restaurant Ordering System --- Hệ thống đặt món nhà hàng.**

Hệ thống giải quyết toàn bộ vòng đời đặt món tại nhà hàng, từ lúc khách tiếp cận thực đơn đến khi hoàn thành thanh toán. Mục tiêu là xây dựng sản phẩm thực tế, có thể triển khai cho doanh nghiệp sử dụng, không phải prototype học thuật.

Hệ thống tập trung vào ba giá trị cốt lõi:

-   Ordering đúng nghiệp vụ: khách đặt món qua nhiều kênh (tại bàn, đặt trước từ xa), bếp nhận đơn realtime.

-   Tính toàn vẹn dữ liệu: không bán âm kho, không mất đơn khi nhiều người đặt cùng lúc.

-   Vận hành đơn giản: thu ngân, bếp, nhân viên phục vụ đều có giao diện riêng phù hợp công việc.

1.2. Phạm vi hệ thống

Hệ thống bao gồm các chức năng sau:

-   Đặt bàn trực tuyến và pre-order món trước khi đến nhà hàng.

-   Gọi món tại bàn thông qua QR code (khách tự thao tác hoặc nhân viên hỗ trợ).

-   Quản lý bếp realtime qua Kitchen Display System (KDS).

-   Thanh toán và tách bill tại POS.

-   Quản lý nguyên liệu, Bill of Materials (BOM), kiểm tra tồn kho trước khi nhận đơn.

-   Quản lý menu, bàn, nhân viên từ giao diện admin.

Hệ thống không bao gồm:

-   Giao hàng (delivery) và tích hợp shipper.

-   Cổng thanh toán online thật (VNPay, MoMo) --- chỉ cần ghi nhận thanh toán tiền mặt và QR tĩnh VietQR.

-   Loyalty points, voucher phức tạp, báo cáo xuất CSV.

-   Mobile native app (iOS/Android) --- sử dụng Flutter Web chạy trên trình duyệt.

1.3. Đối tượng sử dụng

  -----------------------------------------------------------------------------------------------------------------------------
  **Đối tượng**                **Thiết bị sử dụng**       **Chức năng chính**
  ---------------------------- -------------------------- ---------------------------------------------------------------------
  Khách hàng                   Điện thoại (trình duyệt)   Đặt bàn, pre-order, gọi món tại bàn qua QR, theo dõi trạng thái món

  Thu ngân (Cashier)           Máy tính / Tablet          Xem bill, thanh toán, tách bill, đóng bàn

  Bếp / Bar (Kitchen)          Tablet màn hình lớn        Xem thẻ món realtime, cập nhật trạng thái nấu

  Nhân viên phục vụ (Waiter)   Điện thoại hoặc Tablet     Xem trạng thái bàn, tạo order hộ khách, nhận thông báo món xong

  Quản lý (Admin)              Máy tính                   Quản lý menu, BOM, nguyên liệu, bàn, nhân sự
  -----------------------------------------------------------------------------------------------------------------------------

2\. Tech stack và kiến trúc hệ thống

2.1. Tech stack

  ---------------------------------------------------------------------------------------------------------------------------------
  **Hạng mục**        **Công nghệ**                   **Lý do chọn**
  ------------------- ------------------------------- -----------------------------------------------------------------------------
  Backend framework   Python 3.12 + FastAPI           Async native, WebSocket built-in, Pydantic validation, hiệu năng cao

  Database            PostgreSQL 16                   ACID transactions, row-level locking (SELECT FOR UPDATE), JSONB

  ORM / Migration     SQLAlchemy 2.0 + Alembic        Async ORM, type-safe queries, migration version control

  Real-time           FastAPI WebSockets + asyncio    Room-based broadcast theo zone (Bếp/Bar/Staff), không cần Redis

  Authentication      JWT (access + refresh token)    Stateless, RBAC theo role: admin/cashier/kitchen/waiter

  Customer Web        Flutter Web --- HTML renderer   Dart, bundle nhỏ (\~800KB), mobile-friendly, cùng codebase với Internal Web

  Internal Web        Flutter Web --- CanvasKit       POS + KDS + Admin trong một app, phân quyền theo role khi login

  Container           Docker + Docker Compose         Services: api + postgres + nginx, deploy một lệnh

  QR Code             Python qrcode library           Gen QR từ URL bàn, xuất PNG, in dán lên bàn vật lý
  ---------------------------------------------------------------------------------------------------------------------------------

2.2. Kiến trúc tổng thể

Hệ thống sử dụng kiến trúc Modular Monolith --- một backend duy nhất nhưng được tổ chức thành các module độc lập theo domain nghiệp vụ. Lựa chọn này phù hợp với quy mô nhóm nhỏ và timeline ngắn, đồng thời cho phép nâng cấp lên microservices sau này nếu cần.

**Cấu trúc thư mục backend:**

-   app/modules/auth/ --- JWT, middleware, phân quyền RBAC

-   app/modules/menu/ --- CRUD sản phẩm, biến thể, modifier

-   app/modules/inventory/ --- Nguyên liệu, BOM, auto trừ kho

-   app/modules/tables/ --- Sơ đồ bàn, QR code, trạng thái

-   app/modules/orders/ --- Tạo đơn, state machine, ACID lock

-   app/modules/kds/ --- WebSocket dispatcher, KDS broadcast

-   app/modules/billing/ --- Hóa đơn, split bill, thanh toán

-   app/modules/reservations/ --- Đặt bàn, pre-order

-   app/core/ --- Database, config, shared models, WebSocket manager

2.3. Luồng dữ liệu và giao tiếp

Hai cơ chế giao tiếp chính giữa backend và frontend:

-   HTTP REST API: dùng cho tất cả thao tác CRUD, tạo đơn, thanh toán. Mọi request đều có JWT header (trừ endpoint public như GET /menu).

-   WebSocket: dùng cho 3 kênh realtime --- /ws/kds/{zone} đẩy thẻ món về bếp/bar, /ws/staff/{user_id} push notification khi món READY, /ws/pos đẩy sự kiện bàn đổi trạng thái về POS.

Fallback strategy: nếu WebSocket mất kết nối, frontend tự động chuyển sang HTTP polling mỗi 3 giây. Banner cảnh báo \"Mất kết nối\" hiển thị cho người dùng và tự kết nối lại khi mạng phục hồi.

3\. Kiến trúc Frontend

Hệ thống có 2 ứng dụng Flutter Web độc lập, cùng viết bằng Dart, dùng chung một shared package chứa models, API client và WebSocket client. Hai app chạy trên trình duyệt --- không cần cài đặt, không cần app store.

3.1. Tổng quan cấu trúc Monorepo

Toàn bộ code frontend được tổ chức theo cấu trúc Monorepo gồm 3 phần:

  -----------------------------------------------------------------------------------------------------------------------------------------------
  **Thư mục**               **Nội dung**
  ------------------------- ---------------------------------------------------------------------------------------------------------------------
  frontend/shared/          Dart package dùng chung: models, ApiClient (Dio + JWT interceptor), WsClient, enum, utils định dạng tiền/ngày

  frontend/customer_web/    Customer Web --- giao diện khách hàng: đặt bàn, gọi món qua QR, theo dõi đơn realtime

  frontend/internal_web/    Internal Web --- giao diện nội bộ: POS (cashier), KDS (kitchen/bar), Waiter, Admin trong 1 app phân quyền theo role
  -----------------------------------------------------------------------------------------------------------------------------------------------

Lý do dùng shared package: tránh duplicate Dart model giữa 2 app. Khi backend thay đổi response schema, chỉ cần sửa 1 chỗ trong shared/ là cả 2 app cập nhật đồng thời. JWT interceptor và WS reconnect logic viết một lần, dùng ở cả hai.

3.2. Shared Package --- Cấu trúc chi tiết

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **Module**              **Nội dung**
  ----------------------- ------------------------------------------------------------------------------------------------------------------------------------------------
  models/                 Order, OrderItem, MenuItem, Variant, Modifier, Table, Reservation, Ingredient, BomItem, Bill, User --- mỗi class có fromJson/toJson

  api/api_client.dart     Dio instance: base URL từ env, interceptor tự gắn Authorization header, tự gọi /auth/refresh khi nhận 401, ném ApiException có message rõ ràng

  ws/ws_client.dart       WebSocketChannel wrapper: connect(url), subscribe(room), stream\<WsEvent\>, tự reconnect sau 3s khi mất kết nối, expose connectionState

  constants/enums.dart    OrderStatus, OrderItemStatus, TableStatus, UserRole, PaymentMethod, ReservationStatus --- dùng chung giữa UI và API parsing

  utils/formatters.dart   formatVND(int amount), formatDateTime(DateTime), calcItemTotal(basePrice, variant, modifiers) --- tính giá động cho cart
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------

3.3. Customer Web --- Kiến trúc chi tiết

Flutter Web với HTML renderer. Bundle size \~800KB, tối ưu cho mobile browser. Đây là giao diện duy nhất khách hàng tương tác.

3.3.1. Cấu trúc thư mục

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **Thư mục / File**             **Vai trò**
  ------------------------------ -----------------------------------------------------------------------------------------------------------------------------------------------------------------
  lib/main.dart                  Entrypoint: khởi tạo ProviderScope (Riverpod), GoRouter, inject ApiClient từ env config

  lib/router.dart                GoRouter: /, /table/:tableId, /reserve, /reserve/preorder, /order/:orderId. Redirect nếu tableId không hợp lệ

  lib/features/menu/             Màn hình menu: CategoryBar, MenuItemList, SearchBar. MenuProvider: cache theo category, invalidate khi toggle availability

  lib/features/product/          Chi tiết sản phẩm: VariantSelector (required), ModifierList (optional/required), ghi chú tự do, tính giá động real-time

  lib/features/cart/             CartNotifier (StateNotifier): thêm/xóa/sửa qty, tổng tiền, form nhập tên + SĐT, submit POST /orders

  lib/features/order_tracking/   Sau submit: subscribe WS /ws/customer/{orderId}, hiển thị badge trạng thái từng món, animation khi READY

  lib/features/reservation/      Multi-step form: bước 1 chọn ngày/giờ/số người, bước 2 chọn bàn trống (từ GET /tables?available=true&datetime=\...), bước 3 pre-order tuỳ chọn, bước 4 xác nhận

  lib/widgets/                   MenuItemCard, VariantChip, ModifierCheckbox, CartBadge, StatusBadge, OfflineBanner, LoadingOverlay
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

3.3.2. State Management --- Riverpod

-   menuProvider (FutureProvider): fetch GET /menu/items, groupBy category. Refresh khi pull-to-refresh.

-   cartProvider (StateNotifierProvider\<CartNotifier, CartState\>): danh sách CartItem, tổng tiền. Reset về empty sau khi order thành công.

-   orderTrackingProvider (StreamProvider): wrap WsClient.stream(), filter theo orderId. UI tự rebuild mỗi khi trạng thái món thay đổi --- không cần setState.

-   reservationFormProvider (StateNotifierProvider): quản lý multi-step form state, validate từng bước, submit cuối.

-   availableTablesProvider (FutureProvider.family\<DateTime\>): fetch bàn trống theo datetime được chọn trong form đặt bàn.

3.4. Internal Web --- Kiến trúc chi tiết

Flutter Web với CanvasKit renderer. Chạy trên máy tính cashier và tablet bếp/bar. Một app duy nhất, login xong tự route về đúng giao diện theo role.

3.4.1. Cấu trúc thư mục

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **Thư mục / File**         **Vai trò**
  -------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------
  lib/main.dart              Entrypoint: ProviderScope, GoRouter với redirect guard, khởi tạo WsClient sau khi authProvider có token

  lib/router.dart            Redirect guard đọc role từ authProvider: cashier→/pos, kitchen→/kds, waiter→/waiter, admin→/admin. Unauthorized→/login

  lib/features/auth/         LoginScreen, AuthNotifier: gọi POST /auth/login, lưu JWT vào FlutterSecureStorage, expose currentUser (User model với role)

  lib/features/pos/          POS --- cashier: TableGrid (màu theo status), BillDetail, SplitEvenlyModal, PaymentScreen (cash/vietqr/card), CloseTableButton

  lib/features/kds/          KDS --- kitchen/bar: OrderCardList (realtime WS), OrderCard (tên món + variant + modifier + bàn + timer), PREPARING/READY buttons, BatchingBadge, SoundAlert

  lib/features/waiter/       Waiter: TableGrid realtime (WS /ws/pos), CreateOrderFlow (chọn bàn→menu→variant/modifier→submit), NotificationOverlay khi món READY

  lib/features/admin/        Admin: 5 sub-section --- Menu CRUD, BOM Config, Inventory Dashboard, Table Manager (+ QR download), Staff Manager

  lib/widgets/               AppShell (sidebar navigation theo role), OrderCard, BillRow, TableTile, InventoryAlertBadge, ConfirmDialog
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

3.4.2. Role-based Routing

  ------------------------------------------------------------------------------------------------------------------------------
  **Role**    **Route mặc định**   **Routes được phép**
  ----------- -------------------- ---------------------------------------------------------------------------------------------
  cashier     /pos                 /pos, /pos/table/:id, /pos/bill/:id, /pos/split, /pos/payment

  kitchen     /kds                 /kds (zone lấy từ user.profile, tự subscribe đúng WS room)

  waiter      /waiter              /waiter/tables, /waiter/order/:id, /waiter/create

  admin       /admin               Tất cả routes trên + /admin/menu, /admin/bom, /admin/inventory, /admin/tables, /admin/staff
  ------------------------------------------------------------------------------------------------------------------------------

Nếu user cố truy cập route không thuộc role: redirect về route mặc định, không hiện 403 error --- giao diện đơn giản là không tồn tại route đó với họ.

3.4.3. KDS Screen --- chi tiết thiết kế

-   Kết nối WS /ws/kds/{zone} ngay khi màn hình mount. Zone đọc từ user.profile.zone (kitchen hoặc bar).

-   Mỗi order_item mới từ WS → render OrderCard: tên món, variant, modifier, ghi chú đặc biệt, số bàn, thời gian đặt (đếm ngược giây).

-   Batching: order_items cùng menu_item_id trong cùng WS batch → gộp 1 card với badge \"×3\". Giúp bếp nấu gộp, giảm thời gian phục vụ.

-   PREPARING button → card đổi nền vàng. READY button → card đổi nền xanh lá, trigger WS push tới Staff.

-   Card biến mất khi nhân viên xác nhận SERVED từ Waiter screen.

-   Âm thanh beep khi card mới xuất hiện. Nút mute góc màn hình, trạng thái lưu trong SharedPreferences.

-   Offline: OfflineBanner màu đỏ, WsClient tự reconnect sau 3s. Fallback HTTP polling GET /orders?status=PREPARING&zone={zone} mỗi 3 giây.

3.4.4. POS Screen --- chi tiết thiết kế

-   Layout 2 cột: cột trái TableGrid (màu EMPTY=xanh, OCCUPIED=đỏ, RESERVED=tím, CLEANING=xám), cột phải BillDetail của bàn đang chọn.

-   Subscribe WS /ws/pos: khi bàn đổi trạng thái hoặc có order mới, TableGrid tự cập nhật không cần reload.

-   BillDetail: liệt kê từng OrderItem với đơn giá, subtotal, VAT từ restaurant.settings, service fee, tổng cộng.

-   Split Evenly: nhập N người → tính total/N, người cuối trả phần dư (total - (N-1) \* floor(total/N)). Preview rõ từng người trả bao nhiêu trước khi confirm.

-   Thanh toán tiền mặt: nhập số tiền khách đưa → hiển thị tiền thừa. Confirm → POST /billing/checkout với method=CASH.

-   VietQR: hiển thị QR tĩnh embed số tiền (theo chuẩn VietQR). Cashier xác nhận thủ công sau khi kiểm tra app ngân hàng.

-   Đóng bàn: tất cả sub-bill PAID → bàn tự về EMPTY qua WS, order COMPLETED. TableGrid cập nhật màu ngay lập tức.

4\. Thiết kế cơ sở dữ liệu

7.1. Sơ đồ quan hệ (ERD --- mô tả)

Hệ thống sử dụng PostgreSQL với các bảng chính được tổ chức theo 4 nhóm domain:

-   Domain Người dùng & Xác thực: users, restaurants

-   Domain Menu & Nguyên liệu: menu_items, variants, modifiers, ingredients, bom_items

-   Domain Bàn & Đặt chỗ: tables, reservations

-   Domain Đơn hàng & Thanh toán: orders, order_items, order_modifiers, bills, inventory_logs

7.2. Bảng chi tiết

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **Bảng**          **Cột chính**                                                                                                   **Ghi chú nghiệp vụ**
  ----------------- --------------------------------------------------------------------------------------------------------------- -------------------------------------------------------
  users             id, role, name, phone, password_hash, created_at                                                                Role: admin / cashier / kitchen / waiter

  restaurants       id, name, settings (JSONB)                                                                                      Cấu hình VAT, phí dịch vụ, tên nhà hàng, logo URL

  tables            id, zone, number, qr_token, status, restaurant_id                                                               Status: EMPTY / OCCUPIED / RESERVED / CLEANING

  menu_items        id, name, category_id, base_price, image_url, is_available                                                      Toggle is_available ảnh hưởng ngay Customer Web

  variants          id, menu_item_id, name, extra_price                                                                             Biến thể bắt buộc: Size S/M/L

  modifiers         id, menu_item_id, name, extra_price, is_required                                                                Topping tùy chọn hoặc bắt buộc

  ingredients       id, name, unit, stock_qty, alert_threshold                                                                      Nguyên liệu kho, hiển thị cảnh báo khi dưới ngưỡng

  bom_items         id, menu_item_id, variant_id, ingredient_id, qty_required                                                       Công thức: 1 Cà phê M = 20g bột + 30ml sữa

  reservations      id, table_id, customer_name, phone, reserved_at, party_size, status, note                                       Status: PENDING / CONFIRMED / CHECKED_IN / CANCELLED

  orders            id, table_id, reservation_id, customer_name, phone, type, status, total, created_at                             Type: DINE_IN / PRE_ORDER. Status: PENDING→COMPLETED

  order_items       id, order_id, menu_item_id, variant_id, qty, price, note, status                                                Status riêng từng món: PENDING→PREPARING→READY→SERVED

  order_modifiers   id, order_item_id, modifier_id, price                                                                           Modifier khách chọn cho từng order_item

  bills             id, order_id, subtotal, tax, service_fee, discount, total, payment_method, paid_amount, change_amount, status   Status: PENDING / PAID. Method: CASH / VIETQR / CARD

  inventory_logs    id, ingredient_id, delta, reason, order_id, created_at                                                          Audit log mọi biến động kho, delta âm = trừ kho
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

6.3. Ràng buộc kỹ thuật quan trọng

-   Concurrency / ACID: khi tạo order, backend dùng SELECT FOR UPDATE để lock nguyên liệu, tránh bán âm kho khi nhiều request đến cùng lúc.

-   Cascade delete: order_items và order_modifiers bị xóa theo order. Inventory_logs không xóa (immutable audit trail).

-   UUID primary keys cho tất cả bảng --- tránh xung đột khi merge data hoặc nâng cấp sau.

-   JSONB cho restaurant.settings: linh hoạt cấu hình VAT (%), service_fee (%), logo_url mà không cần migration khi thêm field.

5\. Luồng nghiệp vụ (Business Flows)

4.1. Luồng 1 --- Dine-in QR (Gọi món tại bàn)

Đây là luồng cốt lõi nhất của hệ thống, xảy ra mỗi khi khách ngồi tại bàn và tự gọi món qua điện thoại.

1.  Khách quét QR code dán trên bàn bằng camera điện thoại → trình duyệt mở Customer Web tại URL yourapp.com/table/{table_id}.

2.  Customer Web đọc table_id từ URL, gọi GET /tables/{id} để lấy thông tin bàn và menu.

3.  Khách duyệt menu theo category, chọn món, chọn variant (size) và modifier (topping), thêm ghi chú riêng cho từng món.

4.  Khách nhập tên và SĐT (không cần tài khoản), bấm \"Gửi Bếp\".

5.  Backend nhận POST /orders --- kiểm tra tồn kho nguyên liệu với SELECT FOR UPDATE. Nếu đủ: lock tạm, tạo order PENDING. Nếu thiếu: rollback, trả lỗi 422 \"Hết nguyên liệu\".

6.  Bàn chuyển trạng thái EMPTY → OCCUPIED. WebSocket đẩy event về POS ngay lập tức.

7.  WebSocket đẩy thẻ món về KDS đúng zone: đồ ăn → zone:kitchen, đồ uống → zone:bar. Độ trễ mục tiêu \< 1 giây.

8.  Bếp nhận thẻ món, bấm PREPARING → READY. Khi READY, backend push notification về Staff App.

9.  Nhân viên phục vụ nhận popup \"Bàn X có món xong\", bấm \"Đã bưng\" → order_item chuyển SERVED. Backend tự động trừ kho nguyên liệu theo BOM và ghi inventory_log.

10. Khách có thể gọi thêm món bất kỳ lúc nào --- mỗi lần là một order mới gắn cùng table_id.

11. Khi khách yêu cầu thanh toán, thu ngân mở POS → xem bill tổng hợp → thu tiền → đóng bàn → trạng thái về EMPTY.

4.2. Luồng 2 --- Đặt bàn trước và Pre-order (CGV Style)

Khách đặt bàn và đặt món từ xa trước khi đến nhà hàng. Khi đến nơi, món đã được chuẩn bị sẵn.

12. Khách truy cập Customer Web, chọn ngày/giờ/số người, chọn bàn còn trống.

13. Khách tuỳ chọn pre-order món --- giống Luồng 1 nhưng chưa gửi xuống bếp ngay.

14. Nhập tên và SĐT, xác nhận đặt bàn. Backend tạo reservation trạng thái PENDING, bàn chuyển RESERVED.

15. Admin/Staff xác nhận reservation (gọi điện hoặc qua Internal Web) → trạng thái CONFIRMED.

16. Khi khách đến nhà hàng, nhân viên tìm reservation theo SĐT, bấm \"Check-in\" → reservation CHECKED_IN, bàn OCCUPIED.

17. Nếu khách có pre-order: backend tự động tạo order từ pre-order items, đẩy xuống KDS ngay lập tức. Bếp bắt đầu chuẩn bị.

18. Khách ngồi xuống, món đã sẵn hoặc gần xong. Khách có thể gọi thêm món qua QR như Luồng 1.

19. Thanh toán như Luồng 1.

4.3. Luồng 3 --- Nhân viên tạo order hộ khách

Dành cho khách không dùng điện thoại hoặc không muốn tự thao tác. Nhân viên dùng Internal Web để tạo order thay.

20. Nhân viên login Internal Web (role: waiter), chọn bàn trên sơ đồ.

21. Giao diện hiện menu --- nhân viên chọn món, variant, modifier thay cho khách.

22. Xác nhận order → flow tiếp theo giống Luồng 1 từ bước 5 trở đi.

5.4. Luồng 4 --- Thanh toán và Tách bill

23. Thu ngân mở POS, chọn bàn hoặc tìm order.

24. Xem bill: danh sách món, đơn giá, VAT (%), phí dịch vụ (%) tự động tính từ restaurant.settings.

25. Nếu cần tách bill: chọn \"Split evenly\" → nhập số người → hệ thống chia đều tổng tiền, xử lý số lẻ (người cuối trả phần dư).

26. Chọn phương thức thanh toán: Tiền mặt (nhập số tiền khách đưa, tính tiền thừa) / VietQR (hiển thị mã QR tĩnh) / Quẹt thẻ (xác nhận thủ công).

27. Sau khi tất cả phần tiền ghi nhận PAID → bàn tự động về EMPTY, order COMPLETED.

6\. Đặc tả Use Case

5.1. Danh sách Use Case

  -------------------------------------------------------------------------------------------------------------------------
  **ID**   **Tên Use Case**          **Actor**           **Mô tả ngắn**
  -------- ------------------------- ------------------- ------------------------------------------------------------------
  UC01     Đặt bàn trực tuyến        Khách hàng          Chọn ngày/giờ/bàn, nhập thông tin, xác nhận đặt chỗ

  UC02     Pre-order món             Khách hàng          Chọn món kèm đặt bàn, gửi trước lên hệ thống

  UC03     Gọi món qua QR tại bàn    Khách hàng          Quét QR, chọn món, gửi bếp không cần tài khoản

  UC04     Theo dõi trạng thái món   Khách hàng          Xem realtime từng món PENDING→READY trên điện thoại

  UC05     Tạo order hộ khách        Nhân viên phục vụ   Thao tác trên Internal Web để đặt món cho khách

  UC06     Check-in reservation      Nhân viên phục vụ   Xác nhận khách đã đến, kích hoạt pre-order xuống bếp

  UC07     Nhận thông báo món xong   Nhân viên phục vụ   Nhận push WS khi bếp đánh READY, bưng bàn, xác nhận SERVED

  UC08     Cập nhật trạng thái KDS   Bếp / Bar           Nhận thẻ món, bấm PREPARING → READY trên tablet

  UC09     Tách bill và thanh toán   Thu ngân            Xem bill, split evenly, thu tiền nhiều phương thức, đóng bàn

  UC10     Quản lý menu              Admin               CRUD món ăn, variant, modifier, bật/tắt is_available

  UC11     Cấu hình BOM              Admin               Gán nguyên liệu và định lượng cho từng món/variant

  UC12     Quản lý nguyên liệu       Admin               CRUD nguyên liệu, cập nhật tồn kho thủ công, xem cảnh báo ngưỡng

  UC13     Quản lý bàn và QR         Admin               CRUD bàn/zone, sinh QR code PNG, xem trạng thái bàn

  UC14     Quản lý nhân sự           Admin               CRUD nhân viên, phân vai trò, reset mật khẩu
  -------------------------------------------------------------------------------------------------------------------------

5.2. Đặc tả chi tiết --- UC03: Gọi món qua QR tại bàn

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **Thuộc tính**         **Nội dung**
  ---------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Use Case ID            UC03

  Tên                    Gọi món qua QR tại bàn

  Actor chính            Khách hàng

  Điều kiện tiên quyết   Bàn ở trạng thái EMPTY hoặc OCCUPIED. QR code dán trên bàn còn hợp lệ. Có ít nhất 1 món còn available trong menu.

  Luồng chính            1\. Khách quét QR → trình duyệt mở Customer Web 2. Hệ thống hiển thị menu nhà hàng theo category 3. Khách chọn món, chọn variant, chọn modifier, thêm ghi chú 4. Khách thêm vào giỏ, xem lại giỏ hàng, nhập tên + SĐT 5. Bấm \"Gửi Bếp\" → hệ thống tạo order 6. Khách thấy màn hình tracking trạng thái từng món

  Luồng thay thế         A1 --- Hết nguyên liệu: bước 5 trả lỗi \"Hết \[tên nguyên liệu\]\", khách xóa món đó và thử lại. A2 --- Bàn đã có order: khách có thể gọi thêm món, hệ thống tạo order mới gắn cùng table_id. A3 --- Mất kết nối: hiển thị thông báo lỗi, không cho submit, khách liên hệ nhân viên.

  Hậu điều kiện          Order được tạo trạng thái PENDING. Bàn chuyển OCCUPIED. Thẻ món xuất hiện trên KDS bếp/bar trong \< 1 giây.

  Độ ưu tiên             Cao --- đây là luồng chính của hệ thống
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

5.3. Đặc tả chi tiết --- UC08: Cập nhật trạng thái KDS

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **Thuộc tính**         **Nội dung**
  ---------------------- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Use Case ID            UC08

  Tên                    Cập nhật trạng thái KDS

  Actor chính            Bếp / Bar

  Điều kiện tiên quyết   Nhân viên bếp/bar đang xem KDS Web trên tablet. WebSocket đã kết nối thành công.

  Luồng chính            1\. Thẻ món xuất hiện realtime khi có order mới (âm thanh alert) 2. Bếp xem thông tin: tên món, variant, modifier, ghi chú, tên bàn, thời gian đặt 3. Bếp bấm PREPARING → thẻ đổi màu vàng 4. Bếp hoàn thành, bấm READY → thẻ đổi màu xanh lá 5. Hệ thống push notification đến Staff App của nhân viên phục vụ 6. Sau khi nhân viên xác nhận SERVED, thẻ biến mất khỏi KDS

  Batching logic         Nếu nhiều bàn đặt cùng một món (vd: 3 bàn cùng gọi Cà phê sữa), KDS hiển thị 1 thẻ với số lượng \"x3\" thay vì 3 thẻ riêng --- giúp bếp nấu gộp hiệu quả.

  Hậu điều kiện          order_item.status được cập nhật. Nhân viên phục vụ nhận push notification khi READY.
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

7\. Thiết kế API

6.1. Nguyên tắc chung

-   Base URL: /api/v1/

-   Authentication: JWT Bearer token trong Authorization header. Các endpoint public (menu, QR check) không cần token.

-   Response format: JSON thuần, có trường status và data hoặc error.

-   Error codes: 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 422 Business Logic Error (vd: hết kho), 500 Internal Server Error.

6.2. Danh sách endpoint chính

  ---------------------------------------------------------------------------------------------------------------------------
  **Endpoint**                      **Method**       **Auth**        **Mô tả**
  --------------------------------- ---------------- --------------- --------------------------------------------------------
  **AUTH**                                                           

  /auth/login                       POST             Public          Đăng nhập, trả access_token + refresh_token

  /auth/refresh                     POST             Public          Cấp access_token mới từ refresh_token

  **MENU**                                                           

  /menu/items                       GET              Public          Danh sách món theo nhà hàng, filter category/available

  /menu/items                       POST             Admin           Tạo món mới

  /menu/items/{id}                  PATCH            Admin           Cập nhật món, toggle is_available

  /menu/items/{id}/variants         POST             Admin           Thêm variant (size) cho món

  /menu/items/{id}/modifiers        POST             Admin           Thêm modifier (topping) cho món

  **TABLES**                                                         

  /tables                           GET              Staff           Danh sách bàn kèm trạng thái realtime

  /tables                           POST             Admin           Tạo bàn mới, tự động sinh QR code PNG

  /tables/{id}/qr                   GET              Admin           Tải lại QR PNG của bàn

  **RESERVATIONS**                                                   

  /reservations                     POST             Public          Tạo đặt bàn mới (có thể kèm pre-order)

  /reservations/{id}/checkin        POST             Staff           Check-in khách, kích hoạt pre-order xuống KDS

  /reservations/{id}/confirm        PATCH            Staff           Xác nhận reservation PENDING → CONFIRMED

  **ORDERS**                                                         

  /orders                           POST             Public/Staff    Tạo order mới --- ACID lock inventory, state PENDING

  /orders/{id}/items/{iid}/status   PATCH            Kitchen/Staff   Cập nhật trạng thái từng order_item

  **BILLING**                                                        

  /billing/create                   POST             Cashier         Tạo bill từ order_id, tính VAT + service fee tự động

  /billing/split                    POST             Cashier         Tách bill chia đều theo N người

  /billing/checkout                 POST             Cashier         Ghi nhận thanh toán, đóng phiên, bàn về EMPTY

  **INVENTORY**                                                      

  /inventory/ingredients            GET/POST/PATCH   Admin           CRUD nguyên liệu, xem tồn kho hiện tại

  /inventory/bom                    POST             Admin           Cấu hình BOM: gán nguyên liệu và định lượng cho món

  **WEBSOCKET**                                                      

  /ws/kds/{zone}                    WS               Kitchen/Bar     Nhận thẻ món realtime theo zone (kitchen/bar)

  /ws/staff/{user_id}               WS               Waiter          Nhận push notification khi món READY

  /ws/pos                           WS               Cashier         Nhận event bàn đổi trạng thái, order mới
  ---------------------------------------------------------------------------------------------------------------------------

8\. Phân quyền hệ thống (RBAC)

Hệ thống sử dụng Role-Based Access Control với 4 role cố định. Mỗi role chỉ thấy đúng giao diện và endpoint phù hợp với công việc.

  --------------------------------------------------------------------------------------------------------------------------------
  **Role**     **Quyền truy cập**
  ------------ -------------------------------------------------------------------------------------------------------------------
  admin        Toàn quyền: CRUD menu, variant, modifier, BOM, nguyên liệu, bàn, nhân sự, cấu hình nhà hàng. Xem báo cáo tồn kho.

  cashier      Xem và xử lý billing: tạo bill, split, checkout. Xem trạng thái bàn. KHÔNG thấy quản lý menu hay nhân sự.

  kitchen      Chỉ xem KDS theo zone được gán. Cập nhật trạng thái PREPARING/READY. KHÔNG thấy bill hay thông tin khách.

  waiter       Xem sơ đồ bàn, tạo order hộ khách, nhận notification, xác nhận SERVED. KHÔNG thấy doanh thu hay bill.
  --------------------------------------------------------------------------------------------------------------------------------

9\. Phân công nhân sự

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **Thành viên**   **Tỉ lệ**   **Trách nhiệm chính**                                                        **Chi tiết task cốt lõi**
  ---------------- ----------- ---------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  TV1 (Lead)       \~38%       Backend cốt lõi: Order ACID, KDS WebSocket, Billing + DevOps + Code Review   Scaffold FastAPI, schema DB, Docker Compose, WebSocket manager, Table CRUD + QR gen, Order creation ACID (SELECT FOR UPDATE), KDS WS dispatcher + batching, Billing API + Split evenly, Docker prod, README

  TV2              \~25%       Backend: Auth/RBAC, Menu, Inventory/BOM, Reservation                         JWT login/refresh, RBAC middleware, User CRUD, Menu CRUD (item/category/variant/modifier), Ingredient CRUD, BOM config, BOM auto-deduct khi SERVED, Reservation API + check-in flow, Unit test pytest

  TV3              \~22%       Customer Web (Flutter): toàn bộ giao diện khách hàng                         Setup Flutter Web HTML renderer, màn hình menu + category filter, Variant/Modifier picker, giỏ hàng + checkout, Order tracking WS, Đặt bàn + pre-order flow, Integration test Customer ↔ API

  TV4              \~15%       Internal Web (Flutter): POS + KDS + Admin trong 1 app                        Setup Flutter Web CanvasKit, login + role routing, KDS tablet UI (WS, thẻ món, PREPARING/READY, batching, âm thanh), POS bill UI (split evenly, thanh toán, đóng bàn), Admin menu/BOM/inventory/bàn/nhân sự UI
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Nguyên tắc cộng tác:**

-   TV1 là người duy nhất merge vào nhánh main. Mọi PR phải qua TV1 review trước khi merge.

-   TV1 cung cấp Postman collection và API contract chuẩn trước ngày 3 để TV2/TV3/TV4 phát triển song song.

-   Họp đồng bộ nhanh cuối mỗi ngày (15 phút): ai đang làm gì, bị chặn ở đâu.

-   TV2 có thể backup TV1 ở phần Auth và Menu nếu TV1 bị chặn ở Order/KDS.

10\. Kế hoạch triển khai 2 tuần

10.1. Các mốc kiểm tra (Milestones)

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **M#**   **Ngày**       **Tiêu chí hoàn thành**                                                                                              **Chịu trách nhiệm**
  -------- -------------- -------------------------------------------------------------------------------------------------------------------- --------------------------
  M1       Cuối ngày 3    FastAPI chạy, DB migrate thành công, JWT login hoạt động, Postman test pass Auth + Menu GET                          TV1 + TV2

  M2       Cuối ngày 7    POST /orders tạo được, KDS nhận WS event \< 1s, Customer Web gọi món được từ QR, Internal Web login được theo role   TV1 + TV3 + TV4

  M3       Cuối ngày 10   Chạy được end-to-end Luồng 1 hoàn chỉnh: QR → gọi món → KDS → SERVED → bill. Inventory trừ kho đúng theo BOM         Cả nhóm

  M4       Cuối ngày 12   Luồng 2 (đặt bàn + pre-order) và Luồng 4 (split evenly + thanh toán) chạy được. Integration test pass                Cả nhóm

  M5       Cuối ngày 14   Docker Compose prod chạy một lệnh, demo toàn bộ 3 luồng live thành công, README + user guide đủ                      TV1
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------

10.2. Bảng kế hoạch theo ngày --- Tuần 1

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **Ngày**   **TV1 (Lead)**                                                                                                                                                 **TV2**                                                                                                                                                    **TV3**                                                                                                                  **TV4**
  ---------- -------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------ ---------------------------------------------------------------------------------------------------------------------------
  N1         FastAPI scaffold, Modular Monolith structure, PostgreSQL schema, Alembic migration, Docker Compose, WebSocket manager class                                    Auth module: JWT login/refresh, bcrypt hash, user model, RBAC middleware                                                                                   Setup Flutter Web HTML renderer, project structure, Dio HTTP client, Riverpod, routing                                   Setup Flutter Web CanvasKit, project structure, routing, login screen UI

  N2         Table CRUD + zone, QR code gen (qrcode lib), trạng thái EMPTY/OCCUPIED/RESERVED, WS broadcast sơ đồ bàn                                                        Auth: User CRUD, role enum, guard dependency injection theo endpoint, đổi mật khẩu                                                                         Customer: màn hình menu chính, danh sách category, GET /menu/items, loading/empty state                                  Internal: sau login → route theo role, màn hình sơ đồ bàn (grid), lấy trạng thái từ API

  N3         TV1 viết API contract + Postman collection → share cho cả nhóm. Order creation API: ACID transaction, SELECT FOR UPDATE, PENDING state, lock inventory check   Menu: CRUD MenuItem, Category, is_available toggle, image URL, pagination, search                                                                          Customer: màn hình chi tiết sản phẩm, Variant picker, Modifier picker, tính giá động                                     Internal KDS: subscribe WS /ws/kds/{zone}, render thẻ món cơ bản, thông tin tên món + bàn

  N4         Order state machine PENDING→PREPARING→READY→SERVED, validate transition, KDS WS dispatcher phân luồng food→kitchen / drink→bar                                 Menu: Variant CRUD, Modifier CRUD + is_required validation, API tính tổng giá theo lựa chọn                                                                Customer: giỏ hàng (xem/sửa/xóa), tổng tiền, nhập tên + SĐT, nút Gửi Bếp → POST /orders                                  Internal KDS: nút PREPARING (màu vàng), READY (màu xanh lá), đếm ngược thời gian chờ

  N5         KDS batching logic: gom order_items cùng menu_item_id từ nhiều bàn, gửi batch event. Staff push WS /ws/staff/{user_id} khi READY                               Ingredient CRUD: tên, đơn vị, stock_qty, alert_threshold. BOM config API: map món ↔ nguyên liệu ↔ định lượng                                               Customer: màn hình tracking order --- subscribe WS, badge trạng thái từng món realtime, không cần reload                 Internal KDS: batching UI (hiển thị x3 Cà phê), âm thanh alert khi order mới, nút mute

  N6         Billing API: tạo bill từ order_id, áp VAT + service fee từ restaurant.settings, split evenly chia đều N người, xử lý số lẻ                                     BOM auto-deduct: khi order_item → SERVED, trigger trừ kho từng nguyên liệu theo BOM, ghi inventory_log. Alert khi stock \< threshold hiển thị trên Admin   Customer: Đặt bàn flow: chọn ngày/giờ/bàn, POST /reservations, màn hình xác nhận đặt chỗ thành công                      Internal POS: màn hình danh sách order pending, chi tiết bill (itemize từng món, đơn giá, thành tiền)

  N7         Fix bug từ integration test nội bộ ngày 6. Check toàn bộ ACID flow: test 2 request đồng thời mua món cuối --- chỉ 1 pass. Code review TV2/TV3/TV4              Viết pytest unit test: BOM deduct đủ kho, BOM deduct thiếu kho (expect rollback), Auth token validation. Target ≥ 10 test cases pass                       Customer: Pre-order flow trong đặt bàn --- chọn món kèm đặt bàn, data lưu vào reservation. Offline banner khi mất mạng   Internal POS: Split evenly UI (nhập N người, preview bill từng người). Thanh toán tiền mặt: nhập số tiền → tính tiền thừa
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

10.3. Bảng kế hoạch theo ngày --- Tuần 2

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **Ngày**   **TV1 (Lead)**                                                                                                                                                                             **TV2**                                                                                                              **TV3**                                                                                                                **TV4**
  ---------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ -------------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------------
  N8         Reservation check-in API: nhận khách đến, kích hoạt pre-order → tạo order từ reservation_items → đẩy KDS. Subscribe WS /ws/pos cho POS                                                     Fix bug Auth/Menu từ feedback TV3/TV4. Viết integration test Postman Newman cho Auth + Menu + Inventory collection   Customer: hoàn thiện UI/UX toàn bộ Customer Web. Test thật trên điện thoại Android + iOS (trình duyệt Chrome/Safari)   Internal POS: VietQR (hiển thị QR tĩnh), xác nhận card thủ công, ghi nhận PAID, đóng bàn → EMPTY

  N9         Admin UI (trong Internal Web): Menu management CRUD, Variant/Modifier management                                                                                                           Chạy Newman collection, fix bug từ kết quả test, viết thêm edge case test (modifier required, BOM hết kho)           Integration test Customer App ↔ Backend: chạy toàn bộ Luồng 1 và Luồng 2 end-to-end, ghi lại bug                       Internal Admin UI: quản lý nguyên liệu (tồn kho, alert threshold), BOM config UI (chọn món → thêm nguyên liệu + định lượng)

  N10        Admin UI tiếp: Inventory dashboard (tồn kho hiện tại, cảnh báo dưới ngưỡng), Bàn management + QR download, Nhân sự CRUD                                                                    Hỗ trợ fix bug cho TV3 nếu cần. Đảm bảo toàn bộ backend endpoint theo Postman collection đều pass                    Fix bug Luồng 1 + Luồng 2 từ test ngày 9. Polish loading/error/empty states toàn bộ Customer Web                       Internal Admin UI: quản lý bàn (CRUD, xem QR, download PNG), nhân sự (CRUD, phân role, đổi mật khẩu)

  N11        Integration test toàn hệ thống: chạy Luồng 1 + 2 + 3 + 4 end-to-end liên tục không lỗi. Code review lần cuối tất cả PR                                                                     Stress test WebSocket: mô phỏng 10 order cùng lúc, đo latency KDS, đảm bảo \< 1 giây, không drop message             Final polish Customer Web: test QR scan thực tế, test pre-order flow thực tế, fix mọi bug còn lại                      Final polish Internal Web: test KDS trên tablet thực tế, test POS flow đầy đủ, fix mọi bug còn lại

  N12        Docker Compose production: docker-compose.prod.yml, nginx reverse proxy, env file template, healthcheck                                                                                    Hỗ trợ TV1 deploy test lên server/VPS. Kiểm tra toàn bộ API hoạt động trên môi trường prod                           Test Customer Web trên môi trường prod URL, đảm bảo QR gen đúng URL prod, không còn hardcode localhost                 Test Internal Web trên môi trường prod, đảm bảo WS kết nối đúng URL prod, không còn hardcode

  N13        Viết README hoàn chỉnh: hướng dẫn cài đặt, seed data, tài khoản demo, cấu hình môi trường. Chuẩn bị kịch bản demo 3 luồng                                                                  Submit backend code, viết release notes, hỗ trợ demo preparation                                                     Submit Customer Web, chuẩn bị thiết bị demo (điện thoại + kịch bản QR scan)                                            Submit Internal Web, chuẩn bị thiết bị demo (tablet KDS + máy tính POS)

  N14        Demo live toàn hệ thống: Luồng 1 (QR → KDS → SERVED → bill), Luồng 2 (đặt bàn → check-in → pre-order sẵn), Luồng 4 (split evenly → thanh toán). Trả lời câu hỏi về ACID/BOM nếu được hỏi   Tham gia demo. Giải thích BOM auto-deduct, ACID concurrency nếu được hỏi                                             Tham gia demo. Giải thích Customer Web flow, WS tracking trạng thái                                                    Tham gia demo. Giải thích KDS batching, POS split evenly logic
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

11\. Quản lý rủi ro

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **Rủi ro**                                                                                   **Mức độ**   **Xác suất**   **Phương án xử lý**
  -------------------------------------------------------------------------------------------- ------------ -------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  TV1 bị chặn hoặc gặp sự cố cá nhân --- toàn nhóm bị block do phụ thuộc quá nhiều vào TV1     Cao          Trung bình     TV2 được cross-train phần Auth + Menu. TV1 chia sẻ API contract sớm ngày 3. Họp đồng bộ hàng ngày để phát hiện block sớm. TV1 viết TODO comment rõ ràng để người khác có thể tiếp tục

  WebSocket không ổn định --- KDS delay \> 1 giây, ảnh hưởng vận hành bếp                      Cao          Trung bình     Implement HTTP polling fallback 3 giây từ ngày 1, không phải sau khi WS lỗi. Stress test WS ở ngày 11. Nếu WS không ổn định cho demo, dùng polling làm primary

  ACID concurrency bug --- bán âm kho khi nhiều request đồng thời                              Cao          Thấp           Viết unit test ACID ngay khi implement (ngày 5). Test case: 2 request đồng thời, inventory = 1 --- chỉ 1 pass. SQLAlchemy SELECT FOR UPDATE đã battle-tested

  Scope creep trong quá trình làm --- thêm tính năng không có trong kế hoạch                   Trung bình   Cao            Freeze requirement sau ngày 5. Mọi tính năng mới phải họp nhóm approve. Ưu tiên 3 luồng chính chạy mượt hơn là thêm tính năng mới

  Flutter Web tương thích kém trên một số trình duyệt --- khách không dùng được Customer Web   Trung bình   Thấp           Test thật trên Chrome + Safari (iOS) từ ngày 8. Dùng HTML renderer cho Customer Web. Nếu có vấn đề, fallback về React cơ bản cho Customer Web (TV3 cần nắm React cơ bản làm backup)

  Pre-order flow phức tạp hơn dự kiến --- conflict bàn, reservation state machine              Trung bình   Trung bình     Nếu ngày 8 chưa xong Luồng 2, cắt pre-order và chỉ làm đặt bàn (không kèm món). Luồng 1 là must-have, Luồng 2 là nice-to-have
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

12\. Tiêu chí hoàn thành (Definition of Done)

12.1. Must-have --- demo không có thì trừ điểm nặng

-   Luồng 1 chạy end-to-end không lỗi: QR scan → chọn món (với variant + modifier) → gửi bếp → KDS nhận \< 1s → READY → SERVED → trừ kho theo BOM → POS thanh toán → bàn về EMPTY.

-   ACID concurrency: test demo 2 yêu cầu đồng thời mua món cuối cùng --- chỉ 1 thành công, 1 nhận thông báo hết hàng.

-   Inventory + BOM: đặt món thiếu nguyên liệu → bị từ chối với thông báo rõ ràng. Tồn kho hiển thị cảnh báo khi dưới ngưỡng.

-   Internal Web phân quyền đúng: cashier chỉ thấy POS, kitchen chỉ thấy KDS, admin thấy tất cả.

-   Docker Compose: docker-compose up một lệnh là hệ thống chạy hoàn chỉnh.

12.2. Should-have --- có thì cộng điểm

-   Luồng 2: đặt bàn trước + pre-order → check-in → KDS nhận ngay.

-   Split evenly: tách bill đều N người, xử lý số lẻ đúng.

-   KDS batching: nhiều bàn cùng đặt món giống nhau → 1 thẻ với qty gộp.

-   WS reconnect tự động và HTTP polling fallback.

-   Unit test coverage: ít nhất 10 test case cho BOM deduct và Auth.

12.3. Nice-to-have --- nếu còn thời gian

-   Âm thanh alert KDS khi có order mới.

-   In bill (browser print dialog).

-   Admin xem tổng quan tồn kho nguyên liệu theo dạng bảng đơn giản.

Phụ lục --- Thuật ngữ và viết tắt

  ----------------------------------------------------------------------------------------------------------------------------------------------
  **Thuật ngữ**       **Giải thích**
  ------------------- --------------------------------------------------------------------------------------------------------------------------
  KDS                 Kitchen Display System --- màn hình hiển thị thẻ món cho bếp/bar, thay thế giấy in phiếu bếp

  POS                 Point of Sale --- giao diện thu ngân, nơi xử lý bill và thanh toán

  BOM                 Bill of Materials --- công thức nguyên liệu: mỗi món cần bao nhiêu gram/ml nguyên liệu nào

  ACID                Atomicity, Consistency, Isolation, Durability --- tính chất đảm bảo transaction DB không bị lỗi khi xảy ra đồng thời

  SELECT FOR UPDATE   Câu lệnh SQL khóa dòng dữ liệu trong transaction, ngăn 2 request đồng thời sửa cùng một bản ghi

  WebSocket (WS)      Giao thức kết nối 2 chiều liên tục giữa server và client, dùng để đẩy dữ liệu realtime không cần polling

  JWT                 JSON Web Token --- chuỗi mã hoá chứa thông tin xác thực, dùng để xác minh identity mà không cần query DB mỗi request

  RBAC                Role-Based Access Control --- phân quyền theo vai trò, mỗi role có tập quyền cố định

  Modular Monolith    Kiến trúc một backend duy nhất nhưng code được tổ chức thành module độc lập theo domain, dễ tách thành microservices sau

  Pre-order           Đặt món trước khi đến nhà hàng, kèm theo đặt bàn, bếp chuẩn bị sẵn khi khách check-in

  Split evenly        Tách bill chia đều tổng tiền cho N người, người cuối trả phần dư (làm tròn lên)

  Variant             Biến thể bắt buộc của món: size S/M/L, ảnh hưởng giá và BOM nguyên liệu

  Modifier            Lựa chọn thêm vào của món: topping, ghi chú đặc biệt, có thể bắt buộc hoặc tuỳ chọn

  QR Token            Chuỗi định danh duy nhất mã hoá thành QR code, dùng để xác định bàn khi khách quét
  ----------------------------------------------------------------------------------------------------------------------------------------------

**--- Hết tài liệu ---**
