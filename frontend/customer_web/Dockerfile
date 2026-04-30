FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /workspace

# 1. Copy shared package (dependencies)
COPY shared/ shared/

# 2. Caching: Chỉ copy pubspec để tải thư viện trước
COPY customer_web/pubspec.yaml customer_web/pubspec.lock* ./customer_web/
WORKDIR /workspace/customer_web
RUN flutter pub get

# 3. Sau đó mới copy source code (Bước này hay thay đổi nên để dưới cùng)
COPY customer_web/ .
RUN flutter build web --release --base-href /

# ── Stage 2: Serve ──
FROM nginx:1.25-alpine
COPY --from=builder /workspace/customer_web/build/web /usr/share/nginx/html
RUN echo 'server { listen 80; root /usr/share/nginx/html; index index.html; location / { try_files $uri $uri/ /index.html; } }' > /etc/nginx/conf.d/default.conf
EXPOSE 80
