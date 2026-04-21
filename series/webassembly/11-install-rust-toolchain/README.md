# 11 — Installing Rust and the wasm32 Target

> **Type:** Tutorial

## What you will achieve

By the end of this lesson you will have a working Rust installation capable of compiling to WebAssembly.

## Step 1 — Install Rust via rustup

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Follow the prompts (default installation is fine). Then reload your shell:

```bash
source $HOME/.cargo/env
```

Verify:
```bash
rustc --version   # e.g., rustc 1.78.0
cargo --version   # e.g., cargo 1.78.0
```

## Step 2 — Add the WebAssembly target

Rust can compile to many targets. The one we need for browser Wasm is:

```bash
rustup target add wasm32-unknown-unknown
```

- `wasm32` — 32-bit WebAssembly
- `unknown` (OS) — no operating system
- `unknown` (env) — no specific environment (not WASI, not WASM)

For WASI (server-side Wasm):
```bash
rustup target add wasm32-wasi
```

Verify your installed targets:
```bash
rustup target list --installed
```

## Step 3 — Keep Rust up to date

```bash
rustup update
```

Run this periodically. Wasm tooling evolves quickly and newer compiler versions often produce smaller or faster Wasm output.

## Step 4 — Install essential tools

```bash
# wasm-pack: the primary build tool for browser Wasm
cargo install wasm-pack

# trunk: dev server for single-page Wasm apps (covered in lesson 17)
cargo install trunk

# cargo-leptos: Leptos project CLI (covered in lesson 52)
cargo install cargo-leptos
```

## Verify everything

```bash
rustup target list --installed | grep wasm
wasm-pack --version
trunk --version
```

## Troubleshooting

| Issue | Solution |
|-------|---------|
| `command not found: cargo` | Run `source $HOME/.cargo/env` or add `~/.cargo/bin` to `$PATH` |
| `wasm-pack build` fails on Linux | Install `pkg-config`, `libssl-dev`: `sudo apt install pkg-config libssl-dev` |
| Compilation errors about `std` | Use `wasm32-unknown-unknown` target, not a native target |
| Linker errors | Install `lld`: `sudo apt install lld` or use `wasm-pack` which bundles its own linker |
