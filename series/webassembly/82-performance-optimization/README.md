# 82 — WebAssembly Performance Optimization

> **Type:** How-To + Reference

## The two types of Wasm performance

1. **Binary size** — affects download time (first load latency).
2. **Runtime performance** — execution speed of Wasm code.

Leptos handles most runtime optimizations for you. This lesson focuses on both when you need to go further.

## Binary size checklist

```toml
[profile.release]
opt-level = 'z'       # 'z' = smallest, 's' = small-balanced, 3 = fastest
lto = true            # link-time optimization (crucial for size)
codegen-units = 1     # enables more optimization passes
panic = "abort"       # removes panic unwinding machinery (~10-15KB)
strip = "symbols"     # strip debug symbols from release
```

```bash
# wasm-opt (run after wasm-pack build)
wasm-opt -Oz --strip-debug output.wasm -o output-opt.wasm
```

Typical results:
- Before: 800KB
- After `opt-level = 'z' + lto`: 400KB  
- After `wasm-opt -Oz`: 320KB
- After compression (gzip): 120KB

## Runtime performance: where Wasm excels

Wasm is fast for:
- Pure computation (no DOM, no async).
- Data processing (sorting, parsing, encoding).
- Math (cryptography, simulations, physics).
- Tight loops with predictable types.

Wasm is NOT faster for:
- Simple DOM manipulation (DOM calls cross the Wasm-JS boundary anyway).
- Async I/O (all I/O in browser goes through JS).

## Measuring performance

```rust
#[wasm_bindgen]
pub fn benchmark_sort(data: Vec<i32>) -> f64 {
    let start = js_sys::Date::now();
    let mut data = data;
    data.sort_unstable();
    let end = js_sys::Date::now();
    end - start
}
```

Or use the `performance` API:
```rust
let perf = web_sys::window().unwrap()
    .performance().unwrap();
let t0 = perf.now();
// ... work ...
let elapsed = perf.now() - t0;
web_sys::console::log_1(&format!("Took {:.2}ms", elapsed).into());
```

## Avoiding unnecessary allocations

```rust
// ❌ Allocates new String on every call
pub fn process(data: &[u8]) -> String {
    let decoded = base64_decode(data); // Vec<u8>
    String::from_utf8(decoded).unwrap() // String
}

// ✅ Pre-allocate output buffer
pub fn process_into(data: &[u8], output: &mut Vec<u8>) {
    base64_decode_into(data, output); // writes directly
}
```

## Efficient data passing (avoid copying)

Large data passed between JS and Wasm is copied. For hot paths:

```rust
// ❌ Copies the entire Vec across the boundary
fn process(data: Vec<u8>) -> Vec<u8> { ... }

// ✅ Work on a shared ArrayBuffer — zero copy
use js_sys::{Uint8Array, ArrayBuffer};

#[wasm_bindgen]
pub fn process_in_place(data: &Uint8Array) {
    // Read directly from JS memory
    let len = data.length() as usize;
    for i in 0..len {
        let byte = data.get_index(i as u32);
        // process byte...
    }
}
```

## SIMD optimization (advanced)

WebAssembly SIMD processes 128-bit vectors in one instruction:

```toml
# Enable SIMD target features
[build]
rustflags = ["-C", "target-feature=+simd128"]
```

```rust
// Normal scalar:
pub fn sum(data: &[f32]) -> f32 {
    data.iter().sum()
}

// With auto-vectorization (SIMD):
// The compiler generates SIMD instructions automatically with target-feature=+simd128
```

## Wasm threading (SharedArrayBuffer)

For CPU-bound work that can be parallelized:

```toml
[dependencies]
rayon = "1"
wasm-bindgen-rayon = "1"
```

```rust
use rayon::prelude::*;

#[wasm_bindgen]
pub async fn parallel_process(items: Vec<u64>) -> Vec<u64> {
    // Uses Web Workers under the hood
    items.par_iter()
        .map(|&n| fibonacci(n))
        .collect()
}
```

Requires server headers:
```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```
