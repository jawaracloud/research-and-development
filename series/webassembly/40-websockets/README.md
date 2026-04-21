# 40 — Real-Time Communication with WebSockets

> **Type:** How-To + Tutorial

## Setup

```toml
[dependencies.web-sys]
version = "0.3"
features = [
  "WebSocket", "MessageEvent", "CloseEvent",
  "ErrorEvent", "BinaryType",
]
```

## Opening a connection

```rust
use wasm_bindgen::prelude::*;
use wasm_bindgen::JsCast;
use web_sys::{CloseEvent, ErrorEvent, MessageEvent, WebSocket};

#[wasm_bindgen]
pub fn connect(url: &str) -> WebSocket {
    let ws = WebSocket::new(url).unwrap();

    // Optional: use binary messages as ArrayBuffer (not Blob)
    ws.set_binary_type(web_sys::BinaryType::Arraybuffer);

    // onopen
    let onopen = Closure::wrap(Box::new(move |_event: web_sys::Event| {
        web_sys::console::log_1(&"WebSocket connected!".into());
    }) as Box<dyn FnMut(web_sys::Event)>);
    ws.set_onopen(Some(onopen.as_ref().unchecked_ref()));
    onopen.forget();

    // onmessage
    let onmessage = Closure::wrap(Box::new(move |event: MessageEvent| {
        if let Ok(text) = event.data().dyn_into::<js_sys::JsString>() {
            web_sys::console::log_1(&format!("Received text: {}", text).into());
        } else if let Ok(buffer) = event.data().dyn_into::<js_sys::ArrayBuffer>() {
            use js_sys::Uint8Array;
            let bytes = Uint8Array::new(&buffer).to_vec();
            web_sys::console::log_1(&format!("Received binary: {} bytes", bytes.len()).into());
        }
    }) as Box<dyn FnMut(MessageEvent)>);
    ws.set_onmessage(Some(onmessage.as_ref().unchecked_ref()));
    onmessage.forget();

    // onerror
    let onerror = Closure::wrap(Box::new(move |event: ErrorEvent| {
        web_sys::console::error_1(&format!("WS error: {}", event.message()).into());
    }) as Box<dyn FnMut(ErrorEvent)>);
    ws.set_onerror(Some(onerror.as_ref().unchecked_ref()));
    onerror.forget();

    // onclose
    let onclose = Closure::wrap(Box::new(move |event: CloseEvent| {
        web_sys::console::log_1(
            &format!("WS closed: code={} reason={}", event.code(), event.reason()).into()
        );
    }) as Box<dyn FnMut(CloseEvent)>);
    ws.set_onclose(Some(onclose.as_ref().unchecked_ref()));
    onclose.forget();

    ws
}
```

## Sending messages

```rust
// Send text
ws.send_with_str("Hello, server!").unwrap();

// Send JSON
use serde::Serialize;
#[derive(Serialize)]
struct ChatMessage { user: String, text: String }

let msg = ChatMessage { user: "Alice".into(), text: "Hi!".into() };
let json = serde_json::to_string(&msg).unwrap();
ws.send_with_str(&json).unwrap();

// Send binary
let data: Vec<u8> = vec![1, 2, 3, 4];
let array = js_sys::Uint8Array::from(data.as_slice());
ws.send_with_array_buffer(&array.buffer()).unwrap();
```

## Closing gracefully

```rust
// Normal close (code 1000)
ws.close().unwrap();

// With code and reason
ws.close_with_code_and_reason(1000, "Done").unwrap();
```

## ReadyState values

| Value | Constant | Meaning |
|------|---------|---------|
| 0 | `WebSocket::CONNECTING` | Not yet connected |
| 1 | `WebSocket::OPEN` | Connected |
| 2 | `WebSocket::CLOSING` | Closing handshake |
| 3 | `WebSocket::CLOSED` | Closed |

```rust
if ws.ready_state() == WebSocket::OPEN {
    ws.send_with_str("safe to send").unwrap();
}
```

## gloo-net wrapper (recommended for real apps)

```toml
[dependencies]
gloo-net = { version = "0.6", features = ["websocket"] }
```

```rust
use gloo_net::websocket::{futures::WebSocket, Message};
use futures::StreamExt;
use wasm_bindgen_futures::spawn_local;

spawn_local(async move {
    let (mut write, mut read) = WebSocket::open("wss://echo.websocket.org").unwrap().split();
    
    while let Some(msg) = read.next().await {
        match msg.unwrap() {
            Message::Text(t) => log::info!("Got: {}", t),
            Message::Bytes(b) => log::info!("Got {} bytes", b.len()),
        }
    }
});
```

Much cleaner than raw web-sys for production use.
