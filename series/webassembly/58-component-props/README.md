# 58 — Component Props and the #[component] Macro

> **Type:** How-To + Reference

## Defining props

Props are simply the function parameters of a component:

```rust
use leptos::*;

#[component]
fn Button(
    label: String,
    on_click: Callback<()>,
    #[prop(optional)] disabled: bool,  // defaults to false
    #[prop(optional)] class: String,    // defaults to empty string
) -> impl IntoView {
    view! {
        <button
            class=class
            disabled=disabled
            on:click=move |_| on_click.call(())
        >
            {label}
        </button>
    }
}
```

## Prop attributes

| Attribute | Meaning |
|-----------|---------|
| `#[prop(optional)]` | Prop is `Option<T>` under the hood; default is `None` |
| `#[prop(default = value)]` | Specify a default value explicitly |
| `#[prop(into)]` | Auto-convert using `.into()` (e.g., `&str` → `String`) |
| `#[prop(optional, into)]` | Optional + auto-conversion |

## Using `into` for ergonomic strings

```rust
#[component]
fn Heading(
    #[prop(into)] text: String,  // accepts &str, String, and anything Into<String>
) -> impl IntoView {
    view! { <h1>{text}</h1> }
}

// Now you can pass &str directly:
view! { <Heading text="Hello" /> }
```

## Optional props with defaults

```rust
#[component]
fn Card(
    title: String,
    #[prop(default = "text-white".to_string())] text_class: String,
    #[prop(optional)] subtitle: Option<String>,
) -> impl IntoView {
    view! {
        <div class="card">
            <h2 class=text_class>{title}</h2>
            {subtitle.map(|s| view! { <p>{s}</p> })}
        </div>
    }
}
```

## Children as props

```rust
use leptos::Children;

#[component]
fn Panel(
    #[prop(into)] title: String,
    children: Children,
) -> impl IntoView {
    view! {
        <div class="panel">
            <header>{title}</header>
            <main>{children()}</main>
        </div>
    }
}
```

If children might not be provided:
```rust
#[prop(optional)] children: Option<Children>,
// In view: {children.map(|c| c())}
```

## Signal props

Signals are `Copy`, so they can be passed as props without any special handling:

```rust
#[component]
fn Display(count: ReadSignal<i32>) -> impl IntoView {
    view! { <p>{count}</p> }
}

// Parent:
let (count, set_count) = create_signal(0);
view! { <Display count /> }
```

## Callbacks

`Callback<A, R>` is Leptos' wrapper for functions passed as props:

```rust
use leptos::Callback;

#[component]
fn SearchBox(
    on_search: Callback<String>,
) -> impl IntoView {
    let (query, set_query) = create_signal(String::new());
    view! {
        <input
            on:input=move |ev| set_query(event_target_value(&ev))
            on:keydown=move |ev| {
                if ev.key() == "Enter" {
                    on_search.call(query.get());
                }
            }
        />
    }
}

// Usage:
view! {
    <SearchBox on_search=|q| log::info!("Searching: {}", q) />
}
```

## Generated builder API

The `#[component]` macro generates a builder struct for each component:

```rust
// This works because of the generated builder:
view! {
    <Button
        label="Save"
        on_click=|_| log::info!("saved")
        disabled=true
    />
}
```

Internally, it desugars to something like `ButtonProps { label: "Save".to_string(), ... }`.
