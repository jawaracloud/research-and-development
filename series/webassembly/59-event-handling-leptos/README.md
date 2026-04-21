# 59 — Event Handling in Leptos

> **Type:** How-To + Reference

## The on: syntax

Event handlers in `view!` use the `on:event-name` attribute:

```rust
view! {
    <button on:click=|_| log::info!("clicked")>"Click"</button>
    <input on:input=|_| log::info!("changed") />
    <form on:submit=|ev| { ev.prevent_default(); }></form>
}
```

The value is a closure that receives the event object. Event types are auto-inferred from the event name.

## Accessing event target value

```rust
use leptos::ev;

let (text, set_text) = create_signal(String::new());

view! {
    <input
        on:input=move |ev| {
            set_text(event_target_value(&ev));
        }
    />
    <p>"You typed: " {text}</p>
}
```

`event_target_value(ev)` is a helper from Leptos that reads `.target.value` from any input event.

## Common event helpers

```rust
// event_target_value: reads input/textarea value
let val = event_target_value(&ev); // String

// event_target_checked: reads checkbox state
let checked = event_target_checked(&ev); // bool

// Typed event access:
use leptos::ev::MouseEvent;
let handler = move |ev: MouseEvent| {
    let x = ev.client_x();
    let y = ev.client_y();
};
```

## Preventing defaults

```rust
view! {
    <a href="/link" on:click=|ev| {
        ev.prevent_default();
        // handle navigation in Leptos router instead
    }>
        "Link"
    </a>

    <form on:submit=|ev| {
        ev.prevent_default();
        // handle form submission
    }>
        <button type="submit">"Submit"</button>
    </form>
}
```

## Event delegation

Leptos attaches events directly to elements (no event delegation by default). For large lists, consider using event delegation manually:

```rust
// Add a single listener to the container that handles all child item clicks
view! {
    <ul
        on:click=move |ev| {
            // Find closest <li> that was clicked
            if let Some(target) = ev.target() {
                if let Ok(li) = target.dyn_into::<web_sys::HtmlElement>() {
                    if li.tag_name() == "LI" {
                        let id: i32 = li.dataset().get("id")
                            .and_then(|s| s.parse().ok())
                            .unwrap_or(0);
                        handle_item_click(id);
                    }
                }
            }
        }
    >
        // items rendered here
    </ul>
}
```

## Keyboard events

```rust
view! {
    <input
        on:keydown=move |ev| {
            match ev.key().as_str() {
                "Enter" => submit(),
                "Escape" => clear(),
                "ArrowUp" => navigate_up(),
                "ArrowDown" => navigate_down(),
                _ => {}
            }
        }
    />
}
```

## Global event listeners with `window_event_listener`

```rust
use leptos::window_event_listener;

// In a component body (not inside view!):
window_event_listener(ev::keydown, move |ev: ev::KeyboardEvent| {
    if ev.key() == "k" && ev.meta_key() {
        // Cmd+K shortcut
        open_search();
    }
});
```

`window_event_listener` is automatically cleaned up when the component is unmounted.

## Stopping propagation

```rust
view! {
    <div on:click=|ev| {
        ev.stop_propagation(); // prevents parent click handlers
    }>
        "Inner"
    </div>
}
```
