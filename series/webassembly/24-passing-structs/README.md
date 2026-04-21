# 24 — Passing Complex Data Structures (Serde + JsValue)

> **Type:** How-To

## The problem

Wasm can't pass arbitrary structs directly across the boundary. You have two main strategies:

1. **Serde + JSON** — serialize to a JSON string, pass the string.
2. **serde-wasm-bindgen** — serialize directly to `JsValue` (more efficient, no JSON overhead).

## Strategy 1: Serde + JSON (simplest)

```toml
[dependencies]
serde = { version = "1", features = ["derive"] }
serde_json = "1"
wasm-bindgen = "0.2"
```

```rust
use serde::{Deserialize, Serialize};
use wasm_bindgen::prelude::*;

#[derive(Serialize, Deserialize)]
pub struct User {
    pub name: String,
    pub age: u32,
    pub active: bool,
}

// Receive a JSON string from JS, deserialize, process, return JSON string
#[wasm_bindgen]
pub fn process_user(json: &str) -> String {
    let user: User = serde_json::from_str(json).unwrap();
    let updated = User {
        name: user.name.to_uppercase(),
        age: user.age + 1,
        active: user.active,
    };
    serde_json::to_string(&updated).unwrap()
}
```

JavaScript:
```javascript
const user = { name: "Alice", age: 30, active: true };
const result = JSON.parse(process_user(JSON.stringify(user)));
console.log(result); // { name: "ALICE", age: 31, active: true }
```

## Strategy 2: serde-wasm-bindgen (recommended)

Skips JSON string intermediary — serializes Rust structs directly to/from JavaScript objects.

```toml
[dependencies]
serde = { version = "1", features = ["derive"] }
serde-wasm-bindgen = "0.6"
wasm-bindgen = "0.2"
```

```rust
use serde::{Deserialize, Serialize};
use wasm_bindgen::prelude::*;

#[derive(Serialize, Deserialize)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

// Receive a JS object, deserialize to Rust struct
#[wasm_bindgen]
pub fn distance(a: JsValue, b: JsValue) -> f64 {
    let a: Point = serde_wasm_bindgen::from_value(a).unwrap();
    let b: Point = serde_wasm_bindgen::from_value(b).unwrap();
    ((a.x - b.x).powi(2) + (a.y - b.y).powi(2)).sqrt()
}

// Return a Rust struct as a JS object
#[wasm_bindgen]
pub fn midpoint(a: JsValue, b: JsValue) -> JsValue {
    let a: Point = serde_wasm_bindgen::from_value(a).unwrap();
    let b: Point = serde_wasm_bindgen::from_value(b).unwrap();
    let mid = Point { x: (a.x + b.x) / 2.0, y: (a.y + b.y) / 2.0 };
    serde_wasm_bindgen::to_value(&mid).unwrap()
}
```

JavaScript:
```javascript
const dist = distance({ x: 0, y: 0 }, { x: 3, y: 4 });
console.log(dist); // 5.0
const mid = midpoint({ x: 0, y: 0 }, { x: 4, y: 6 });
console.log(mid);  // { x: 2, y: 3 }
```

## Passing arrays

```rust
#[wasm_bindgen]
pub fn sum_numbers(values: JsValue) -> f64 {
    let nums: Vec<f64> = serde_wasm_bindgen::from_value(values).unwrap();
    nums.iter().sum()
}
```

```javascript
console.log(sum_numbers([1.0, 2.0, 3.0])); // 6.0
```

## Strategy comparison

| | JSON string | serde-wasm-bindgen |
|:|:------------|:------------------|
| Performance | ❌ double encode | ✅ direct |
| Bundle overhead | ❌ serde_json is large | ✅ smaller |
| JS object → Rust | ❌ manual JSON.stringify | ✅ native |
| Debugging | ✅ readable JSON logs | ⚠️ JsValue opaque |

Prefer `serde-wasm-bindgen` unless you specifically need the JSON string format.
