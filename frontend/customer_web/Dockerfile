# ── Stage 1: Build ───────────────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /workspace

# Copy shared package first (used as path dependency)
COPY shared/ shared/

# Copy customer_web source
COPY customer_web/ customer_web/

WORKDIR /workspace/customer_web

RUN flutter pub get
RUN flutter build web --release --base-href /

# ── Stage 2: Serve with nginx ─────────────────────────────────────────────────
FROM nginx:1.25-alpine

COPY --from=builder /workspace/customer_web/build/web /usr/share/nginx/html

# SPA fallback: rewrite all routes to index.html
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { try_files $uri $uri/ /index.html; } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
