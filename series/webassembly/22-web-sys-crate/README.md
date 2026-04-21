# 22 — The web-sys Crate: Browser APIs in Rust

> **Type:** Reference + How-To

## What is web-sys?

`web-sys` provides Rust bindings to all Web APIs defined by the W3C and WHATWG — everything from the DOM to `fetch`, `WebSocket`, `Canvas`, `WebGL`, `AudioContext`, and more.

Unlike `js-sys` (ECMAScript), `web-sys` covers browser-specific APIs.

## Installation

```toml
[dependencies.web-sys]
version = "0.3"
features = [
  # Only enable what you use — each feature adds to binary size
  "Window",
  "Document",
  "Element",
  "HtmlElement",
  "HtmlInputElement",
  "Node",
  "EventTarget",
  "console",
]
```

> Every API in `web-sys` requires a Cargo feature. This is by design to keep binaries small.

## How to discover the feature name

The feature name is always the interface name from the Web API spec:
- `window.document` → feature `"Document"`, type `web_sys::Document`
- `<canvas>` → feature `"HtmlCanvasElement"`, type `web_sys::HtmlCanvasElement`
- `new WebSocket(...)` → feature `"WebSocket"`, type `web_sys::WebSocket`

Look them up at: https://rustwasm.github.io/wasm-bindgen/api/web_sys/

## Common patterns

### Get the window and document

```rust
use web_sys::{window, Document, Window};

fn get_window() -> Window {
    web_sys::window().expect("no global `window` exists")
}

fn get_document() -> Document {
    get_window()
        .document()
        .expect("should have a document on window")
}
```

### Query an element

```rust
use web_sys::HtmlElement;
use wasm_bindgen::JsCast;

let el = get_document()
    .get_element_by_id("my-button")
    .unwrap()
    .dyn_into::<HtmlElement>()  // downcast to concrete type
    .unwrap();
```

> `dyn_into` is how you downcast `Element` to `HtmlElement`, `HtmlInputElement`, etc.
> It comes from `wasm_bindgen::JsCast`.

### Create and append elements

```rust
use web_sys::Element;

let doc = get_document();
let div = doc.create_element("div").unwrap();
div.set_text_content(Some("Hello!");
doc.body().unwrap().append_child(&div).unwrap();
```

### Read input value

```rust
use web_sys::HtmlInputElement;
use wasm_bindgen::JsCast;

let input = get_document()
    .get_element_by_id("name-input")
    .unwrap()
    .dyn_into::<HtmlInputElement>()
    .unwrap();

let value = input.value();  // String
```

## The Result pattern

Almost every `web-sys` method returns a `Result<T, JsValue>`. Use `.unwrap()` during learning but handle errors properly in production:

```rust
let el = doc.get_element_by_id("missing").ok_or("element not found")?;
```

## Feature reference by category

| Category | Key features |
|---------|-------------|
| Core DOM | `Window`, `Document`, `Element`, `Node`, `HtmlElement` |
| Forms | `HtmlInputElement`, `HtmlFormElement`, `HtmlSelectElement` |
| Canvas | `HtmlCanvasElement`, `CanvasRenderingContext2d`, `WebGlRenderingContext` |
| Network | `Request`, `Response`, `Headers`, `AbortController` |
| Storage | `Storage`, `IdbFactory` |
| Realtime | `WebSocket`, `MessageEvent`, `CloseEvent` |
| Workers | `Worker`, `DedicatedWorkerGlobalScope` |
| Audio | `AudioContext`, `AudioNode`, `GainNode` |
| File | `File`, `FileReader`, `FileList`, `Blob` |
| History | `History`, `Location` |
