# 12 — wasm-pack: Build, Test, Publish Rust-Generated Wasm

> **Type:** Reference + How-To

## What is wasm-pack?

`wasm-pack` is the official Rust tool for building, testing, and publishing Rust-generated WebAssembly packages. It wraps `cargo`, invokes `wasm-bindgen`, optimizes the output, and generates an npm-compatible package.

## Installation

```bash
cargo install wasm-pack
```

Or with the installer script:
```bash
curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh
```

## Core commands

### `wasm-pack build`

Compiles your crate to Wasm and generates a JavaScript + TypeScript package.

```bash
wasm-pack build              # default: --target bundler
wasm-pack build --release    # optimized build
wasm-pack build --target web # standalone, no bundler needed
wasm-pack build --target nodejs  # for Node.js
wasm-pack build --out-dir pkg    # where to put the output
```

### Targets explained

| Target | Use case | How to load |
|--------|----------|------------|
| `bundler` (default) | Webpack, Vite, Rollup | `import init from './pkg'` |
| `web` | Plain HTML, no bundler | `import init from './pkg/module.js'` |
| `nodejs` | Node.js | `require('./pkg')` |
| `no-modules` | Old-style `<script>` tags | Global variable |

### `wasm-pack test`

Runs your Rust tests in a headless browser or Node.js:

```bash
wasm-pack test --headless --firefox
wasm-pack test --headless --chrome
wasm-pack test --node
```

### `wasm-pack publish`

Publishes the generated package to npm:

```bash
wasm-pack login   # authenticate
wasm-pack publish --access=public
```

## Output structure

After `wasm-pack build --target web`, the `pkg/` directory contains:

```
pkg/
├── my_crate.js          # JS glue (handles init, exports)
├── my_crate.d.ts        # TypeScript definitions
├── my_crate_bg.wasm     # The compiled Wasm binary
├── my_crate_bg.wasm.d.ts
└── package.json         # npm-compatible package manifest
```

## Typical Cargo.toml for wasm-pack

```toml
[package]
name = "my-wasm-project"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]  # required for wasm-pack

[dependencies]
wasm-bindgen = "0.2"

[profile.release]
opt-level = "z"      # optimize for size
lto = true           # link-time optimization
codegen-units = 1    # better optimization
```
