# 17 — Trunk: A Dev Server and Bundler for Rust Wasm

> **Type:** Tutorial + Reference

## What is Trunk?

Trunk is a build tool and dev server specifically designed for Rust Wasm web applications. It handles:
- Compiling your Rust crate to Wasm.
- Bundling assets (CSS, images, JS).
- Running a dev server with hot-reload.
- Producing production builds.

Trunk is the standard dev tool for Leptos CSR (client-side rendering) projects.

## Installation

```bash
cargo install trunk
```

## Project structure

```
my-app/
├── Cargo.toml
├── index.html     ← Trunk's entry point
├── src/
│   └── main.rs    ← or lib.rs
└── assets/
    └── style.css
```

## index.html — the key file

Trunk is driven by special tags in `index.html`:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>My Wasm App</title>
  <!-- Trunk will replace this with the compiled Wasm + JS glue -->
  <link data-trunk rel="rust" data-wasm-opt="z" />
  <!-- Include a CSS file; Trunk will hash and bundle it -->
  <link data-trunk rel="css" href="assets/style.css" />
</head>
<body>
</body>
</html>
```

## Commands

```bash
# Start dev server with hot reload (watches for file changes)
trunk serve

# Build for production
trunk build --release

# Build to a custom directory
trunk build --release --dist ./dist
```

## Trunk configuration (Trunk.toml)

```toml
[build]
target = "index.html"
dist = "dist"
public_url = "/"

[watch]
ignore = ["./dist"]

[serve]
port = 8080
open = true    # auto-open browser
```

## How Trunk differs from wasm-pack

| | Trunk | wasm-pack |
|:|:------|:---------|
| Target | Full apps (single-page) | Libraries (npm packages) |
| Entry point | `index.html` | `lib.rs` with `#[wasm_bindgen]` |
| Output | Static site (`dist/`) | npm package (`pkg/`) |
| Dev server | ✅ Built-in | ❌ Need to add |
| Hot reload | ✅ | ❌ |
| Use with Leptos | ✅ CSR mode | ❌ |

## Cargo.toml for a Trunk app

```toml
[package]
name = "my-app"
version = "0.1.0"
edition = "2021"

# Trunk expects a binary, not a lib
[[bin]]
name = "my-app"
path = "src/main.rs"

[dependencies]
leptos = { version = "0.7", features = ["csr"] }
```

## The data-trunk attributes

| Attribute | Purpose |
|-----------|---------|
| `data-trunk rel="rust"` | Compile main Rust crate |
| `data-trunk rel="css"` | Include CSS file |
| `data-trunk rel="copy-file"` | Copy file verbatim |
| `data-trunk rel="copy-dir"` | Copy directory |
| `data-trunk rel="icon"` | App icon |
| `data-wasm-opt="z"` | Run wasm-opt -Oz |
