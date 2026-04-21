# 88 — SIMD in WebAssembly

> **Type:** Explanation + How-To

## What is SIMD?

**SIMD** (Single Instruction, Multiple Data) is a CPU feature that processes multiple data elements with a single instruction. Instead of adding one pair of numbers at a time, SIMD can add 4-16 pairs simultaneously.

WebAssembly SIMD uses 128-bit lanes:
- `i8x16` — 16 × 8-bit integers
- `i16x8` — 8 × 16-bit integers
- `i32x4` — 4 × 32-bit integers
- `f32x4` — 4 × 32-bit floats
- `f64x2` — 2 × 64-bit floats

## Browser support

WebAssembly SIMD is supported in all modern browsers (Chrome 91+, Firefox 89+, Safari 16.4+).

## Enabling SIMD

```toml
# .cargo/config.toml
[target.wasm32-unknown-unknown]
rustflags = ["-C", "target-feature=+simd128"]
```

Or per-command:
```bash
RUSTFLAGS="-C target-feature=+simd128" cargo build --target wasm32-unknown-unknown --release
```

## Auto-vectorization (easiest path)

With SIMD enabled, the Rust compiler and LLVM often **auto-vectorize** loops:

```rust
// This may auto-vectorize with SIMD target feature
pub fn sum_f32(data: &[f32]) -> f32 {
    data.iter().sum() // Compiled to SIMD instructions automatically
}

pub fn scale(data: &mut [f32], factor: f32) {
    for x in data.iter_mut() {
        *x *= factor;
    }
}

pub fn add_arrays(a: &[f32], b: &[f32], out: &mut [f32]) {
    for i in 0..a.len() {
        out[i] = a[i] + b[i];
    }
}
```

## Explicit SIMD with std::simd (nightly)

On nightly Rust, use portable SIMD:

```rust
#![feature(portable_simd)]
use std::simd::f32x4;

pub fn dot_product_simd(a: &[f32], b: &[f32]) -> f32 {
    assert_eq!(a.len(), b.len());
    let chunks = a.len() / 4;
    
    let mut sum = f32x4::splat(0.0);
    
    for i in 0..chunks {
        let va = f32x4::from_slice(&a[i*4..]);
        let vb = f32x4::from_slice(&b[i*4..]);
        sum += va * vb;
    }
    
    let simd_sum: f32 = sum.reduce_sum();
    
    // Handle remainder
    let remainder: f32 = a[chunks*4..].iter()
        .zip(&b[chunks*4..])
        .map(|(x, y)| x * y)
        .sum();
    
    simd_sum + remainder
}
```

## Using core::arch::wasm32 (explicit intrinsics)

For maximum control, use wasm32 intrinsics directly:

```rust
#[cfg(target_arch = "wasm32")]
use core::arch::wasm32::*;

pub fn multiply_add_simd(a: &[f32; 4], b: &[f32; 4], c: &[f32; 4]) -> [f32; 4] {
    unsafe {
        let va = f32x4(a[0], a[1], a[2], a[3]);
        let vb = f32x4(b[0], b[1], b[2], b[3]);
        let vc = f32x4(c[0], c[1], c[2], c[3]);
        
        // (a * b) + c — fused multiply-add
        let result = f32x4_add(f32x4_mul(va, vb), vc);
        
        [
            f32x4_extract_lane::<0>(result),
            f32x4_extract_lane::<1>(result),
            f32x4_extract_lane::<2>(result),
            f32x4_extract_lane::<3>(result),
        ]
    }
}
```

## Real-world use case: Image processing

```rust
pub fn grayscale(rgba: &mut [u8]) {
    // Process 4 pixels at a time (each pixel = 4 bytes RGBA)
    let chunks = rgba.chunks_exact_mut(16); // 4 pixels × 4 bytes

    for chunk in chunks {
        // For each pixel: gray = 0.299*R + 0.587*G + 0.114*B
        for pixel in chunk.chunks_exact_mut(4) {
            let gray = (pixel[0] as f32 * 0.299
                + pixel[1] as f32 * 0.587
                + pixel[2] as f32 * 0.114) as u8;
            pixel[0] = gray;
            pixel[1] = gray;
            pixel[2] = gray;
        }
    }
}

// With SIMD target feature enabled, LLVM may auto-vectorize the above
```

## Benchmarking

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn benchmark() -> js_sys::Object {
    let data: Vec<f32> = (0..1_000_000).map(|i| i as f32).collect();

    let perf = web_sys::window().unwrap().performance().unwrap();

    let t0 = perf.now();
    let sum_scalar: f32 = data.iter().sum();
    let t1 = perf.now();
    
    web_sys::console::log_2(
        &format!("Scalar sum: {} in {:.2}ms", sum_scalar, t1 - t0).into(),
        &"".into(),
    );

    js_sys::Object::new()
}
```

Compare results in browser DevTools to measure speedup from SIMD.
