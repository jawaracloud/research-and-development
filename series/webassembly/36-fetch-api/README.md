# 36 — Making HTTP Requests with the Fetch API

> **Type:** How-To

## Setup

```toml
[dependencies]
wasm-bindgen = "0.2"
wasm-bindgen-futures = "0.4"
serde = { version = "1", features = ["derive"] }
serde-wasm-bindgen = "0.6"
js-sys = "0.3"

[dependencies.web-sys]
version = "0.3"
features = [
  "Window", "Request", "RequestInit", "RequestMode",
  "Response", "Headers",
]
```

## Simple GET request

```rust
use wasm_bindgen::prelude::*;
use wasm_bindgen_futures::JsFuture;
use web_sys::{Request, RequestInit, RequestMode, Response};

#[wasm_bindgen]
pub async fn fetch_get(url: String) -> Result<JsValue, JsValue> {
    let window = web_sys::window().unwrap();

    // Build request
    let mut opts = RequestInit::new();
    opts.method("GET");
    opts.mode(RequestMode::Cors);
    let request = Request::new_with_str_and_init(&url, &opts)?;

    // Await the fetch
    let response_value = JsFuture::from(window.fetch_with_request(&request)).await?;
    let response: Response = response_value.dyn_into()?;

    // Check status
    if !response.ok() {
        return Err(JsValue::from_str(&format!(
            "HTTP error: {}", response.status()
        )));
    }

    // Parse response body as JSON
    let json = JsFuture::from(response.json()?).await?;
    Ok(json)
}
```

## Deserializing into a Rust struct

```rust
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct Post {
    pub id: u32,
    pub title: String,
    pub body: String,
}

#[wasm_bindgen]
pub async fn fetch_post(id: u32) -> Result<JsValue, JsValue> {
    let url = format!("https://jsonplaceholder.typicode.com/posts/{}", id);
    let json = fetch_get(url).await?;
    
    let post: Post = serde_wasm_bindgen::from_value(json)
        .map_err(|e| JsValue::from_str(&e.to_string()))?;
    
    web_sys::console::log_1(&format!("Post: {:?}", post).into());

    // Return as JsValue so JS can use it
    serde_wasm_bindgen::to_value(&post).map_err(|e| JsValue::from_str(&e.to_string()))
}
```

## POST request with JSON body

```rust
use serde::Serialize;
use js_sys::JSON;

#[derive(Serialize)]
struct NewPost {
    title: String,
    body: String,
    user_id: u32,
}

#[wasm_bindgen]
pub async fn create_post(title: String, body: String) -> Result<JsValue, JsValue> {
    let payload = NewPost { title, body, user_id: 1 };
    let json_str = serde_json::to_string(&payload)
        .map_err(|e| JsValue::from_str(&e.to_string()))?;

    let mut opts = RequestInit::new();
    opts.method("POST");
    opts.mode(RequestMode::Cors);
    opts.body(Some(&JsValue::from_str(&json_str)));

    let request = Request::new_with_str_and_init(
        "https://jsonplaceholder.typicode.com/posts",
        &opts,
    )?;
    request.headers().set("Content-Type", "application/json")?;

    let window = web_sys::window().unwrap();
    let response: Response = JsFuture::from(window.fetch_with_request(&request))
        .await?
        .dyn_into()?;

    JsFuture::from(response.json()?).await
}
```

## Using reqwest (simpler alternative)

The `reqwest` crate supports Wasm and has a much more ergonomic API:

```toml
[dependencies]
reqwest = { version = "0.12", features = ["json"] }
tokio = { version = "1", features = ["rt"] }
```

```rust
#[wasm_bindgen]
pub async fn fetch_with_reqwest(url: String) -> Result<JsValue, JsValue> {
    let data: serde_json::Value = reqwest::get(&url)
        .await
        .map_err(|e| JsValue::from_str(&e.to_string()))?
        .json()
        .await
        .map_err(|e| JsValue::from_str(&e.to_string()))?;
    
    serde_wasm_bindgen::to_value(&data)
        .map_err(|e| JsValue::from_str(&e.to_string()))
}
```

`reqwest` is preferred for real applications — it handles cookies, auth headers, timeout, and retry patterns.
