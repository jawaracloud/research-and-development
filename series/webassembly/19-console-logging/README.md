# 19 — Logging from Rust to the Browser Console

> **Type:** How-To + Reference

## Options for logging

| Approach | Crate | Best for |
|---------|-------|---------|
| Direct JS call | `web-sys` | Simple, no deps |
| `log` crate interface | `log` + `console_log` | Structured, level-aware |
| Leptos logger | `leptos` built-in | Leptos apps |

## Option 1: Direct web-sys call (minimal)

```toml
[dependencies.web-sys]
version = "0.3"
features = ["console"]
```

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn do_something() {
    web_sys::console::log_1(&"Hello from Rust!".into());
    web_sys::console::warn_1(&"This is a warning".into());
    web_sys::console::error_1(&"This is an error".into());

    // Log multiple values
    web_sys::console::log_2(
        &"Value:".into(),
        &JsValue::from(42),
    );
}
```

## Option 2: The `log` crate ecosystem (recommended)

This gives you the same `log::info!`, `log::debug!` macros used in native Rust.

```toml
[dependencies]
log = "0.4"
console_log = "1"
```

Set up once at app start:
```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen(start)]
pub fn start() {
    // Log everything at Debug level and above
    console_log::init_with_level(log::Level::Debug)
        .expect("Failed to initialize logger");

    log::info!("App initialized");
    log::debug!("Debug mode active");
    log::warn!("Something to watch out for");
    log::error!("Something went wrong");
}
```

You can format values normally:
```rust
let user = "Alice";
let count = 42;
log::info!("User {} has {} items", user, count);
```

## Option 3: Using a macro wrapper

For convenience, define a short macro:

```rust
use wasm_bindgen::prelude::*;

macro_rules! log {
    ($($t:tt)*) => {
        web_sys::console::log_1(&format!($($t)*).into())
    };
}

// Usage
log!("Hello from macro: {}", 42);
```

## Log levels in the browser

```
log::error!  → console.error  (red)
log::warn!   → console.warn   (yellow)
log::info!   → console.info   (blue)
log::debug!  → console.debug  (grey, often hidden by default)
log::trace!  → console.debug  (grey)
```

In Chrome DevTools, click the filter dropdown to show/hide "Verbose" to see debug/trace logs.

## Stripping logs in production

Use the `log` crate's feature flags:
```toml
# Only compile warn and error in release builds
[dependencies]
log = { version = "0.4", features = ["max_level_warn", "release_max_level_warn"] }
```

This completely eliminates debug/info log code from the release binary — smaller and no perf cost.
