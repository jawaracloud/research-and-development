# 32 — Creating and Appending HTML Elements Dynamically

> **Type:** How-To + Tutorial

## Setup

```toml
[dependencies.web-sys]
version = "0.3"
features = [
  "Window", "Document", "Element",
  "HtmlElement", "Node", "Text",
]
```

## Creating elements

```rust
use wasm_bindgen::prelude::*;
use web_sys::{Document, Element, HtmlElement};
use wasm_bindgen::JsCast;

fn document() -> Document {
    web_sys::window().unwrap().document().unwrap()
}

#[wasm_bindgen]
pub fn build_ui() {
    let doc = document();

    // Create a <div>
    let container = doc.create_element("div").unwrap();
    container.set_attribute("id", "app").unwrap();
    container.set_attribute("class", "container").unwrap();

    // Create a <h1>
    let heading = doc.create_element("h1").unwrap();
    heading.set_text_content(Some("Hello from Rust!"));

    // Create a <p>
    let para = doc.create_element("p").unwrap();
    para.set_text_content(Some("Built without a framework."));

    // Create a <button>
    let btn = doc.create_element("button").unwrap();
    btn.set_text_content(Some("Click me"));
    btn.set_attribute("id", "main-btn").unwrap();

    // Assemble the tree
    container.append_child(&heading).unwrap();
    container.append_child(&para).unwrap();
    container.append_child(&btn).unwrap();

    // Append to body
    doc.body().unwrap().append_child(&container).unwrap();
}
```

## Creating elements with inline styles

```rust
let card = doc.create_element("div").unwrap();
let card_html: HtmlElement = card.dyn_into().unwrap();
let style = card_html.style();
style.set_property("background", "#1e1e2e").unwrap();
style.set_property("border-radius", "8px").unwrap();
style.set_property("padding", "16px").unwrap();
style.set_property("color", "white").unwrap();
```

## Creating a text node

```rust
let text = doc.create_text_node("Raw text node");
container.append_child(&text).unwrap();
```

## Creating elements with a helper function

Managing this verbosity is why frameworks exist. A helper makes it bearable:

```rust
fn create_el(tag: &str, class: &str, text: Option<&str>) -> web_sys::Element {
    let doc = web_sys::window().unwrap().document().unwrap();
    let el = doc.create_element(tag).unwrap();
    if !class.is_empty() {
        el.set_attribute("class", class).unwrap();
    }
    if let Some(t) = text {
        el.set_text_content(Some(t));
    }
    el
}

// Usage:
let title = create_el("h2", "card-title", Some("About"));
let body  = create_el("p", "card-body", Some("Some description."));
```

## Removing elements

```rust
// Remove a child from its parent
parent.remove_child(&child).unwrap();

// Remove an element from the DOM directly (self-remove)
el.remove();
```

## Inserting before another element

```rust
// insert_before(new_node, reference_node)
parent.insert_before(&new_child, Some(&existing_child)).unwrap();
```

## Replacing elements

```rust
parent.replace_child(&new_child, &old_child).unwrap();
```

## Cloning an element

```rust
let clone = el.clone_node_with_deep(true).unwrap();  // deep clone
parent.append_child(&clone).unwrap();
```
