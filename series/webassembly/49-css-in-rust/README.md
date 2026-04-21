# 49 — Styling Strategies: CSS-in-Rust Approaches

> **Type:** Explanation + How-To

## The styling problem

Rust Wasm apps separate structure (Rust), behavior (Rust/Wasm), and styling (CSS). Unlike JavaScript frameworks that have mature CSS-in-JS solutions, Rust has fewer options — but what exists is solid.

## Strategy 1: External CSS files (recommended default)

The simplest approach: write a `.css` file and link it from HTML. Works with any build tool.

**With Trunk:**
```html
<!-- index.html -->
<link data-trunk rel="css" href="style.css" />
```

Good for: most projects. No overhead, full CSS feature support, great tooling.

## Strategy 2: Inline styles via `web-sys`

```rust
use wasm_bindgen::JsCast;
use web_sys::HtmlElement;

let el = element.dyn_into::<HtmlElement>().unwrap();
let style = el.style();
style.set_property("color", "red").unwrap();
style.set_property("background", "linear-gradient(to right, #1e1e2e, #313244)").unwrap();
style.set_property("border-radius", "8px").unwrap();
```

Good for: runtime-computed styles (animations, dynamic colors).

## Strategy 3: CSS classes for state

Prefer toggling CSS classes rather than setting inline styles:

```rust
let class_list = el.class_list();

// Add
class_list.add_1("active").unwrap();

// Remove
class_list.remove_1("hidden").unwrap();

// Toggle
class_list.toggle("open").unwrap();

// Check
let is_active = class_list.contains("active");
```

Good for: state-based styling (active tab, open dropdown, error state).

## Strategy 4: Leptos `stylers` crate (scoped CSS)

For Leptos projects, `stylers` provides scoped CSS that is extracted at compile time:

```toml
[dependencies]
stylers = "0.13"
```

```rust
use leptos::*;
use stylers::style;

#[component]
pub fn Card(title: String) -> impl IntoView {
    let class_name = style! {
        div.card {
            background: #1e1e2e;
            border-radius: 8px;
            padding: 16px;
        }
        h2 {
            color: #cba6f7;
            font-size: 1.2rem;
        }
    };

    view! {
        <div class=class_name.clone()>
            <h2>{title}</h2>
        </div>
    }
}
```

CSS is scoped to the component by a generated hash class, preventing style leakage.

## Strategy 5: Tailwind with Leptos

```toml
[dependencies]
leptos = { version = "0.7", features = ["csr"] }
```

`Trunk.toml`:
```toml
[[hooks]]
stage = "pre_build"
command = "npx"
command_arguments = ["tailwindcss", "-i", "input.css", "-o", "style.css"]
```

```rust
view! {
    <div class="bg-gray-900 rounded-lg p-4 text-purple-300 hover:scale-105 transition">
        {title}
    </div>
}
```

Good for: teams already using Tailwind, rapid prototyping.

## Decision guide

| Situation | Recommendation |
|-----------|---------------|
| Small/medium project | External CSS |
| Dynamic, computed styles | `web-sys` inline styles |
| Component state changes | CSS class toggling |
| Leptos app, scoped styles | `stylers` |
| Leptos app, utility-first | Tailwind |
| Design system | CSS custom properties + external CSS |

## CSS custom properties (variables) + Rust

Control design tokens from Rust at runtime:

```rust
let root = web_sys::window().unwrap().document().unwrap()
    .document_element().unwrap()
    .dyn_into::<web_sys::HtmlElement>().unwrap();

let style = root.style();
style.set_property("--primary", "#cba6f7").unwrap();
style.set_property("--font-size", "18px").unwrap();
```

CSS:
```css
button { background: var(--primary); font-size: var(--font-size); }
```

This is a clean separation: CSS owns the design, Rust owns the logic that selects which values to use.
