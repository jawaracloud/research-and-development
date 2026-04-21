# 31 — Querying and Modifying the DOM from Rust

> **Type:** How-To

## Setup

```toml
[dependencies]
wasm-bindgen = "0.2"

[dependencies.web-sys]
version = "0.3"
features = [
  "Window", "Document", "Element",
  "HtmlElement", "HtmlInputElement",
  "Node", "NodeList",
]
```

## Getting the document

```rust
use web_sys::{window, Document};

fn document() -> Document {
    window().unwrap().document().unwrap()
}
```

## Querying elements

```rust
use wasm_bindgen::JsCast;
use web_sys::{Element, HtmlElement, HtmlInputElement};

// By ID — returns Option<Element>
let el: Option<Element> = document().get_element_by_id("my-id");

// By CSS selector — returns Option<Element>
let el = document().query_selector(".my-class").unwrap();

// By tag name — returns NodeList (not Vec)
let divs = document().get_elements_by_tag_name("div");
for i in 0..divs.length() {
    let div = divs.item(i).unwrap();
    // ...
}

// By CSS selector (all matches) — returns NodeList
let items = document().query_selector_all("li").unwrap();
```

## Downcasting with JsCast

`get_element_by_id` returns `Element`. To use element-specific methods (like `.value()` on inputs), downcast with `dyn_into`:

```rust
use wasm_bindgen::JsCast;

let input = document()
    .get_element_by_id("username")
    .unwrap()
    .dyn_into::<HtmlInputElement>()
    .unwrap();

let value = input.value();      // String
input.set_value("new value");
input.focus().unwrap();
```

## Modifying elements

```rust
let el = document()
    .get_element_by_id("greeting")
    .unwrap();

// Text content
el.set_text_content(Some("Hello, Wasm!"));

// Inner HTML (be careful with user content — XSS risk)
el.set_inner_html("<strong>Bold text</strong>");

// Attributes
el.set_attribute("data-count", "42").unwrap();
let val = el.get_attribute("data-count"); // Option<String>
el.remove_attribute("hidden").unwrap();

// CSS classes
let class_list = el.class_list();
class_list.add_1("active").unwrap();
class_list.remove_1("hidden").unwrap();
class_list.toggle("visible").unwrap();
let has = class_list.contains("active");

// Inline style (via HtmlElement)
use web_sys::HtmlElement;
let html_el = el.dyn_into::<HtmlElement>().unwrap();
let style = html_el.style();
style.set_property("color", "red").unwrap();
style.set_property("font-size", "18px").unwrap();
```

## Traversing the tree

```rust
let el = document().get_element_by_id("parent").unwrap();

// Children
let children = el.children();         // HTMLCollection
let child_nodes = el.child_nodes();   // NodeList (incl. text nodes)
let first = el.first_element_child(); // Option<Element>
let last = el.last_element_child();   // Option<Element>

// Siblings
let next = el.next_element_sibling(); // Option<Element>
let prev = el.previous_element_sibling();

// Parent
let parent = el.parent_element();     // Option<Element>
```
