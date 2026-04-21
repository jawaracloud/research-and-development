# 45 — Project: Todo App (No Framework)

> **Type:** Tutorial

## What you will build

A fully functional Todo application compiled to Wasm — no framework, no virtual DOM, only `web-sys` and `wasm-bindgen`. This project consolidates lessons 11–44.

## Features

- Add, complete, and delete todos
- Filter by all / active / completed
- Persist todos to localStorage
- Keyboard support (Enter to add)

## Project structure

```
45-todo-app/
├── Cargo.toml
├── index.html
└── src/
    └── lib.rs
```

## Cargo.toml

```toml
[package]
name = "todo-app"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
wasm-bindgen = "0.2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
console_error_panic_hook = "0.1"

[dependencies.web-sys]
version = "0.3"
features = [
  "Window", "Document", "Element", "HtmlElement",
  "HtmlInputElement", "Node", "Event", "KeyboardEvent",
  "MouseEvent", "Storage", "EventTarget",
]
```

## Core data model

```rust
use serde::{Deserialize, Serialize};
use std::cell::RefCell;

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct Todo {
    pub id: u32,
    pub text: String,
    pub completed: bool,
}

#[derive(Clone, Copy, PartialEq)]
pub enum Filter { All, Active, Completed }

pub struct AppState {
    pub todos: Vec<Todo>,
    pub filter: Filter,
    pub next_id: u32,
}

thread_local! {
    static STATE: RefCell<AppState> = RefCell::new(AppState {
        todos: load_todos(),
        filter: Filter::All,
        next_id: 1,
    });
}
```

## State operations

```rust
pub fn add_todo(text: String) {
    STATE.with(|s| {
        let mut state = s.borrow_mut();
        let id = state.next_id;
        state.next_id += 1;
        state.todos.push(Todo { id, text, completed: false });
        save_todos(&state.todos);
    });
    render();
}

pub fn toggle_todo(id: u32) {
    STATE.with(|s| {
        let mut state = s.borrow_mut();
        if let Some(todo) = state.todos.iter_mut().find(|t| t.id == id) {
            todo.completed = !todo.completed;
        }
        save_todos(&state.todos);
    });
    render();
}

pub fn delete_todo(id: u32) {
    STATE.with(|s| {
        let mut state = s.borrow_mut();
        state.todos.retain(|t| t.id != id);
        save_todos(&state.todos);
    });
    render();
}
```

## Persistence

```rust
fn save_todos(todos: &[Todo]) {
    let json = serde_json::to_string(todos).unwrap();
    web_sys::window().unwrap()
        .local_storage().unwrap().unwrap()
        .set_item("todos", &json).unwrap();
}

fn load_todos() -> Vec<Todo> {
    web_sys::window().unwrap()
        .local_storage().unwrap().unwrap()
        .get_item("todos").unwrap()
        .and_then(|json| serde_json::from_str(&json).ok())
        .unwrap_or_default()
}
```

## Rendering

```rust
pub fn render() {
    STATE.with(|s| {
        let state = s.borrow();
        let doc = web_sys::window().unwrap().document().unwrap();
        let list = doc.get_element_by_id("todo-list").unwrap();
        list.set_inner_html("");

        let visible: Vec<&Todo> = state.todos.iter().filter(|t| match state.filter {
            Filter::All => true,
            Filter::Active => !t.completed,
            Filter::Completed => t.completed,
        }).collect();

        for todo in visible {
            let li = doc.create_element("li").unwrap();
            li.set_attribute("class", if todo.completed { "completed" } else { "" }).unwrap();

            let checkbox = doc.create_element("input").unwrap();
            checkbox.set_attribute("type", "checkbox").unwrap();
            if todo.completed {
                checkbox.set_attribute("checked", "").unwrap();
            }

            let id = todo.id;
            let toggle = Closure::wrap(Box::new(move || toggle_todo(id)) as Box<dyn FnMut()>);
            checkbox.dyn_ref::<web_sys::HtmlElement>().unwrap()
                .set_onclick(Some(toggle.as_ref().unchecked_ref()));
            toggle.forget();

            let label = doc.create_element("label").unwrap();
            label.set_text_content(Some(&todo.text));

            let del_btn = doc.create_element("button").unwrap();
            del_btn.set_text_content(Some("×"));
            let del = Closure::wrap(Box::new(move || delete_todo(id)) as Box<dyn FnMut()>);
            del_btn.dyn_ref::<web_sys::HtmlElement>().unwrap()
                .set_onclick(Some(del.as_ref().unchecked_ref()));
            del.forget();

            li.append_child(&checkbox).unwrap();
            li.append_child(&label).unwrap();
            li.append_child(&del_btn).unwrap();
            list.append_child(&li).unwrap();
        }
    });
}
```

## Entry point

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen(start)]
pub fn start() {
    console_error_panic_hook::set_once();
    setup_input_handler();
    render();
}
```

## Build and run

```bash
wasm-pack build --target web
python3 -m http.server 8080
```

## What this teaches

After completing this, you will deeply appreciate why frameworks like Leptos exist — specifically:
- The verbosity of manual event wiring.
- The difficulty of keeping UI in sync with state.
- The memory management burden of `Closure::forget()`.
