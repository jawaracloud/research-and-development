# 33 — Adding Event Listeners (Click, Input, Submit)

> **Type:** How-To

## Setup

```toml
[dependencies.web-sys]
version = "0.3"
features = [
  "Window", "Document", "Element", "EventTarget",
  "HtmlElement", "HtmlInputElement", "HtmlFormElement",
  "Event", "MouseEvent", "InputEvent", "KeyboardEvent",
  "SubmitEvent",
]
```

## Basic click listener

```rust
use wasm_bindgen::prelude::*;
use wasm_bindgen::JsCast;
use web_sys::{EventTarget, MouseEvent};

#[wasm_bindgen]
pub fn setup_button() {
    let doc = web_sys::window().unwrap().document().unwrap();
    let btn = doc.get_element_by_id("my-button").unwrap();

    let handler = Closure::wrap(Box::new(move |_event: MouseEvent| {
        web_sys::console::log_1(&"Button clicked!".into());
    }) as Box<dyn FnMut(MouseEvent)>);

    btn.add_event_listener_with_callback(
        "click",
        handler.as_ref().unchecked_ref(),
    ).unwrap();

    handler.forget(); // Keep alive for app lifetime
}
```

## Input listener (reading keyboard input)

```rust
use web_sys::{EventTarget, HtmlInputElement, InputEvent};

pub fn setup_input(input_id: &str) {
    let doc = web_sys::window().unwrap().document().unwrap();
    let input = doc.get_element_by_id(input_id).unwrap();

    let handler = Closure::wrap(Box::new(move |event: InputEvent| {
        let target = event.target().unwrap();
        let input: HtmlInputElement = target.dyn_into().unwrap();
        let value = input.value();
        web_sys::console::log_1(&format!("Input: {}", value).into());
    }) as Box<dyn FnMut(InputEvent)>);

    input.add_event_listener_with_callback("input", handler.as_ref().unchecked_ref())
        .unwrap();

    handler.forget();
}
```

## Form submit listener

```rust
use web_sys::{Event, HtmlFormElement, HtmlInputElement};

pub fn setup_form() {
    let doc = web_sys::window().unwrap().document().unwrap();
    let form = doc.get_element_by_id("my-form").unwrap();

    let handler = Closure::wrap(Box::new(move |event: Event| {
        event.prevent_default(); // prevent page reload
        
        let doc = web_sys::window().unwrap().document().unwrap();
        let name: HtmlInputElement = doc
            .get_element_by_id("name-field").unwrap()
            .dyn_into().unwrap();
        
        web_sys::console::log_1(&format!("Submitted: {}", name.value()).into());
    }) as Box<dyn FnMut(Event)>);

    form.add_event_listener_with_callback("submit", handler.as_ref().unchecked_ref())
        .unwrap();

    handler.forget();
}
```

## Keyboard listener

```rust
use web_sys::KeyboardEvent;

pub fn setup_keyboard() {
    let window = web_sys::window().unwrap();

    let handler = Closure::wrap(Box::new(move |event: KeyboardEvent| {
        let key = event.key();
        if key == "Escape" {
            web_sys::console::log_1(&"Escape pressed".into());
        }
        if event.ctrl_key() && key == "s" {
            event.prevent_default();
            web_sys::console::log_1(&"Ctrl+S".into());
        }
    }) as Box<dyn FnMut(KeyboardEvent)>);

    window.add_event_listener_with_callback("keydown", handler.as_ref().unchecked_ref())
        .unwrap();

    handler.forget();
}
```

## Removing event listeners

To remove an event listener, you need to keep a reference to the same callback function. With `Closure`, call `.forget()` returns the underlying `js_sys::Function`:

```rust
// Store the closure instead of forgetting it
let closure = Closure::wrap(Box::new(move |_: MouseEvent| {
    // handler
}) as Box<dyn FnMut(MouseEvent)>);

let fn_ref: &Function = closure.as_ref().unchecked_ref();
target.add_event_listener_with_callback("click", fn_ref).unwrap();

// Later...
target.remove_event_listener_with_callback("click", fn_ref).unwrap();
drop(closure); // Now safe to drop
```
