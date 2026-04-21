# 20 — Handling Errors Across the Rust–JS Boundary

> **Type:** Explanation + How-To

## The challenge

Rust uses `Result<T, E>` for errors. JavaScript uses exceptions. When these two systems meet at the Wasm boundary, you need strategies to bridge them cleanly.

## Option 1: Panic (not recommended for production)

If a Rust function panics, the browser catches it as a JavaScript error. Without `console_error_panic_hook`, the message is useless (`unreachable` or similar).

Use `console_error_panic_hook` for better messages (see lesson 18), but panics should only happen for truly unexpected conditions — not user errors.

## Option 2: Return a JsValue error

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn parse_number(s: &str) -> Result<f64, JsValue> {
    s.parse::<f64>().map_err(|e| JsValue::from_str(&e.to_string()))
}
```

In JavaScript, a `Result<T, E>` where `E: Into<JsValue>`:
- On `Ok(v)` — returns `v` normally.
- On `Err(e)` — throws a JavaScript `Error` exception.

```javascript
try {
    const n = parse_number("abc");
} catch (e) {
    console.error("Parse failed:", e);  // "invalid float literal"
}
```

## Option 3: Return an Option (null-safe)

```rust
#[wasm_bindgen]
pub fn find_word(text: &str, word: &str) -> Option<usize> {
    text.find(word)
}
```

`Option<usize>` maps to `number | undefined` in TypeScript:
- `Some(n)` → `n`
- `None` → `undefined`

## Option 4: Use a custom error type

For richer errors:

```rust
use wasm_bindgen::prelude::*;
use js_sys::Error;

#[wasm_bindgen]
pub fn divide(a: f64, b: f64) -> Result<f64, JsValue> {
    if b == 0.0 {
        let err = Error::new("Division by zero");
        err.set_name("MathError");
        return Err(err.into());
    }
    Ok(a / b)
}
```

In JavaScript:
```javascript
try {
    divide(10.0, 0.0);
} catch (e) {
    console.log(e.name);    // "MathError"
    console.log(e.message); // "Division by zero"
}
```

## Option 5: Catching JS exceptions from Rust

When calling JS functions that might throw, use `#[wasm_bindgen(catch)]`:

```rust
#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(catch, js_namespace = JSON)]
    fn parse(text: &str) -> Result<JsValue, JsValue>;
}

pub fn safe_json_parse(s: &str) -> Option<JsValue> {
    parse(s).ok()
}
```

## Error handling strategy summary

| Scenario | Strategy |
|---------|---------|
| Programming bug | `panic!` (with `console_error_panic_hook`) |
| User input error | Return `Result<T, JsValue>` |
| Optional value | Return `Option<T>` |
| JS function that throws | Use `#[wasm_bindgen(catch)]` |
| Rich error with name + message | Use `js_sys::Error` |

## Best practice

In production, log panics to an error monitoring service (Sentry, Datadog). Wrap `console_error_panic_hook` to forward the panic message:

```rust
std::panic::set_hook(Box::new(|info| {
    console_error_panic_hook::hook(info);
    // also send to your error monitoring
}));
```
