# 54 — The view! Macro: Writing HTML in Rust

> **Type:** Explanation + Reference

## What is the view! macro?

`view!` is a procedural macro that lets you write HTML-like syntax inside Rust. It compiles to calls that set up reactive DOM nodes.

```rust
view! {
    <div class="container">
        <h1>"Hello, " {name}</h1>
        <button on:click=handler>"Click me"</button>
    </div>
}
```

This looks like JSX but it is **pure Rust** — parsed and compiled entirely at compile time.

## Text content

Strings in `view!` must be in quotes:
```rust
view! {
    <p>"Static text"</p>
    <p>"Hello, " {name} "!"</p>  // interpolation
}
```

Interpolations `{expr}` can be any expression that implements `IntoView`.

## Attributes

```rust
view! {
    // Static attribute
    <div class="card"></div>

    // Dynamic attribute (reactive)
    <div class=class_name></div>  // class_name is a signal or string

    // Dynamic from a signal
    <input value=input_value />

    // Boolean attributes
    <button disabled=is_disabled>"Submit"</button>
    <input checked=is_checked />

    // Custom data attributes
    <div data-id="42" data-role="admin"></div>

    // Style attribute (object syntax)
    <div style="color: red; font-size: 14px"></div>

    // Dynamic style
    <div style:color=text_color></div>
    <div style:font-size=move || format!("{}px", font_size.get())></div>
}
```

## Event handlers

Prefix event names with `on:`:
```rust
view! {
    <button on:click=|_| log::info!("clicked")>"Click"</button>
    <input on:input=move |ev| set_value(event_target_value(&ev)) />
    <form on:submit=|ev| { ev.prevent_default(); /* handle */ }></form>
}
```

`event_target_value(&ev)` is a helper that extracts `.target.value` from an input event.

## Class directives

```rust
view! {
    // Static class
    <div class="card"></div>

    // Dynamic class toggle:
    // class:name=condition
    <div class:active=is_active class:hidden=move || !is_visible.get()></div>

    // Computed class string
    <div class=move || if is_active.get() { "card active" } else { "card" }></div>
}
```

## Control flow inside view!

Use `{move || ...}` blocks for reactive guards:

```rust
// Conditional
view! {
    {move || if count.get() > 0 {
        view! { <p>"Positive!"</p> }.into_view()
    } else {
        view! { <p>"Zero or below"</p> }.into_view()
    }}
}

// Or use the Show component (lesson 60):
view! {
    <Show when=move || count.get() > 0>
        <p>"Positive!"</p>
    </Show>
}
```

## Loops inside view!

```rust
view! {
    <ul>
        {items.iter().map(|item| view! {
            <li>{item.name.clone()}</li>
        }).collect_view()}
    </ul>

    // Or with a signal-driven list (lesson 61 — <For>):
    <For
        each=move || items.get()
        key=|item| item.id
        children=|item| view! { <li>{item.name}</li> }
    />
}
```

## Special elements

```rust
view! {
    // Fragment (no wrapper element)
    <>
        <p>"First"</p>
        <p>"Second"</p>
    </>

    // Raw HTML (dangerous — only for trusted content)
    <div inner_html=html_string></div>
}
```

## view! limitations

- You cannot use arbitrary Rust control flow inside the HTML portion — only `{expr}` delimited blocks.
- Component names must be uppercase: `<MyComponent>`, not `<myComponent>`.
- Attributes that conflict with Rust keywords use renames: `type` becomes `type_` or is written as `type=`.
