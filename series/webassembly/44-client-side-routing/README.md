# 44 — Client-Side Routing with the History API

> **Type:** How-To + Tutorial

## What is client-side routing?

In a Single Page Application (SPA), navigation between "pages" doesn't reload the browser. Instead:
1. JavaScript intercepts link clicks.
2. It updates the browser's URL using the **History API**.
3. It renders the appropriate content for the new URL.

The server only serves one HTML file — all routing happens in the browser.

## The History API

```rust
// Get the History object
use web_sys::History;

fn history() -> History {
    web_sys::window().unwrap().history().unwrap()
}

// Push a new route (adds to browser history)
history().push_state_with_url(&JsValue::NULL, "", Some("/about")).unwrap();

// Replace current route (no new history entry)
history().replace_state_with_url(&JsValue::NULL, "", Some("/home")).unwrap();

// Go back/forward
web_sys::window().unwrap().history().unwrap().back().unwrap();
web_sys::window().unwrap().history().unwrap().forward().unwrap();
```

## Getting the current path

```rust
fn current_path() -> String {
    web_sys::window()
        .unwrap()
        .location()
        .pathname()
        .unwrap()
}
```

## Intercepting link clicks

```rust
use wasm_bindgen::JsCast;
use web_sys::{Event, MouseEvent, HtmlAnchorElement};

pub fn intercept_links() {
    let handler = Closure::wrap(Box::new(move |event: MouseEvent| {
        if let Some(target) = event.target() {
            if let Ok(anchor) = target.dyn_into::<HtmlAnchorElement>() {
                let href = anchor.pathname(); // e.g., "/about"
                event.prevent_default();
                navigate(&href);
            }
        }
    }) as Box<dyn FnMut(MouseEvent)>);

    web_sys::window().unwrap().document().unwrap()
        .add_event_listener_with_callback("click", handler.as_ref().unchecked_ref())
        .unwrap();
    handler.forget();
}

pub fn navigate(path: &str) {
    web_sys::window().unwrap()
        .history().unwrap()
        .push_state_with_url(&JsValue::NULL, "", Some(path))
        .unwrap();
    render_route(path);
}
```

## Handling the back button

The `popstate` event fires when the user navigates back/forward:

```rust
use web_sys::PopStateEvent;

let handler = Closure::wrap(Box::new(move |_event: PopStateEvent| {
    let path = current_path();
    render_route(&path);
}) as Box<dyn FnMut(PopStateEvent)>);

web_sys::window().unwrap()
    .add_event_listener_with_callback("popstate", handler.as_ref().unchecked_ref())
    .unwrap();
handler.forget();
```

## A minimal router

```rust
pub fn render_route(path: &str) {
    let doc = web_sys::window().unwrap().document().unwrap();
    let main = doc.get_element_by_id("main").unwrap();
    
    main.set_inner_html(match path {
        "/" | "/home" => "<h1>Home</h1><p>Welcome!</p>",
        "/about" => "<h1>About</h1><p>This is a Wasm SPA.</p>",
        "/posts" => "<h1>Posts</h1><ul><li>Post 1</li></ul>",
        _ => "<h1>404</h1><p>Page not found.</p>",
    });
}
```

## Server configuration

When using client-side routing, your server must redirect all paths to `index.html`. Otherwise, a hard refresh at `/about` returns a 404.

Examples:
- **Nginx**: `try_files $uri /index.html;`
- **Trunk dev server**: handles this automatically.
- **Vercel**: `rewrites` in `vercel.json`.
