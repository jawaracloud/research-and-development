# 27 — Importing Custom JavaScript Functions into Rust

> **Type:** How-To + Reference

## Why import JS into Rust?

Sometimes you need to call code that already exists in JavaScript — a third-party library, browser APIs not yet in `web-sys`, or legacy code — from within your Rust Wasm module.

## Basic import syntax

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern "C" {
    fn alert(message: &str);
}

#[wasm_bindgen]
pub fn say_hello() {
    alert("Hello from Rust!");
}
```

The `extern "C" { ... }` block tells `wasm-bindgen` to treat the declared functions as imports that the JavaScript host must supply.

## Importing from a JavaScript namespace

```rust
#[wasm_bindgen]
extern "C" {
    // Imports console.log
    #[wasm_bindgen(js_namespace = console)]
    fn log(s: &str);

    // Imports Math.random
    #[wasm_bindgen(js_namespace = Math)]
    fn random() -> f64;

    // Imports JSON.stringify
    #[wasm_bindgen(js_namespace = JSON)]
    fn stringify(val: &JsValue) -> String;
}
```

## Importing a method on a class

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern "C" {
    pub type MyLibrary;

    #[wasm_bindgen(constructor)]
    fn new() -> MyLibrary;

    #[wasm_bindgen(method)]
    fn compute(this: &MyLibrary, input: f64) -> f64;
}

#[wasm_bindgen]
pub fn run() {
    let lib = MyLibrary::new();
    let result = lib.compute(3.14);
    web_sys::console::log_1(&result.into());
}
```

## Importing from an ES module

If you have a JavaScript module you want to import from:

```rust
#[wasm_bindgen(module = "/src/utils.js")]
extern "C" {
    fn format_currency(amount: f64, currency: &str) -> String;
}
```

`/src/utils.js`:
```javascript
export function format_currency(amount, currency) {
    return new Intl.NumberFormat('en-US', {
        style: 'currency', currency
    }).format(amount);
}
```

## Catching exceptions from imported JS

If the JS function might throw:

```rust
#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(catch)]
    fn dangerous_js_call(val: &str) -> Result<JsValue, JsValue>;
}

pub fn safe_call(val: &str) {
    match dangerous_js_call(val) {
        Ok(result) => { /* use result */ }
        Err(err) => {
            web_sys::console::error_1(&err);
        }
    }
}
```

## Importing with different JS name

```rust
#[wasm_bindgen]
extern "C" {
    // JS name is "my-function" (with hyphen, invalid Rust ident)
    #[wasm_bindgen(js_name = "my-function")]
    fn my_function(x: i32) -> i32;
}
```

## Complete workflow summary

1. Write the `extern "C"` block with `#[wasm_bindgen]` attributes.
2. Use `js_namespace`, `js_name`, `module`, `method`, `constructor`, `catch` as needed.
3. Call the imported function from other `#[wasm_bindgen]` functions.
4. When building with `wasm-pack --target web` or Trunk, the JS glue automatically wires up the imports.
