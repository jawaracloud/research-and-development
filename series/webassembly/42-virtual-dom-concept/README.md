# 42 — Building a Minimal Virtual DOM in Rust

> **Type:** Explanation + Tutorial

## What is a virtual DOM?

A Virtual DOM (VDOM) is a lightweight in-memory tree that mirrors the real DOM. Instead of updating the DOM immediately when state changes, you:

1. Re-render to a *new* VDOM tree.
2. **Diff** the new tree against the old tree.
3. Apply only the minimal set of real DOM mutations.

This prevents expensive full re-renders and preserves cursor position, focus, and animation state.

## A minimal VDOM node type

```rust
pub enum VNode {
    Text(String),
    Element {
        tag: String,
        attrs: Vec<(String, String)>,
        children: Vec<VNode>,
    },
}

impl VNode {
    pub fn element(tag: &str) -> Self {
        VNode::Element { tag: tag.to_string(), attrs: vec![], children: vec![] }
    }

    pub fn text(t: &str) -> Self { VNode::Text(t.to_string()) }
    
    pub fn attr(mut self, key: &str, val: &str) -> Self {
        if let VNode::Element { ref mut attrs, .. } = self {
            attrs.push((key.to_string(), val.to_string()));
        }
        self
    }
    
    pub fn child(mut self, child: VNode) -> Self {
        if let VNode::Element { ref mut children, .. } = self {
            children.push(child);
        }
        self
    }
}
```

## Mounting: VDOM → real DOM

```rust
use web_sys::{Document, Element, Node, Text};

pub fn mount(vnode: &VNode, document: &Document) -> Node {
    match vnode {
        VNode::Text(text) => {
            document.create_text_node(text).into()
        }
        VNode::Element { tag, attrs, children } => {
            let el = document.create_element(tag).unwrap();
            for (key, val) in attrs {
                el.set_attribute(key, val).unwrap();
            }
            for child in children {
                let child_node = mount(child, document);
                el.append_child(&child_node).unwrap();
            }
            el.into()
        }
    }
}
```

## Diffing: patch the real DOM

```rust
pub fn patch(parent: &Element, old: &VNode, new: &VNode, index: usize) {
    let doc = web_sys::window().unwrap().document().unwrap();
    let child_node = parent.child_nodes().item(index as u32);

    match (old, new) {
        // 1. Both are text nodes
        (VNode::Text(old_text), VNode::Text(new_text)) => {
            if old_text != new_text {
                if let Some(node) = child_node {
                    node.set_text_content(Some(new_text));
                }
            }
        }
        // 2. Tag changed — replace entirely
        (VNode::Element { tag: old_tag, .. }, VNode::Element { tag: new_tag, .. })
            if old_tag != new_tag =>
        {
            let new_node = mount(new, &doc);
            if let Some(old_node) = child_node {
                parent.replace_child(&new_node, &old_node).unwrap();
            }
        }
        // 3. Same tag — diff attributes and children
        (
            VNode::Element { tag: _, attrs: old_attrs, children: old_children },
            VNode::Element { tag: _, attrs: new_attrs, children: new_children },
        ) => {
            if let Some(node) = child_node {
                let el = node.dyn_into::<Element>().unwrap();
                
                // Update attributes (simplified)
                for (key, val) in new_attrs {
                    el.set_attribute(key, val).unwrap();
                }
                
                // Recursively diff children
                let max = old_children.len().max(new_children.len());
                for i in 0..max {
                    match (old_children.get(i), new_children.get(i)) {
                        (Some(o), Some(n)) => patch(&el, o, n, i),
                        (None, Some(n)) => {
                            el.append_child(&mount(n, &doc)).unwrap();
                        }
                        (Some(_), None) => {
                            if let Some(child) = el.child_nodes().item(i as u32) {
                                el.remove_child(&child).unwrap();
                            }
                        }
                        (None, None) => {}
                    }
                }
            }
        }
        // 4. Node type changed (text ↔ element) — replace
        _ => {
            let new_node = mount(new, &doc);
            if let Some(old_node) = child_node {
                parent.replace_child(&new_node, &old_node).unwrap();
            }
        }
    }
}
```

## Using the mini-VDOM

```rust
use wasm_bindgen::prelude::*;

static mut PREV_TREE: Option<VNode> = None;

fn render_tree(count: i32) -> VNode {
    VNode::element("div")
        .child(VNode::element("h1").child(VNode::text("Counter")))
        .child(VNode::element("p").child(VNode::text(&format!("Count: {}", count))))
        .child(VNode::element("button").attr("id", "btn").child(VNode::text("+")))
}
```

## Why this is valuable to understand

Building a VDOM yourself reveals:
- Diffing is **hard to get right** (key-based list diffing is a major edge case).
- Fine-grained reactivity (Leptos, Solid) avoids needing a VDOM entirely by knowing *exactly* which DOM nodes depend on which state.
