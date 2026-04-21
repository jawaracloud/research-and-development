# 74 — Hydration: Connecting Server HTML to Client Wasm

> **Type:** Explanation + How-To

## What is hydration?

Hydration is the process by which the Wasm bundle attaches event listeners and reactive state to the HTML that was rendered by the server. Rather than erasing and recreating the DOM, Leptos **walks the existing DOM** and connects signals to it.

```
Server sends:   <button id="b-1">Count: 0</button>

Wasm receives:  DOM already has button "b-1"
                → attaches click handler
                → creates signal pointing at button's text
                → NO DOM replacement happens
```

## Setting up hydration

### lib.rs (browser entry point)

```rust
// src/lib.rs
#[cfg(feature = "hydrate")]
#[wasm_bindgen::prelude::wasm_bindgen(start)]
pub fn hydrate() {
    use crate::app::App;
    console_error_panic_hook::set_once();
    
    // leptos::hydrate_body replaces leptos::mount_to_body for SSR+hydration
    leptos::hydrate_body(App);
}
```

### Cargo.toml features

```toml
[features]
hydrate = ["leptos/hydrate"]
ssr = ["leptos/ssr", "leptos_axum"]
```

### index.html

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>App</title>
  <!-- Trunk injects Wasm here for CSR -->
  <!-- cargo-leptos injects the hydration bundle for SSR+hydrate -->
</head>
<body>
  <!-- Server renders the full app HTML here -->
  <!-- Wasm will hydrate this on load -->
</body>
</html>
```

## Hydration markers

Leptos automatically inserts invisible HTML comments to help the Wasm hydrate correctly:

```html
<!--hk=0-0|leptos-->
<main>
<!--hk=1-0|leptos-->
<h1>Hello</h1>
<!--hk=2-0|leptos-->
</main>
```

These `<!--hk=...-->` comments are the "hydration keys" that map server-rendered nodes to Leptos's component tree. Never remove or modify them manually.

## Common hydration mismatches

A **hydration mismatch** occurs when the server HTML doesn't match what Wasm would render:

| Cause | Fix |
|-------|-----|
| Random values (UUID, timestamps) | Generate the same value on both sides |
| Date rendering differs by timezone | Use UTC on server, format on client |
| Browser-only APIs called during render | Guard with `#[cfg(not(feature = "ssr"))]` |
| Async data loaded differently | Use `create_resource` (not bare `async` in render) |

Example of a mismatch:
```rust
// ❌ This produces different output each time
view! { <p>{js_sys::Math::random().to_string()}</p> }

// ✅ Use a signal instead, set after hydration
let (id, set_id) = create_signal(String::new());
create_effect(move |_| set_id(generate_id())); // runs only in browser
view! { <p>{id}</p> }
```

## Checking if running in browser vs server

```rust
#[cfg(not(feature = "ssr"))]
fn browser_only_setup() {
    // This code does NOT compile on the server
}

// At runtime:
use leptos::DomHelper;
if leptos::is_browser() {
    // Access web APIs
}

// Or use a signal that starts false, sets true in effect:
let (is_client, set_is_client) = create_signal(false);
create_effect(move |_| set_is_client(true));
```

## Island architecture (partial hydration)

In Leptos 0.7+, "islands" allow most of the page to be static HTML (fast, no Wasm needed) and only specific interactive components ("islands") to hydrate:

```rust
#[island]  // instead of #[component]
fn Counter() -> impl IntoView {
    let (count, set_count) = create_signal(0);
    view! {
        <button on:click=move |_| set_count.update(|n| *n += 1)>
            {count}
        </button>
    }
}
```

Islands load Wasm only for themselves, not the whole page — significantly reducing Wasm payload for content-heavy sites.
