# 26 — Promises in JS ↔ Futures in Rust (wasm-bindgen-futures)

> **Type:** How-To + Explanation

## The async story

JavaScript uses `Promise` for async operations. Rust uses `Future`. The `wasm-bindgen-futures` crate bridges the two, letting you:
- Call JS `Promise`-returning APIs from Rust `async` functions.
- Expose Rust `async fn` to JavaScript as `Promise`-returning functions.

```toml
[dependencies]
wasm-bindgen = "0.2"
wasm-bindgen-futures = "0.4"
```

## Exposing an async Rust function to JavaScript

```rust
use wasm_bindgen::prelude::*;
use wasm_bindgen_futures::JsFuture;
use web_sys::{Request, RequestInit, RequestMode, Response};

#[wasm_bindgen]
pub async fn fetch_json(url: String) -> Result<JsValue, JsValue> {
    let mut opts = RequestInit::new();
    opts.method("GET");
    opts.mode(RequestMode::Cors);

    let request = Request::new_with_str_and_init(&url, &opts)?;
    let window = web_sys::window().unwrap();

    // window.fetch() returns a Promise — JsFuture bridges it to Rust
    let resp_value = JsFuture::from(window.fetch_with_request(&request)).await?;

    // Cast to Response
    let resp: Response = resp_value.dyn_into()?;

    // resp.json() also returns a Promise
    let json = JsFuture::from(resp.json()?).await?;

    Ok(json)
}
```

JavaScript usage:
```javascript
const data = await fetch_json("https://api.example.com/users");
console.log(data);
```

Note: `async fn` exported via `#[wasm_bindgen]` automatically becomes a JS `async function` returning a `Promise`.

## Converting a JS Promise to a Rust Future

```rust
use wasm_bindgen_futures::JsFuture;
use js_sys::Promise;

async fn wait_for_promise(promise: Promise) -> Result<JsValue, JsValue> {
    JsFuture::from(promise).await
}
```

## Spawning a Future (fire and forget)

When you want to start async work without `await`:

```rust
use wasm_bindgen_futures::spawn_local;

#[wasm_bindgen]
pub fn start_background_work() {
    spawn_local(async {
        // This runs concurrently on the JS event loop
        let window = web_sys::window().unwrap();
        let promise = window.fetch_with_str("https://api.example.com/data");
        let _ = JsFuture::from(promise).await;
        web_sys::console::log_1(&"Background fetch done".into());
    });
}
```

`spawn_local` is the Wasm equivalent of `tokio::spawn` for the browser's single-threaded event loop.

## The execution model

Wasm in the browser is **single-threaded** (unless using Web Workers). `spawn_local` does not create a new thread — it queues the future onto the JS microtask queue. Futures run cooperatively:
- Your future runs until the first `.await`.
- It suspends, the event loop handles other tasks.
- When the awaited value is ready, your future resumes.

## Async in Leptos

Leptos has its own async primitives (`create_resource`, `Action`) that build on `wasm-bindgen-futures` internally. You will rarely use `spawn_local` directly when using Leptos, but understanding it helps when debugging async issues.
