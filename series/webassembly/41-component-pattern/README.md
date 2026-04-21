# 41 — Implementing a Component Pattern Manually

> **Type:** Explanation + How-To

## Why this matters

Before reaching for a framework, understanding how to build a component system from scratch reveals exactly what frameworks solve — and why they're worth using.

## The goal

A "component" should:
1. Encapsulate its own DOM rendering.
2. Manage its own state.
3. Know how to re-render when that state changes.

## A minimal component trait

```rust
use web_sys::Element;

pub trait Component {
    /// Render the component's DOM and return the root element
    fn render(&self) -> Element;
    
    /// Called after the component is mounted into the DOM
    fn mount(&mut self, container: &Element) {
        let el = self.render();
        container.append_child(&el).unwrap();
    }
}
```

## A concrete Counter component

```rust
use std::cell::Cell;
use std::rc::Rc;
use wasm_bindgen::prelude::*;
use wasm_bindgen::JsCast;
use web_sys::{Document, Element, HtmlElement};

fn doc() -> Document {
    web_sys::window().unwrap().document().unwrap()
}

pub struct Counter {
    count: Rc<Cell<i32>>,
    container_id: String,
}

impl Counter {
    pub fn new(id: &str) -> Self {
        Counter {
            count: Rc::new(Cell::new(0)),
            container_id: id.to_string(),
        }
    }

    pub fn mount(&self) {
        let container = doc().get_element_by_id(&self.container_id).unwrap();
        self.render_into(&container);
    }

    fn render_into(&self, parent: &Element) {
        parent.set_inner_html(""); // clear

        let count = self.count.clone();
        let container_id = self.container_id.clone();

        let wrapper = doc().create_element("div").unwrap();

        let display = doc().create_element("p").unwrap();
        display.set_text_content(Some(&format!("Count: {}", count.get())));

        let btn = doc().create_element("button").unwrap();
        btn.set_text_content(Some("Increment"));

        let count_clone = count.clone();
        let id_clone = container_id.clone();
        let handler = Closure::wrap(Box::new(move || {
            count_clone.set(count_clone.get() + 1);
            // Re-render by re-mounting
            let container = doc().get_element_by_id(&id_clone).unwrap();
            container.set_inner_html("");
            let display = doc().create_element("p").unwrap();
            display.set_text_content(Some(&format!("Count: {}", count_clone.get())));
            let new_btn = doc().create_element("button").unwrap();
            new_btn.set_text_content(Some("Increment"));
            container.append_child(&display).unwrap();
            container.append_child(&new_btn).unwrap();
            // Note: we lose the event listener on re-render — this is the problem
            // frameworks solve with virtual DOM / fine-grained reactivity
        }) as Box<dyn FnMut()>);

        btn.dyn_ref::<HtmlElement>().unwrap()
            .set_onclick(Some(handler.as_ref().unchecked_ref()));
        handler.forget();

        wrapper.append_child(&display).unwrap();
        wrapper.append_child(&btn).unwrap();
        parent.append_child(&wrapper).unwrap();
    }
}
```

## The fundamental problems this reveals

1. **Re-render wires lost** — every re-render destroys and recreates DOM, losing all event listeners.
2. **Ownership chaos** — closures must clone references everywhere to survive re-renders.
3. **No diffing** — the whole DOM is replaced, even for tiny changes (bad for performance and focus).

This is exactly what a virtual DOM (React) or fine-grained signals (Leptos/Solid) solve:
- React: re-renders only changed elements via virtual DOM diff.
- Leptos: surgically updates only the specific DOM nodes that depend on changed signals.

## Key insight

> Every component framework is fighting the same battle: **state that changes over time + DOM that cannot mutate itself**.

Understanding this struggle at the raw level makes framework choices much clearer.
