# 21 — The js-sys Crate: Calling JavaScript Built-ins from Rust

> **Type:** Reference + How-To

## What is js-sys?

`js-sys` provides Rust bindings for all JavaScript built-in objects and functions — the standard library of JavaScript, accessible from Rust code in Wasm.

```toml
[dependencies]
js-sys = "0.3"
```

## What it covers

`js-sys` binds everything that is part of the ECMAScript specification (not browser-specific):

| JS Global | js-sys type |
|-----------|------------|
| `Array` | `js_sys::Array` |
| `Object` | `js_sys::Object` |
| `Map` | `js_sys::Map` |
| `Set` | `js_sys::Set` |
| `Promise` | `js_sys::Promise` |
| `Date` | `js_sys::Date` |
| `JSON` | `js_sys::JSON` functions |
| `Math` | `js_sys::Math` functions |
| `Error` | `js_sys::Error` |
| `ArrayBuffer` | `js_sys::ArrayBuffer` |
| `Uint8Array`, `Float32Array`, etc. | `js_sys::Uint8Array`, etc. |
| `Function` | `js_sys::Function` |
| `Reflect` | `js_sys::Reflect` |

## Common usage examples

### Working with JavaScript Arrays

```rust
use js_sys::Array;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn sum_array(arr: &Array) -> f64 {
    let mut total = 0.0;
    for i in 0..arr.length() {
        if let Some(val) = arr.get(i).as_f64() {
            total += val;
        }
    }
    total
}

#[wasm_bindgen]
pub fn make_array() -> Array {
    let arr = Array::new();
    arr.push(&JsValue::from(1));
    arr.push(&JsValue::from(2));
    arr.push(&JsValue::from(3));
    arr
}
```

### Working with Math

```rust
use js_sys::Math;

let random = Math::random();          // f64 in [0, 1)
let sqrt = Math::sqrt(2.0_f64);       // 1.4142...
let max = Math::max(3.0, 5.0, 1.0);  // 5.0
```

### Using JSON

```rust
use js_sys::JSON;
use wasm_bindgen::JsValue;

// Serialize a JsValue to a JSON string
let obj = JsValue::from_str(r#"{"name":"Alice"}"#);
let json_str = JSON::stringify(&obj).unwrap();
```

### Working with typed arrays (zero-copy!)

```rust
use js_sys::Uint8Array;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn process_bytes(data: &Uint8Array) -> Uint8Array {
    // View the JS ArrayBuffer's bytes directly from Rust
    let bytes = data.to_vec();
    let processed: Vec<u8> = bytes.iter().map(|b| b.wrapping_add(1)).collect();
    Uint8Array::from(processed.as_slice())
}
```

### Getting the current timestamp

```rust
use js_sys::Date;

let now_ms = Date::now() as u64;  // milliseconds since epoch
let date = Date::new_0();
let year = date.get_full_year();
```

## Tip: combining js-sys and web-sys

- **`js-sys`** — ECMAScript built-ins (Array, Promise, Map, Date, Math)
- **`web-sys`** — Browser APIs (Window, Document, Element, Fetch, Canvas)

They complement each other. Import from the right one to keep your code clean.
