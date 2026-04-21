# 25 — Closures and Callbacks Across the Wasm Boundary

> **Type:** How-To + Explanation

## The challenge with closures

Rust closures and JavaScript callbacks have very different ownership models. Rust closures have lifetimes — Wasm can't let JavaScript hold a reference to a Rust closure that might be dropped. `wasm-bindgen` provides the `Closure` type to manage this.

## The `Closure` type

`Closure<T>` is a wrapper that:
1. Puts your Rust closure on the heap.
2. Creates a JavaScript `Function` object that refers to it.
3. Keeps the closure alive as long as the `Closure<T>` is alive.

```toml
[dependencies]
wasm-bindgen = "0.2"
```

## One-shot callbacks (Closure::once)

For callbacks that fire exactly once (e.g., `setTimeout`):

```rust
use wasm_bindgen::prelude::*;
use web_sys::window;

#[wasm_bindgen]
pub fn schedule_greet(delay_ms: i32) {
    let callback = Closure::once(move || {
        web_sys::console::log_1(&"Hello after delay!".into());
    });

    window()
        .unwrap()
        .set_timeout_with_callback_and_timeout_and_arguments_0(
            callback.as_ref().unchecked_ref(),
            delay_ms,
        )
        .unwrap();

    // For once closures, we can forget them — they self-drop after calling
    callback.forget();
}
```

## Persistent callbacks (event listeners)

For callbacks that fire multiple times (e.g., `addEventListener`):

```rust
use wasm_bindgen::prelude::*;
use web_sys::{Event, EventTarget};

pub fn add_click_handler(target: &EventTarget) -> Closure<dyn FnMut(Event)> {
    let handler = Closure::wrap(Box::new(move |event: Event| {
        web_sys::console::log_1(&"Clicked!".into());
    }) as Box<dyn FnMut(Event)>);

    target
        .add_event_listener_with_callback("click", handler.as_ref().unchecked_ref())
        .unwrap();

    // Return the closure so the caller can keep it alive
    // If this were dropped here, the callback would become invalid
    handler
}
```

> **Critical**: The returned `Closure` must be kept alive (stored in a `static`, `Rc`, or struct field). If it is dropped, the JS callback references a dangling function and will panic.

## Using `Closure::forget` (for permanent listeners)

If a closure should live for the entire app lifetime, you can call `forget()`:

```rust
let handler = Closure::wrap(Box::new(move |_event: Event| {
    // handle event
}) as Box<dyn FnMut(Event)>);

document
    .add_event_listener_with_callback("click", handler.as_ref().unchecked_ref())
    .unwrap();

// Leak the closure intentionally — it lives forever
handler.forget();
```

This leaks memory, but it's fine for application-lifetime callbacks.

## Passing a callback from JavaScript to Rust

```rust
use js_sys::Function;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn call_later(callback: &Function, value: i32) {
    let arg = JsValue::from(value * 2);
    callback.call1(&JsValue::NULL, &arg).unwrap();
}
```

JavaScript:
```javascript
call_later((result) => console.log(result), 21); // logs 42
```

## Memory safety summary

| Pattern | How to handle |
|---------|--------------|
| One-shot callback | `Closure::once` + `.forget()` |
| Repeated callback (finite lifetime) | `Closure::wrap`, store the handle, drop when done |
| Application-lifetime listener | `Closure::wrap` + `.forget()` |
| JS callback into Rust | Receive as `&js_sys::Function`, call with `.call1()` |
