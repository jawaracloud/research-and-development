# 60 — Conditional Rendering (Show, match)

> **Type:** How-To + Reference

## Three ways to conditionally render

### 1. `<Show>` component (recommended for simple conditions)

```rust
use leptos::*;

let (logged_in, _) = create_signal(false);

view! {
    <Show
        when=move || logged_in.get()
        fallback=|| view! { <p>"Please log in."</p> }
    >
        <p>"Welcome back!"</p>
    </Show>
}
```

`<Show>` renders `children` when `when` is true, `fallback` when false. The `fallback` prop receives a closure that returns a view.

### 2. `{move || if ... }` block (flexible)

```rust
view! {
    {move || if count.get() > 0 {
        view! { <p class="positive">"Positive: " {count}</p> }.into_view()
    } else if count.get() < 0 {
        view! { <p class="negative">"Negative: " {count}</p> }.into_view()
    } else {
        view! { <p class="zero">"Zero"</p> }.into_view()
    }}
}
```

Note: all branches must call `.into_view()` to unify the type.

### 3. `{move || match ... }` (for enums)

```rust
#[derive(Clone)]
enum Status { Loading, Ready(String), Error(String) }

let (status, _) = create_signal(Status::Loading);

view! {
    {move || match status.get() {
        Status::Loading => view! { <p>"Loading..."</p> }.into_view(),
        Status::Ready(data) => view! { <p>{data}</p> }.into_view(),
        Status::Error(msg) => view! { <p class="error">{msg}</p> }.into_view(),
    }}
}
```

## Show vs if block — which to use?

| Situation | Use |
|-----------|-----|
| Simple true/false with fallback | `<Show>` |
| More than two branches | `{move || if...else if...}` |
| Matching an enum | `{move || match ...}` |
| No fallback needed | `{move || condition.then(|| view! {...})}` |

## The `then` shorthand

For "render if true, nothing if false":

```rust
view! {
    {move || (count.get() > 10).then(|| view! {
        <div class="badge">"High count!"</div>
    })}
}
```

## Showing vs hiding with CSS

Sometimes you want to keep the element in the DOM but hide it (to preserve focus, animations, etc.):

```rust
view! {
    <div
        class:hidden=move || !show_panel.get()
        // or:
        style:display=move || if show_panel.get() { "block" } else { "none" }
    >
        "Panel content"
    </div>
}
```

## Conditional class application

```rust
view! {
    <button
        class="btn"
        class:btn-primary=move || is_primary.get()
        class:btn-disabled=move || is_disabled.get()
        disabled=move || is_disabled.get()
    >
        "Submit"
    </button>
}
```

## Lazy rendering with Show

`<Show>` by default does NOT immediately destroy and recreate its children when toggled — it keeps the children mounted once first shown. To eagerly destroy/recreate:

```rust
<Show
    when=move || show.get()
    // Children are remounted every time `show` becomes true
    fallback=|| ()
>
    <ExpensiveComponent />
</Show>
```

For full lazy mounting (never mount until shown for the first time), use `Suspense` with a lazy resource (lesson 68).
