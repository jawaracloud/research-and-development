# 43 — State Management Without a Framework

> **Type:** How-To + Explanation

## The challenge

State in browsers is inherently mutable. Rust's ownership rules and the single-threaded Wasm environment create friction. The idiomatic Wasm solution for shared mutable state is `Rc<RefCell<T>>`.

## Pattern 1: `Rc<RefCell<T>>` (shared single-threaded state)

```rust
use std::cell::RefCell;
use std::rc::Rc;

#[derive(Debug, Clone)]
pub struct AppState {
    pub count: i32,
    pub name: String,
    pub items: Vec<String>,
}

impl AppState {
    pub fn new() -> Self {
        AppState { count: 0, name: String::new(), items: vec![] }
    }
}

// Create shared state
let state = Rc::new(RefCell::new(AppState::new()));

// Clone the Rc to share it with closures
let state_for_btn = state.clone();
let handler = Closure::wrap(Box::new(move || {
    state_for_btn.borrow_mut().count += 1;
    re_render(&state_for_btn.borrow());
}) as Box<dyn FnMut()>);
```

## Pattern 2: Thread-local global state

For application-wide state that doesn't need to be passed around:

```rust
use std::cell::RefCell;

thread_local! {
    static APP_STATE: RefCell<AppState> = RefCell::new(AppState::new());
}

pub fn increment() {
    APP_STATE.with(|s| s.borrow_mut().count += 1);
    re_render();
}

pub fn get_count() -> i32 {
    APP_STATE.with(|s| s.borrow().count)
}
```

Since Wasm is single-threaded, `thread_local!` is essentially a safe global.

## Pattern 3: Store + subscription (Observer pattern)

```rust
use std::cell::RefCell;
use std::rc::Rc;

pub struct Store<T> {
    state: Rc<RefCell<T>>,
    subscribers: Rc<RefCell<Vec<Box<dyn Fn(&T)>>>>,
}

impl<T: Clone> Store<T> {
    pub fn new(initial: T) -> Self {
        Store {
            state: Rc::new(RefCell::new(initial)),
            subscribers: Rc::new(RefCell::new(vec![])),
        }
    }

    pub fn subscribe(&self, f: impl Fn(&T) + 'static) {
        self.subscribers.borrow_mut().push(Box::new(f));
    }

    pub fn update(&self, f: impl FnOnce(&mut T)) {
        f(&mut self.state.borrow_mut());
        let state = self.state.borrow();
        for subscriber in self.subscribers.borrow().iter() {
            subscriber(&state);
        }
    }

    pub fn get(&self) -> std::cell::Ref<T> {
        self.state.borrow()
    }
}
```

Usage:
```rust
let store = Store::new(AppState::new());

// Subscribe a render function
store.subscribe(|state| {
    let el = web_sys::window().unwrap().document().unwrap()
        .get_element_by_id("counter").unwrap();
    el.set_text_content(Some(&format!("Count: {}", state.count)));
});

// Dispatch updates
store.update(|s| s.count += 1);
```

## Comparison with framework approaches

| Approach | Framework equivalent |
|---------|-------------------|
| `Rc<RefCell<T>>` | React `useRef` |
| `thread_local! + RefCell` | React `Context` / Zustand global store |
| Store + subscribers | Redux / Zustand |
| Fine-grained signals | Leptos `create_signal`, Solid.js signals |

## The takeaway

Every state management approach eventually involves some form of:
1. **Container** — where the state lives.
2. **Mutator** — how to change it.
3. **Notifier** — how UI is told to update.

Leptos signals (Part 2 of this series) implement all three automatically. Understanding the manual version makes signals click immediately.
