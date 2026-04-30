FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /workspace

# 1. Copy shared package
COPY shared/ shared/

# 2. Caching dependencies
COPY internal_web/pubspec.yaml internal_web/pubspec.lock* ./internal_web/
WORKDIR /workspace/internal_web
RUN flutter pub get

# 3. Copy source and build
COPY internal_web/ .
RUN flutter build web --release --base-href /

# ── Stage 2: Serve ──
FROM nginx:1.25-alpine
COPY --from=builder /workspace/internal_web/build/web /usr/share/nginx/html
RUN echo 'server { listen 80; root /usr/share/nginx/html; index index.html; location / { try_files $uri $uri/ /index.html; } }' > /etc/nginx/conf.d/default.conf
EXPOSE 80
