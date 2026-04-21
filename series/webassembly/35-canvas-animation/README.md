# 35 — Animating with requestAnimationFrame

> **Type:** How-To + Tutorial

## How animation works in the browser

`requestAnimationFrame` (rAF) asks the browser to call your function before the next screen repaint — typically 60 times per second. This is the correct way to drive animations.

The pattern: each rAF callback schedules the *next* rAF call, creating a loop.

## The recursive rAF pattern in Rust

The challenge in Rust is that the callback must reference itself (to schedule the next frame) — which creates a circular reference. The standard solution uses `Rc<RefCell<Option<Closure<...>>>>`:

```rust
use std::cell::RefCell;
use std::rc::Rc;
use wasm_bindgen::prelude::*;
use wasm_bindgen::JsCast;
use web_sys::{CanvasRenderingContext2d, HtmlCanvasElement, Window};

#[wasm_bindgen]
pub fn start_animation() {
    let window = web_sys::window().unwrap();
    let doc = window.document().unwrap();
    let canvas: HtmlCanvasElement = doc
        .get_element_by_id("canvas").unwrap()
        .dyn_into().unwrap();
    let ctx: CanvasRenderingContext2d = canvas
        .get_context("2d").unwrap().unwrap()
        .dyn_into().unwrap();

    // State
    let mut angle: f64 = 0.0;
    let width = canvas.width() as f64;
    let height = canvas.height() as f64;

    // Shared closure slot
    let f = Rc::new(RefCell::new(None::<Closure<dyn FnMut()>>));
    let g = f.clone();

    *g.borrow_mut() = Some(Closure::wrap(Box::new(move || {
        // Update state
        angle += 0.02;
        if angle > std::f64::consts::TAU { angle = 0.0; }

        // Draw
        ctx.clear_rect(0.0, 0.0, width, height);
        ctx.set_fill_style(&"#1e1e2e".into());
        ctx.fill_rect(0.0, 0.0, width, height);

        let cx = width / 2.0 + 150.0 * angle.cos();
        let cy = height / 2.0 + 150.0 * angle.sin();

        ctx.begin_path();
        ctx.arc(cx, cy, 30.0, 0.0, std::f64::consts::TAU).unwrap();
        ctx.set_fill_style(&"#cba6f7".into());
        ctx.fill();

        // Schedule next frame
        web_sys::window().unwrap()
            .request_animation_frame(
                f.borrow().as_ref().unwrap().as_ref().unchecked_ref()
            )
            .unwrap();
    }) as Box<dyn FnMut()>));

    // Kick off the loop
    window
        .request_animation_frame(
            g.borrow().as_ref().unwrap().as_ref().unchecked_ref()
        )
        .unwrap();
}
```

## Using timestamps for smooth animation

rAF passes a `DOMHighResTimeStamp` (milliseconds since page load):

```rust
let f = Rc::new(RefCell::new(None::<Closure<dyn FnMut(f64)>>));
let g = f.clone();

let start_time: Rc<RefCell<Option<f64>>> = Rc::new(RefCell::new(None));

*g.borrow_mut() = Some(Closure::wrap(Box::new(move |timestamp: f64| {
    let start = *start_time.borrow_mut().get_or_insert(timestamp);
    let elapsed = (timestamp - start) / 1000.0; // seconds
    let angle = elapsed * std::f64::consts::TAU / 4.0; // full circle every 4s

    // draw using angle...

    web_sys::window().unwrap()
        .request_animation_frame(f.borrow().as_ref().unwrap().as_ref().unchecked_ref())
        .unwrap();
}) as Box<dyn FnMut(f64)>));
```

## Cancelling animation

```rust
let animation_id = window
    .request_animation_frame(callback.as_ref().unchecked_ref())
    .unwrap();

// Later:
window.cancel_animation_frame(animation_id).unwrap();
```

## The gloo crate (cleaner API)

The `gloo` crate wraps rAF in a cleaner Rust interface:

```toml
[dependencies]
gloo = "0.11"
```

```rust
use gloo::render::{request_animation_frame, AnimationFrame};

let handle: AnimationFrame = request_animation_frame(|timestamp| {
    // draw frame
});
// hold `handle` — drop it to cancel
```
