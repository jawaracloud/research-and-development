# 63 — Styling Leptos Components

> **Type:** How-To + Reference

## Approach 1: External CSS + class binding

The default and most portable approach: write a CSS file, reference classes in `view!`.

```css
/* style.css */
.card { background: #1e1e2e; border-radius: 8px; padding: 1rem; }
.card.active { border: 2px solid #cba6f7; }
.btn-primary { background: #cba6f7; color: #1e1e2e; }
```

```rust
view! {
    <div class="card" class:active=is_active>
        <button class="btn-primary">"Confirm"</button>
    </div>
}
```

**With Trunk:**
```html
<link data-trunk rel="css" href="style.css" />
```

## Approach 2: Dynamic class strings

For computed classes based on state:

```rust
view! {
    <div class=move || {
        let mut classes = vec!["card"];
        if is_active.get() { classes.push("active"); }
        if is_loading.get() { classes.push("skeleton"); }
        classes.join(" ")
    }>
        "Content"
    </div>
}
```

## Approach 3: Inline style object syntax

```rust
view! {
    <div
        style:background=move || if dark.get() { "#1e1e2e" } else { "#eff1f5" }
        style:color=move || if dark.get() { "#cdd6f4" } else { "#4c4f69" }
        style:border-radius="8px"
        style:padding="1rem"
    >
        "Themed card"
    </div>
}
```

Use `style:property-name=value` for individual properties.

## Approach 4: Tailwind CSS

```bash
npm install -D tailwindcss @tailwindcss/typography
npx tailwindcss init
```

`tailwind.config.js`:
```javascript
module.exports = {
    content: ["./src/**/*.rs", "./index.html"],
    theme: { extend: {} },
}
```

`Trunk.toml`:
```toml
[[hooks]]
stage = "pre_build"
command = "npx"
command_arguments = ["tailwindcss", "-i", "./input.css", "-o", "./style/tailwind.css", "--minify"]
```

```rust
view! {
    <div class="bg-slate-900 rounded-xl p-4 text-slate-100 hover:shadow-lg transition-shadow">
        <h2 class="text-purple-400 font-bold text-xl">"Title"</h2>
    </div>
}
```

## Approach 5: stylers (scoped CSS)

Scopes CSS to the component with auto-generated class hashes:

```toml
[dependencies]
stylers = "0.13"
```

```rust
use stylers::style;
use leptos::*;

#[component]
fn Card(title: String) -> impl IntoView {
    let class = style! {
        div.card {
            background: #1e1e2e;
            border-radius: 8px;
            padding: 1rem;
        }
        h2 {
            color: #cba6f7;
            font-size: 1.2rem;
        }
    };

    view! {
        class=class,  // applies the scoped hash class
        <div class="card">
            <h2>{title}</h2>
        </div>
    }
}
```

CSS is extracted at compile time and injected into a `<style>` tag — no runtime overhead.

## CSS Custom Properties from Rust

Set design tokens at the root level, consume in CSS:

```rust
create_effect(move |_| {
    let root = document().document_element().unwrap()
        .dyn_into::<web_sys::HtmlElement>().unwrap();
    let style = root.style();
    let primary = if dark_mode.get() { "#cba6f7" } else { "#7c3aed" };
    style.set_property("--color-primary", primary).unwrap();
});
```

```css
button { background: var(--color-primary); }
```

## Recommendation matrix

| Project type | Recommended styling |
|-------------|-------------------|
| Small app / prototype | External CSS |
| Leptos component library | `stylers` (scoped) |
| Design system with utility classes | Tailwind |
| Dynamic themes / user-configurable colors | CSS custom properties |
| Runtime animations | `style:property` in view! |
