# 96 — CI/CD Pipeline for Leptos Apps

> **Type:** How-To + Reference

## Pipeline overview

```
git push → GitHub Actions
              │
              ├── Check (cargo check, clippy, fmt)
              ├── Test (cargo test --features ssr)
              ├── Build (cargo leptos build --release)
              ├── E2E tests (Playwright)
              └── Deploy (Docker → server / Fly.io)
```

## GitHub Actions workflow

```yaml
# .github/workflows/ci.yml
name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  CARGO_TERM_COLOR: always
  DATABASE_URL: sqlite:./test.db

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Rust
        uses: dtolnay/rust-toolchain@stable
        with:
          targets: wasm32-unknown-unknown
          components: clippy, rustfmt

      - name: Cache cargo
        uses: Swatinem/rust-cache@v2

      - name: Format check
        run: cargo fmt --all -- --check

      - name: Clippy (server)
        run: cargo clippy --features ssr -- -D warnings

      - name: Clippy (client)
        run: cargo clippy --features hydrate -- -D warnings

  test:
    runs-on: ubuntu-latest
    needs: check
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable

      - name: Install sqlx-cli
        run: cargo install sqlx-cli --no-default-features --features sqlite

      - name: Run migrations
        run: sqlx database create && sqlx migrate run

      - name: Run tests
        run: cargo test --features ssr

  build:
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Rust + Wasm target
        uses: dtolnay/rust-toolchain@stable
        with: { targets: wasm32-unknown-unknown }

      - name: Cache cargo
        uses: Swatinem/rust-cache@v2

      - name: Install cargo-leptos
        run: cargo install cargo-leptos --locked

      - name: Install wasm-bindgen-cli
        run: cargo install wasm-bindgen-cli --locked

      - name: Build release
        run: cargo leptos build --release

      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .

      - name: Login to registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Push image
        run: |
          docker tag myapp:${{ github.sha }} ghcr.io/${{ github.repository }}:latest
          docker push ghcr.io/${{ github.repository }}:latest

  e2e:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }

      - name: Install Playwright
        run: npx playwright install --with-deps chromium

      - name: Pull and run app
        run: |
          docker pull ghcr.io/${{ github.repository }}:latest
          docker run -d -p 3000:3000 \
            -e DATABASE_URL=sqlite:/tmp/test.db \
            -e SESSION_SECRET=ci-test-secret \
            ghcr.io/${{ github.repository }}:latest

      - name: Wait for server
        run: |
          until curl -s http://localhost:3000/api/health; do sleep 1; done

      - name: Run E2E tests
        run: npx playwright test

  deploy:
    runs-on: ubuntu-latest
    needs: e2e
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to Fly.io
        uses: superfly/flyctl-actions/setup-flyctl@master
      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

## Caching strategy

```yaml
- name: Cache cargo registry and build artifacts
  uses: Swatinem/rust-cache@v2
  with:
    key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
    restore-keys: |
      ${{ runner.os }}-cargo-
```

Caching Cargo registry and build artifacts can reduce CI time from 8+ minutes to 2-3 minutes on subsequent pushes.

## Branch protection rules

Protect `main` with:
- Require status checks: `check`, `test`.
- Require pull request reviews (≥1 reviewer).
- Dismiss stale reviews on push.
- No force pushes.

## Secrets to configure

```
GITHUB_TOKEN     - auto-provided
FLY_API_TOKEN    - from flyctl auth token
SESSION_SECRET   - random hex string
DATABASE_URL     - production DB URL
SENTRY_DSN       - error monitoring (optional)
```

## Database migrations in CI

```yaml
- name: Check sqlx offline metadata is up to date
  run: cargo sqlx prepare --check --workspace
```

`sqlx prepare` generates `.sqlx/` offline query metadata — ensures queries are type-checked even without a live DB in CI.
