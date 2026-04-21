# 80 — Dockerizing and Deploying a Leptos App

> **Type:** How-To + Tutorial

## Multi-stage Dockerfile

```dockerfile
# Stage 1: Build the Leptos app
FROM rust:1.77-slim-bookworm AS builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    pkg-config libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install cargo-leptos and Wasm target
RUN cargo install cargo-leptos --locked
RUN rustup target add wasm32-unknown-unknown
RUN cargo install wasm-bindgen-cli --locked

# Cache dependencies
COPY Cargo.toml Cargo.lock ./
COPY Leptos.toml ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release --features ssr 2>/dev/null || true
RUN rm -rf src

# Build the actual app
COPY . .
RUN cargo leptos build --release

# Stage 2: Minimal runtime image
FROM debian:bookworm-slim AS runtime

WORKDIR /app

RUN apt-get update && apt-get install -y \
    ca-certificates libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Copy the server binary
COPY --from=builder /app/target/release/myapp ./myapp

# Copy the site directory (Wasm, JS, CSS, assets)
COPY --from=builder /app/target/site ./target/site

# Copy migrations
COPY --from=builder /app/migrations ./migrations

ENV LEPTOS_OUTPUT_NAME=myapp
ENV LEPTOS_SITE_ROOT=./target/site
ENV LEPTOS_SITE_ADDR=0.0.0.0:3000
ENV LEPTOS_ENV=PROD

EXPOSE 3000

CMD ["./myapp"]
```

## docker-compose.yml

```yaml
version: '3.9'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=sqlite:/data/app.db
      - SESSION_SECRET=${SESSION_SECRET}
      - LEPTOS_ENV=PROD
    volumes:
      - app_data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 5s
      retries: 3

volumes:
  app_data:
```

## Nginx reverse proxy

```nginx
# nginx.conf
server {
    listen 80;
    server_name yourdomain.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://app:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (for hot reload in dev, or WebSocket features)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Cache static Wasm/JS/CSS assets
    location /pkg/ {
        proxy_pass http://app:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## Deploying to Railway / Render / Fly.io

**Railway/Render:** Connect GitHub repo, set environment variables, deploy. They auto-detect Dockerfile.

**Fly.io:**
```bash
fly launch --name myapp
fly secrets set SESSION_SECRET=your-secret DATABASE_URL=postgres://...
fly volumes create app_data --size 1
fly deploy
```

`fly.toml`:
```toml
app = "myapp"
primary_region = "sea"

[build]
dockerfile = "Dockerfile"

[[services]]
  http_checks = []
  internal_port = 3000
  protocol = "tcp"
  [[services.ports]]
    handlers = ["http"]
    port = 80
  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443
```

## Production checklist

- [ ] `LEPTOS_ENV=PROD` (disables debug logging, enables compression)
- [ ] `DATABASE_URL` pointing to production DB (PostgreSQL recommended, not SQLite)
- [ ] `SESSION_SECRET` is a random 32+ byte hex string
- [ ] HTTPS terminated at load balancer or Nginx
- [ ] Static assets (`/pkg/*`) have long cache headers
- [ ] Health check endpoint returns 200
- [ ] Run `sqlx migrate run` before starting the app
- [ ] Backups configured for the database
