# 16 — Optimizing Wasm Binary Size with wasm-opt

> **Type:** How-To

## Why size matters

Wasm binaries must be downloaded before they can run. A 5 MB binary blocks first load for 2–3 seconds on a mobile connection. Optimization is not optional for production.

## The optimization stack

```
rustc release build
    → wasm-bindgen
        → wasm-opt (Binaryen)
            → compressed with Brotli/gzip on the server
```

Each step reduces size independently.

## Step 1 — Use release profile settings

`Cargo.toml`:
```toml
[profile.release]
opt-level = "z"      # size-first optimization
lto = true
codegen-units = 1
panic = "abort"      # removes unwinding code
strip = true
```

`wasm-pack build --release` automatically uses the release profile.

## Step 2 — Run wasm-opt manually

`wasm-opt` is the optimizer from the Binaryen toolkit.

```bash
# Install Binaryen
sudo apt install binaryen     # Ubuntu/Debian
brew install binaryen          # macOS

# Optimize for size
wasm-opt -Oz -o output.wasm input.wasm

# Optimize for speed
wasm-opt -O3 -o output.wasm input.wasm

# Optimize for both (typical production setting)
wasm-opt -O2 -o output.wasm input.wasm
```

`wasm-pack` runs `wasm-opt` automatically in release mode if Binaryen is installed.

## Step 3 — Analyze what is taking space

Use `twiggy` to see which functions are largest:

```bash
cargo install twiggy

twiggy top path/to/module.wasm
twiggy paths path/to/module.wasm
twiggy garbage path/to/module.wasm  # find dead code
```

Example output:
```
 Shallow Bytes │ Shallow % │ Item
───────────────┼───────────┼───────────────────────
         45230 │    32.40% │ data[0]
         12842 │     9.20% │ "fmt" machinery (formatting)
          8120 │     5.82% │ panic handling
```

## Common size savers

| Technique | Size saving |
|-----------|------------|
| `opt-level = "z"` in release | 20–40% |
| `lto = true` and `codegen-units = 1` | 10–30% |
| `panic = "abort"` | ~10% |
| Remove unused `web-sys` features | varies |
| Avoid `format!` / `{}` in hot paths | ~5–15% (fmt is big) |
| Use `wee_alloc` (older approach) | ~10 KB |
| Serve with Brotli compression | 60–80% transfer reduction |

## How wasm-pack integrates wasm-opt

`wasm-pack build --release` automatically calls `wasm-opt -O` if Binaryen is installed on your PATH. You can customize this in `.wasm-pack.toml`:

```toml
[wasm-opt]
level = "z"          # -Oz: optimize for size
enable-simd = false  # disable SIMD proposals
```

## Realistic size targets

| App type | Unoptimized | Optimized | Gzipped |
|---------|------------|----------|--------|
| Hello World | ~2 MB | ~20 KB | ~10 KB |
| Todo App | ~3 MB | ~100 KB | ~40 KB |
| Full Leptos App | ~5 MB | ~500 KB | ~150 KB |
