# 14 — Configuring Cargo.toml for Wasm Projects

> **Type:** Reference

## The minimal Cargo.toml

```toml
[package]
name = "my-wasm-lib"
version = "0.1.0"
edition = "2021"

# Required: cdylib produces a .wasm file
# rlib keeps it usable as a Rust library locally
[lib]
crate-type = ["cdylib", "rlib"]

[dependencies]
wasm-bindgen = "0.2"
```

## Key settings explained

### `crate-type`

| Type | When to use |
|------|------------|
| `cdylib` | Required for Wasm output. Produces a dynamic library (`.wasm`). |
| `rlib` | Lets you use the crate as a dependency in other Rust code. |
| `bin` | A binary — not for Wasm libraries. |

If you are building a full Leptos app with Trunk, you typically use a `[[bin]]` target, not a `[lib]`.

### Dependencies for Wasm projects

```toml
[dependencies]
wasm-bindgen = "0.2"
js-sys = "0.3"
serde = { version = "1", features = ["derive"] }
serde-wasm-bindgen = "0.6"
console_error_panic_hook = "0.1"

[dependencies.web-sys]
version = "0.3"
features = [
  "Window",
  "Document",
  "Element",
  "HtmlElement",
  "console",
]
```

> `web-sys` uses Cargo features to opt-in each Web API — this keeps binary size down.

### Profile settings for release

```toml
[profile.release]
opt-level = "z"      # "z" = smallest binary, "s" = balance size/speed
lto = true           # Link-time optimization (big size reduction)
codegen-units = 1    # Single codegen unit for best LTO
panic = "abort"      # Don't include unwinding code (saves ~10-20%)
strip = true         # Strip debug symbols
```

### Reduce allocator size with wee_alloc

```toml
[dependencies]
wee_alloc = "0.4"
```

In `lib.rs`:
```rust
#[global_allocator]
static ALLOC: wee_alloc::WeeAlloc = wee_alloc::WeeAlloc::INIT;
```

> Note: `wee_alloc` is unmaintained. For Leptos apps, the default allocator with `opt-level = "z"` usually produces acceptable output.

### Workspace for full-stack Leptos apps

```toml
# Workspace Cargo.toml (root)
[workspace]
members = ["frontend", "backend", "shared"]

[workspace.dependencies]
leptos = { version = "0.7", features = ["nightly"] }
leptos_router = { version = "0.7" }
serde = { version = "1", features = ["derive"] }
```

## Common gotchas

- Forgetting `crate-type = ["cdylib"]` → Wasm file is not produced.
- Including `std` features that don't compile to `wasm32-unknown-unknown` (e.g., filesystem I/O, threads without atomics).
- Adding too many `web-sys` features → binary gets large. Only enable what you use.
