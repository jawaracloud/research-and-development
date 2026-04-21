# 53 — Your First Leptos Component

> **Type:** Tutorial

## What is a component?

In Leptos, a **component** is a Rust function annotated with `#[component]` that returns `impl IntoView`. It describes a piece of UI. Components are composable and reactive.

## The minimal component

```rust
use leptos::*;

#[component]
fn Hello() -> impl IntoView {
    view! {
        <p>"Hello from a Leptos component!"</p>
    }
}
```

That's it. No `render` method, no lifecycle hooks, no class — just a function.

## Key rules

1. The function must be `pub` if used from another module.
2. It must be annotated with `#[component]`.
3. It must return `impl IntoView` (not a concrete type).
4. Component names must start with an uppercase letter (to distinguish `<MyComponent>` from `<div>`).

## Composing components

```rust
#[component]
fn Greeting(name: String) -> impl IntoView {
    view! {
        <p>"Hello, " {name} "!"</p>
    }
}

#[component]
fn App() -> impl IntoView {
    view! {
        <main>
            <h1>"My App"</h1>
            <Greeting name="Alice".to_string() />
            <Greeting name="Bob".to_string() />
        </main>
    }
}
```

## Mounting to the DOM

```rust
pub fn main() {
    leptos::mount_to_body(App);
}
```

This replaces the `<body>` with your app. For mounting somewhere specific:

```rust
use leptos::*;

pub fn main() {
    let mount_point = web_sys::window()
        .unwrap()
        .document()
        .unwrap()
        .get_element_by_id("app")
        .unwrap();

    mount_to(mount_point.unchecked_into(), App);
}
```

## Component lifecycle

Leptos components are **not** re-rendered like React components. A component function runs **once** when the component mounts. Any reactive behavior (things that change) is handled by signals and effects *inside* the component — not by re-calling the component function.

```rust
#[component]
fn Counter() -> impl IntoView {
    // This runs ONCE when the component mounts:
    let (count, set_count) = create_signal(0);

    // The view is set up ONCE.
    // Only the reactive parts ({count}) update when count changes.
    view! {
        <button on:click=move |_| set_count.update(|n| *n += 1)>
            "Count: " {count}
        </button>
    }
}
```

Compare to React, where the whole component function re-runs on each state change. In Leptos, only `{count}` in the DOM is updated.

## Children

```rust
#[component]
fn Card(children: Children) -> impl IntoView {
    view! {
        <div class="card">
            {children()}
        </div>
    }
}

// Usage:
view! {
    <Card>
        <h2>"Title"</h2>
        <p>"Body text"</p>
    </Card>
}
```

`Children` is a special prop type that represents the children passed to a component.

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Component name is lowercase | Must be uppercase: `fn MyComponent` not `fn myComponent` |
| Returning a concrete type | Return `impl IntoView`, not `HtmlElement` |
| Calling the component function directly | Use `<MyComponent />` in `view!`, not `MyComponent()` |
| Expecting component to re-run on state change | It doesn't — use signals for reactivity |
