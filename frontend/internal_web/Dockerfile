FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /workspace

# Cho phép override URL lúc build (ví dụ: docker build --build-arg API_URL=https://api.mysite.com)
ARG API_URL=http://localhost:8080
ARG WS_URL=ws://localhost:8080/ws

# 1. Copy shared package
COPY shared/ shared/

# 2. Caching dependencies
COPY internal_web/pubspec.yaml internal_web/pubspec.lock* ./internal_web/
WORKDIR /workspace/internal_web
RUN flutter pub get

# 3. Copy source and build
COPY internal_web/ .
RUN flutter build web --release --base-href / \
    --dart-define=API_URL=${API_URL} \
    --dart-define=WS_URL=${WS_URL}

# ── Stage 2: Serve ──
FROM nginx:1.25-alpine
COPY --from=builder /workspace/internal_web/build/web /usr/share/nginx/html
RUN echo 'server { listen 80; root /usr/share/nginx/html; index index.html; location / { try_files $uri $uri/ /index.html; } }' > /etc/nginx/conf.d/default.conf
EXPOSE 80
