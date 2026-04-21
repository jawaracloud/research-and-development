# 34 — Drawing on the HTML5 Canvas (2D Context)

> **Type:** Tutorial + How-To

## Setup

```toml
[dependencies.web-sys]
version = "0.3"
features = [
  "Window", "Document",
  "HtmlCanvasElement", "CanvasRenderingContext2d",
  "Element",
]
```

## Getting the 2D context

```rust
use wasm_bindgen::prelude::*;
use wasm_bindgen::JsCast;
use web_sys::{HtmlCanvasElement, CanvasRenderingContext2d};

fn get_context(canvas_id: &str) -> (HtmlCanvasElement, CanvasRenderingContext2d) {
    let doc = web_sys::window().unwrap().document().unwrap();
    let canvas = doc
        .get_element_by_id(canvas_id).unwrap()
        .dyn_into::<HtmlCanvasElement>().unwrap();

    let ctx = canvas
        .get_context("2d").unwrap().unwrap()
        .dyn_into::<CanvasRenderingContext2d>().unwrap();

    (canvas, ctx)
}
```

## Drawing shapes

```rust
#[wasm_bindgen]
pub fn draw() {
    let (canvas, ctx) = get_context("my-canvas");
    let w = canvas.width() as f64;
    let h = canvas.height() as f64;

    // Clear
    ctx.clear_rect(0.0, 0.0, w, h);

    // Background
    ctx.set_fill_style(&"#1e1e2e".into());
    ctx.fill_rect(0.0, 0.0, w, h);

    // Rectangle
    ctx.set_fill_style(&"#cba6f7".into());
    ctx.fill_rect(50.0, 50.0, 200.0, 100.0);

    // Stroke rectangle
    ctx.set_stroke_style(&"#89b4fa".into());
    ctx.set_line_width(3.0);
    ctx.stroke_rect(300.0, 50.0, 150.0, 150.0);

    // Circle
    ctx.begin_path();
    ctx.arc(200.0, 300.0, 80.0, 0.0, std::f64::consts::TAU).unwrap();
    ctx.set_fill_style(&"#a6e3a1".into());
    ctx.fill();
    ctx.set_stroke_style(&"#ffffff".into());
    ctx.set_line_width(2.0);
    ctx.stroke();

    // Line
    ctx.begin_path();
    ctx.move_to(0.0, h);
    ctx.line_to(w, 0.0);
    ctx.set_stroke_style(&"#f38ba8".into());
    ctx.set_line_width(1.0);
    ctx.stroke();

    // Triangle
    ctx.begin_path();
    ctx.move_to(400.0, 300.0);
    ctx.line_to(500.0, 450.0);
    ctx.line_to(300.0, 450.0);
    ctx.close_path();
    ctx.set_fill_style(&"#fab387".into());
    ctx.fill();
}
```

## Drawing text

```rust
ctx.set_font("bold 32px sans-serif");
ctx.set_fill_style(&"white".into());
ctx.fill_text("Hello, Canvas!", 50.0, 200.0).unwrap();

// Centered text
ctx.set_text_align("center");
ctx.fill_text("Centered", w / 2.0, h / 2.0).unwrap();
```

## Drawing an image

```rust
use web_sys::HtmlImageElement;

let img = HtmlImageElement::new().unwrap();
img.set_src("sprite.png");

// Draw once loaded
let ctx_clone = ctx.clone();
let handler = Closure::once(move || {
    ctx_clone.draw_image_with_html_image_element(&img, 0.0, 0.0).unwrap();
});
img.set_onload(Some(handler.as_ref().unchecked_ref()));
handler.forget();
```

## Working with pixel data

```rust
let image_data = ctx.get_image_data(0.0, 0.0, 100.0, 100.0).unwrap();
let data = image_data.data(); // Uint8ClampedArray — RGBA bytes
// Modify pixels...
ctx.put_image_data(&image_data, 0.0, 0.0).unwrap();
```

## HTML

```html
<canvas id="my-canvas" width="600" height="500"></canvas>
```
