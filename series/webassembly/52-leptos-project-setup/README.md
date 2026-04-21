# 52 — Setting Up a Leptos Project with cargo-leptos

> **Type:** Tutorial

## What you will achieve

A running Leptos project in CSR (client-side rendering) mode using Trunk, and optionally a full-stack SSR project using `cargo-leptos`.

## Prerequisites

```bash
rustup target add wasm32-unknown-unknown
cargo install trunk
cargo install cargo-leptos   # for full-stack SSR
```

## Option A: CSR-only project (Trunk / browser only)

### Create the project

```bash
cargo new --lib leptos-csr
cd leptos-csr
```

### Cargo.toml

```toml
[package]
name = "leptos-csr"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
leptos = { version = "0.7", features = ["csr"] }
console_error_panic_hook = "0.1"
```

### src/lib.rs

```rust
use leptos::*;

#[component]
fn App() -> impl IntoView {
    view! {
        <main>
            <h1>"Hello, Leptos!"</h1>
        </main>
    }
}

pub fn main() {
    console_error_panic_hook::set_once();
    mount_to_body(App);
}
```

### index.html

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Leptos App</title>
  <link data-trunk rel="rust" data-wasm-opt="z" />
</head>
<body></body>
</html>
```

### Run

```bash
trunk serve --open
```

## Option B: Full-stack SSR project (cargo-leptos + Axum)

### Create from template

```bash
cargo leptos new --git leptos-rs/start-axum
cd my-app
```

Or manually:
```bash
cargo new my-app
cd my-app
```

### Workspace Cargo.toml

```toml
[workspace]
members = ["frontend", "backend"]

[workspace.dependencies]
leptos = { version = "0.7" }
leptos_router = { version = "0.7" }
leptos_axum = { version = "0.7" }
axum = "0.7"
tokio = { version = "1", features = ["full"] }
```

### Running with cargo-leptos

```bash
# Dev mode with hot reload
cargo leptos watch

# Production build
cargo leptos build --release
```

## Project directory layout (full-stack)

```
my-app/
├── Cargo.toml              # workspace or package
├── Leptos.toml             # cargo-leptos config
├── src/
│   ├── main.rs             # server entry (native)
│   ├── lib.rs              # shared: components, server fns
│   ├── app.rs              # App component + router
│   └── components/
│       └── counter.rs
├── style/
│   └── main.scss
├── public/                 # static assets
└── end2end/                # Playwright tests (optional)
```

## Leptos.toml (cargo-leptos config)

```toml
[package]
name = "my-app"
bin-features = ["ssr"]
lib-features = ["hydrate"]

[package.metadata.leptos]
output-name = "my-app"
site-root = "target/site"
site-pkg-dir = "pkg"
style-file = "style/main.scss"
assets-dir = "public"
site-addr = "127.0.0.1:3000"
reload-port = 3001
browserquery = "defaults"
watch = false
env = "DEV"
bin-default-features = false
lib-default-features = false
```

## Feature flags pattern (SSR vs. CSR)

```toml
[features]
hydrate = ["leptos/hydrate"]  # browser
ssr = ["leptos/ssr", "leptos_axum"]  # server
```

```rust
// Conditional compilation
#[cfg(feature = "ssr")]
async fn server_only_function() { ... }

#[cfg(feature = "hydrate")]
fn client_only_initialization() { ... }
```

This is how the same codebase targets both server and browser.
