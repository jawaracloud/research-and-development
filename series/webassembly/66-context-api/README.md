# 66 — Global State with the Context API

> **Type:** How-To + Explanation

## Why a context API?

Passing signals as props works well within a component tree. But when many unrelated components need the same state (theme, current user, cart, locale), prop-drilling becomes painful. Leptos's context API is the solution.

## provide_context / use_context

```rust
use leptos::*;

// Provider: provide state at the top of the tree
#[component]
fn App() -> impl IntoView {
    let (theme, set_theme) = create_signal("dark".to_string());
    provide_context(theme);
    provide_context(set_theme);

    view! {
        <Router>
            <Routes>
                <Route path="/" view=HomePage />
            </Routes>
        </Router>
    }
}

// Consumer: any component in the tree can access it
#[component]
fn ThemeToggle() -> impl IntoView {
    let theme = use_context::<ReadSignal<String>>()
        .expect("theme context must be provided");
    let set_theme = use_context::<WriteSignal<String>>()
        .expect("theme setter context must be provided");

    view! {
        <button on:click=move |_| {
            set_theme.update(|t| {
                *t = if t == "dark" { "light".into() } else { "dark".into() }
            });
        }>
            "Toggle theme: " {theme}
        </button>
    }
}
```

## Pattern: typed context struct

Wrap related signals in a struct for clarity:

```rust
#[derive(Clone, Copy)]
struct AuthContext {
    pub user: ReadSignal<Option<User>>,
    pub set_user: WriteSignal<Option<User>>,
    pub is_authenticated: Memo<bool>,
}

impl AuthContext {
    pub fn new() -> Self {
        let (user, set_user) = create_signal(None::<User>);
        let is_authenticated = create_memo(move |_| user.get().is_some());
        AuthContext { user, set_user, is_authenticated }
    }
}

// In App:
provide_context(AuthContext::new());

// In any child:
let auth = use_context::<AuthContext>().expect("auth context");
let is_logged_in = auth.is_authenticated;
```

## Pattern: store pattern with context

For complex domain state:

```rust
#[derive(Clone, Copy)]
struct CartStore {
    pub items: RwSignal<Vec<CartItem>>,
}

impl CartStore {
    pub fn add(&self, item: CartItem) {
        self.items.update(|v| v.push(item));
    }

    pub fn remove(&self, id: u32) {
        self.items.update(|v| v.retain(|i| i.id != id));
    }

    pub fn total(&self) -> f64 {
        self.items.get().iter().map(|i| i.price * i.quantity as f64).sum()
    }
}

// Provide:
provide_context(CartStore { items: create_rw_signal(vec![]) });

// Use:
let cart = use_context::<CartStore>().expect("cart store");
cart.add(item);
```

## Global signal (simplest)

For simple boolean flags (modal open, sidebar visible):

```rust
// In App
provide_context(create_rw_signal(false)); // sidebar open

// In Sidebar button
let sidebar = use_context::<RwSignal<bool>>().expect("sidebar signal");
view! {
    <button on:click=move |_| sidebar.update(|v| *v = !*v)>
        "Toggle sidebar"
    </button>
}
```

## When to use context vs props

| Signal travels | Use |
|---------------|-----|
| Parent → immediate child | Props |
| Parent → grandchild+ (several levels) | Props (if < 3 levels) |
| Many unrelated components at different levels | Context |
| App-wide settings (theme, locale, auth) | Context |

## Context vs crates like `leptos-use`

For complex global state beyond what context handles elegantly, the `leptos-use` crate provides utilities like `use_storage` (reactive localStorage), `use_websocket`, `use_media_query`, etc.

```toml
[dependencies]
leptos-use = "0.13"
```

```rust
use leptos_use::storage::use_local_storage;

let (value, set_value, _) = use_local_storage::<String>("my-key");
```
