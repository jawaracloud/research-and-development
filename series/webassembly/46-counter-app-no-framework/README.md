# 46 — Project: Counter App with State & Rendering

> **Type:** Tutorial

## Purpose

A counter is the "Hello World" of frontend state. This project focuses on the *correct* way to manage state and re-render efficiently in raw Wasm.

## What you will build

A counter with:
- Increment, decrement, reset
- Step size input
- History of last 5 values
- Animated CSS class transitions

## Project structure

```
46-counter-app/
├── Cargo.toml
├── index.html
├── style.css
└── src/
    └── lib.rs
```

## Cargo.toml

```toml
[package]
name = "counter-app"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
wasm-bindgen = "0.2"
console_error_panic_hook = "0.1"

[dependencies.web-sys]
version = "0.3"
features = [
  "Window", "Document", "HtmlElement",
  "HtmlInputElement", "Element",
]
```

## State model

```rust
use std::cell::RefCell;
use std::collections::VecDeque;

struct CounterState {
    count: i32,
    step: i32,
    history: VecDeque<i32>,
}

impl CounterState {
    fn apply(&mut self, new_value: i32) {
        self.history.push_front(self.count);
        if self.history.len() > 5 { self.history.pop_back(); }
        self.count = new_value;
    }
}

thread_local! {
    static STATE: RefCell<CounterState> = RefCell::new(CounterState {
        count: 0,
        step: 1,
        history: VecDeque::new(),
    });
}
```

## DOM update (targeted, not full re-render)

Key insight: updating only the changed DOM nodes, not the whole page:

```rust
fn update_display() {
    STATE.with(|s| {
        let state = s.borrow();
        let doc = web_sys::window().unwrap().document().unwrap();

        // Update counter value
        let display = doc.get_element_by_id("count-display").unwrap();
        display.set_text_content(Some(&state.count.to_string()));

        // Apply color class based on value
        let class_list = display.class_list();
        class_list.remove_2("positive", "negative").unwrap();
        if state.count > 0 {
            class_list.add_1("positive").unwrap();
        } else if state.count < 0 {
            class_list.add_1("negative").unwrap();
        }

        // Update history
        let history_el = doc.get_element_by_id("history").unwrap();
        let history_text: Vec<String> = state.history.iter()
            .map(|n| n.to_string())
            .collect();
        history_el.set_text_content(Some(&history_text.join(" → ")));
    });
}
```

## Actions

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn increment() {
    STATE.with(|s| {
        let mut state = s.borrow_mut();
        let new = state.count + state.step;
        state.apply(new);
    });
    update_display();
}

#[wasm_bindgen]
pub fn decrement() {
    STATE.with(|s| {
        let mut state = s.borrow_mut();
        let new = state.count - state.step;
        state.apply(new);
    });
    update_display();
}

#[wasm_bindgen]
pub fn reset() {
    STATE.with(|s| s.borrow_mut().count = 0);
    update_display();
}

#[wasm_bindgen]
pub fn set_step(step: i32) {
    STATE.with(|s| s.borrow_mut().step = step.max(1));
}
```

## index.html

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Counter</title>
  <link rel="stylesheet" href="style.css" />
</head>
<body>
  <div class="app">
    <h1 id="count-display" class="count">0</h1>
    <div class="controls">
      <button onclick="wasm.decrement()">−</button>
      <button onclick="wasm.reset()">Reset</button>
      <button onclick="wasm.increment()">+</button>
    </div>
    <label>Step: <input type="number" value="1" min="1"
      oninput="wasm.set_step(parseInt(this.value))" /></label>
    <p>History: <span id="history">—</span></p>
  </div>
  <script type="module">
    import init, * as wasm_module from './pkg/counter_app.js';
    await init();
    window.wasm = wasm_module;
  </script>
</body>
</html>
```

## Key learning from this project

- **Targeted DOM updates** are more efficient than full re-renders.
- State in `thread_local!` + `RefCell` works well for simple apps.
- As app grows, this pattern becomes unmaintainable — signals (Leptos) automate this tracking.
