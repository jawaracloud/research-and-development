# 13 — wasm-bindgen: Bridging Rust and JavaScript

> **Type:** Explanation + Reference

## What is wasm-bindgen?

`wasm-bindgen` is the Rust crate (and accompanying CLI tool) that makes it possible to work with rich JavaScript types from Rust. Raw Wasm only understands numbers (`i32`, `i64`, `f32`, `f64`) — `wasm-bindgen` adds the machinery to pass strings, objects, closures, DOM elements, and more.

## How it works

1. You annotate your Rust code with `#[wasm_bindgen]`.
2. `wasm-bindgen` the macro expands your code, generating glue.
3. `wasm-pack` calls the `wasm-bindgen` CLI, which reads the `.wasm` binary and the glue, and generates the final optimized Wasm + JS wrapper.

```
Rust  →  rustc  →  .wasm + metadata  →  wasm-bindgen CLI  →  .wasm + .js + .d.ts
```

## Basic annotations

```rust
use wasm_bindgen::prelude::*;

// Export a function to JavaScript
#[wasm_bindgen]
pub fn greet(name: &str) -> String {
    format!("Hello, {}!", name)
}

// Export a struct (becomes a JS class)
#[wasm_bindgen]
pub struct Counter {
    value: i32,
}

#[wasm_bindgen]
impl Counter {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Counter {
        Counter { value: 0 }
    }

    pub fn increment(&mut self) {
        self.value += 1;
    }

    pub fn get(&self) -> i32 {
        self.value
    }
}
```

In JavaScript:
```javascript
import init, { greet, Counter } from './pkg/my_pkg.js';
await init();

console.log(greet("World"));  // "Hello, World!"

const c = new Counter();
c.increment();
console.log(c.get()); // 1
c.free(); // always free manually, structs are not GC'd
```

## Importing JavaScript into Rust

```rust
#[wasm_bindgen]
extern "C" {
    // Import window.alert
    fn alert(msg: &str);

    // Import console.log
    #[wasm_bindgen(js_namespace = console)]
    fn log(msg: &str);
}
```

## Common attributes

| Attribute | Purpose |
|-----------|---------|
| `#[wasm_bindgen]` | Export/import |
| `#[wasm_bindgen(constructor)]` | Mark as JS constructor |
| `#[wasm_bindgen(getter)]` | Getter property |
| `#[wasm_bindgen(setter)]` | Setter property |
| `#[wasm_bindgen(js_namespace = X)]` | Call `X.method` |
| `#[wasm_bindgen(module = "path")]` | Import from an ES module |
| `#[wasm_bindgen(catch)]` | Catch JS exceptions |
| `#[wasm_bindgen(skip)]` | Don't bind this item |

## Memory management caveat

Exported Rust structs are heap-allocated and returned to JS as opaque handles. JavaScript's GC does **not** automatically free them. You must call `.free()` on them when done, or use `Drop` via `wasm_bindgen::JsValue::from(...)` patterns.
