# 47 — Project: Markdown Previewer (Rust Parsing + DOM)

> **Type:** Tutorial

## What you will build

A side-by-side Markdown editor where you type on the left and see rendered HTML on the right — the parsing happens in Wasm using a pure Rust Markdown library.

This is a great showcase for Wasm's value: a CPU-intensive parsing task (Markdown → HTML) runs in Rust at native speed, then the result is handed to the browser for display.

## Cargo.toml

```toml
[package]
name = "markdown-previewer"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
wasm-bindgen = "0.2"
pulldown-cmark = "0.11"
console_error_panic_hook = "0.1"
```

**`pulldown-cmark`** is a fast, CommonMark-compliant Markdown parser written in Rust.

## Core parsing function

```rust
use pulldown_cmark::{html, Options, Parser};
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn markdown_to_html(input: &str) -> String {
    let mut options = Options::empty();
    options.insert(Options::ENABLE_STRIKETHROUGH);
    options.insert(Options::ENABLE_TABLES);
    options.insert(Options::ENABLE_FOOTNOTES);
    options.insert(Options::ENABLE_TASKLISTS);

    let parser = Parser::new_ext(input, options);
    let mut html_output = String::new();
    html::push_html(&mut html_output, parser);
    html_output
}
```

That's the entire Wasm logic. No DOM manipulation needed from Rust — we produce an HTML string and let JavaScript set `.innerHTML`.

## index.html

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Markdown Previewer</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { display: flex; height: 100vh; font-family: sans-serif; }
    .pane { flex: 1; padding: 1rem; overflow: auto; }
    #editor {
      background: #1e1e2e; color: #cdd6f4;
      font-family: monospace; font-size: 14px;
      border: none; outline: none; resize: none;
      width: 100%; height: 100%;
    }
    #preview { background: #181825; color: #cdd6f4; }
    #preview h1,h2,h3 { margin: 1em 0 0.5em; color: #cba6f7; }
    #preview code { background: #313244; padding: 2px 6px; border-radius: 4px; }
    #preview pre { background: #313244; padding: 1em; border-radius: 8px; }
    .divider { width: 2px; background: #313244; cursor: ew-resize; }
  </style>
</head>
<body>
  <div class="pane">
    <textarea id="editor" placeholder="Type Markdown here..."># Hello, Wasm!

Write **bold**, *italic*, or `code`.

- Item 1
- Item 2

> Blockquote

```rust
fn main() {
    println!("Hello!");
}
```
    </textarea>
  </div>
  <div class="divider"></div>
  <div class="pane" id="preview"></div>

  <script type="module">
    import init, { markdown_to_html } from './pkg/markdown_previewer.js';
    await init();

    const editor = document.getElementById('editor');
    const preview = document.getElementById('preview');

    function update() {
        // XSS note: this is a dev tool, not user-facing content.
        // In production, sanitize HTML output.
        preview.innerHTML = markdown_to_html(editor.value);
    }

    editor.addEventListener('input', update);
    update(); // render on load
  </script>
</body>
</html>
```

## Build and run

```bash
wasm-pack build --target web --release
python3 -m http.server 8080
```

## Extension ideas

1. **Syntax highlighting** — add `highlight.js` on the JS side to highlight code blocks.
2. **Output copy button** — copy rendered HTML to clipboard.
3. **Export to PDF** — use `window.print()` on the preview pane.
4. **Auto-save** — persist editor content to localStorage (lesson 37).
5. **Split pane** — implement a draggable divider.

## Performance note

`pulldown-cmark` in Wasm can parse a 10,000-word document in under 2ms. The JS `innerHTML` set is the bottleneck for large documents. Use `requestAnimationFrame` debouncing for smooth typing:

```javascript
let frameId = null;
editor.addEventListener('input', () => {
    if (frameId) cancelAnimationFrame(frameId);
    frameId = requestAnimationFrame(() => {
        preview.innerHTML = markdown_to_html(editor.value);
    });
});
```
