# 87 — Wasm Threads with SharedArrayBuffer

> **Type:** Explanation + How-To

## Prerequisites

Wasm threads require:
1. `SharedArrayBuffer` support (all modern browsers).
2. Two HTTP headers (for cross-origin isolation):
   ```
   Cross-Origin-Opener-Policy: same-origin
   Cross-Origin-Embedder-Policy: require-corp
   ```
3. Wasm compiled with threads flag.

## Build configuration

```toml
# .cargo/config.toml
[target.wasm32-unknown-unknown]
rustflags = ["-C", "target-feature=+atomics,+bulk-memory,+mutable-globals"]

[unstable]
build-std = ["panic_abort", "std"]
```

Build:
```bash
RUSTFLAGS="-C target-feature=+atomics,+bulk-memory,+mutable-globals" \
  cargo build --target wasm32-unknown-unknown --release \
  -Z build-std=std,panic_abort
```

## Setting up the server headers

**Axum:**
```rust
use axum::http::{header, HeaderValue};

let app = Router::new()
    // ...
    .layer(
        tower_http::set_header::SetResponseHeaderLayer::if_not_present(
            header::HeaderName::from_static("cross-origin-opener-policy"),
            HeaderValue::from_static("same-origin"),
        )
    )
    .layer(
        tower_http::set_header::SetResponseHeaderLayer::if_not_present(
            header::HeaderName::from_static("cross-origin-embedder-policy"),
            HeaderValue::from_static("require-corp"),
        )
    );
```

**Nginx:**
```nginx
add_header Cross-Origin-Opener-Policy same-origin;
add_header Cross-Origin-Embedder-Policy require-corp;
```

## Using rayon for parallel computation

```toml
[dependencies]
rayon = "1"
wasm-bindgen-rayon = "1"
```

```rust
use leptos::*;
use rayon::prelude::*;
use wasm_bindgen::prelude::*;
use wasm_bindgen_rayon::init_thread_pool;

#[wasm_bindgen(start)]
pub async fn start() {
    // Initialize thread pool (uses navigator.hardwareConcurrency threads)
    init_thread_pool(web_sys::window().unwrap()
        .navigator().hardware_concurrency() as usize)
        .await;

    leptos::mount_to_body(App);
}

#[wasm_bindgen]
pub fn parallel_fibonacci(n: u64) -> Vec<u64> {
    (0..n).into_par_iter()
        .map(|i| fib(i))
        .collect()
}

fn fib(n: u64) -> u64 {
    if n <= 1 { return n; }
    let mut a = 0u64;
    let mut b = 1u64;
    for _ in 2..=n {
        let c = a + b;
        a = b;
        b = c;
    }
    b
}
```

## Manual thread spawning with web-sys

```rust
use web_sys::Worker;
use wasm_bindgen::JsCast;

// Create a worker from a JS URL
let worker = Worker::new("./compute_worker.js").unwrap();

// Post data
worker.post_message(&JsValue::from(42.0)).unwrap();

// Receive result
let on_message = Closure::wrap(Box::new(move |event: web_sys::MessageEvent| {
    let result = event.data().as_f64().unwrap();
    web_sys::console::log_1(&format!("Result: {}", result).into());
}) as Box<dyn FnMut(web_sys::MessageEvent)>);

worker.set_onmessage(Some(on_message.as_ref().unchecked_ref()));
on_message.forget();
```

## Shared memory with SharedArrayBuffer

```rust
use js_sys::{SharedArrayBuffer, Int32Array};

// Create shared memory (must have COOP/COEP headers)
let buffer = SharedArrayBuffer::new(1024);
let view = Int32Array::new(&buffer);

// Write from one context
view.set_index(0, 42);

// Pass buffer to worker — it shares the same memory
worker.post_message(&buffer).unwrap();
```

## Atomics for synchronization

```rust
use js_sys::Atomics;

// Atomic store (thread-safe write)
Atomics::store(&view, 0, 1).unwrap();

// Atomic read
let val = Atomics::load(&view, 0).unwrap();

// Atomic compare-and-swap
let old = Atomics::compare_exchange(&view, 0, 1, 2).unwrap();
```

## Performance expectations

| Task | Single thread | 4 threads | 8 threads |
|------|--------------|-----------|-----------|
| SHA-256 1M iterations | 1000ms | 260ms | 140ms |
| Image convolution 4K | 800ms | 210ms | 115ms |
| Sort 10M items | 500ms | 145ms | 85ms |

Thread scaling is near-linear for compute-bound tasks with no shared mutable state.
