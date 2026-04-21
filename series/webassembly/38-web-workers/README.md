# 38 — Running Wasm Inside Web Workers

> **Type:** Explanation + How-To

## Why Web Workers?

WebAssembly in the main browser thread *can* block the UI — a Wasm function that takes 500ms to compute will freeze the page for 500ms. Web Workers run on separate threads, so heavy computation doesn't interrupt the user experience.

## Architecture

```
Main thread (UI)              Worker thread
     │                              │
     │ postMessage(data) ─────────► │
     │                         [Wasm compute]
     │ ◄─────────── postMessage(result)
     │
  Update DOM
```

## Setting up a Web Worker with Wasm

### Step 1: Build your Wasm for the `no-modules` target

```bash
wasm-pack build --target no-modules --out-dir pkg
```

This produces a `mylib.js` that doesn't use ES module syntax — required inside Workers.

### Step 2: Worker script (`worker.js`)

```javascript
// Import the no-modules Wasm glue
importScripts('./pkg/mylib.js');

// Initialize Wasm
const { wasm_compute } = wasm_bindgen;

async function init() {
    await wasm_bindgen('./pkg/mylib_bg.wasm');

    self.onmessage = (event) => {
        const { data } = event;
        const result = wasm_compute(data.input);
        self.postMessage({ result });
    };
}

init();
```

### Step 3: Main thread code

```javascript
const worker = new Worker('./worker.js');

worker.onmessage = (event) => {
    console.log('Result:', event.data.result);
    document.getElementById('output').textContent = event.data.result;
};

document.getElementById('compute-btn').addEventListener('click', () => {
    worker.postMessage({ input: 42 });
});
```

## Using wasm-bindgen Workers from Rust directly

The `wasm-bindgen` team provides `wasm-bindgen-rayon` for parallel computation using Wasm threads (requires `SharedArrayBuffer` + COOP/COEP headers):

```toml
[dependencies]
rayon = "1"
wasm-bindgen-rayon = "1"
```

```rust
use wasm_bindgen::prelude::*;
use wasm_bindgen_rayon::init_thread_pool;

#[wasm_bindgen]
pub async fn setup(threads: usize) {
    init_thread_pool(threads).await;
}

#[wasm_bindgen]
pub fn parallel_sum(data: Vec<f64>) -> f64 {
    use rayon::prelude::*;
    data.par_iter().sum()
}
```

## SharedArrayBuffer requirements

Using `SharedArrayBuffer` (needed for Wasm threads) requires the server to send two HTTP headers:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

## Alternatives: gloo-worker

`gloo-worker` provides a typed, ergonomic API for Rust-to-Rust Worker communication:

```toml
[dependencies]
gloo-worker = "0.5"
```

Define the worker:
```rust
use gloo_worker::{Worker, WorkerBridge};
use serde::{Deserialize, Serialize};

pub struct MyWorker;

impl Worker for MyWorker {
    type Input = u64;
    type Output = u64;

    fn create(_scope: &WorkerScope<Self>) -> Self { MyWorker }
    fn update(&mut self, scope: &WorkerScope<Self>, msg: Self::Input) {
        let result = fibonacci(msg);
        scope.respond(result);
    }
}
```

This is like a typed actor model for the browser.
