# 81 — Code Splitting and Lazy Loading

> **Type:** How-To + Explanation

## Why code splitting?

A full Leptos app's Wasm binary can grow large. Code splitting (lazy loading) defers loading parts of the app until they're needed — e.g., loading the admin dashboard only when an admin navigates to it.

## Route-based code splitting with leptos_router

Leptos supports lazy-loaded route components via `view` closures and conditional resource loading:

```rust
use leptos::*;
use leptos_router::*;

// Heavy component that shouldn't load on the home page
#[component]
fn AdminPanel() -> impl IntoView {
    view! { <h1>"Admin Panel"</h1> }
}

#[component]
fn App() -> impl IntoView {
    view! {
        <Router>
            <Routes>
                <Route path="/" view=HomePage />
                // Admin panel only loads when /admin is visited:
                <Route path="/admin" view=AdminPanel />
            </Routes>
        </Router>
    }
}
```

For true Wasm code splitting (separate `.wasm` files), you need `wasm-bindgen`'s `start` method and dynamic `import()` — currently experimental in stable Leptos.

## Lazy data loaded via Resources

More common is lazy *data* loading — defer fetching until the component is visible:

```rust
#[component]
fn ReportPage() -> impl IntoView {
    // Data loads only when this component mounts (route is navigated to)
    let report = create_resource(|| (), |_| async { fetch_heavy_report().await });

    view! {
        <Suspense fallback=|| view! { <p>"Loading report..."</p> }>
            {move || report.get().map(|r| view! { <ReportTable data=r /> })}
        </Suspense>
    }
}
```

## Intersection Observer for lazy rendering

Render heavy list items only when they scroll into view:

```rust
use web_sys::{IntersectionObserver, IntersectionObserverEntry};

fn use_visible(element_id: &'static str) -> ReadSignal<bool> {
    let (visible, set_visible) = create_signal(false);

    create_effect(move |_| {
        let callback = Closure::wrap(Box::new(move |entries: js_sys::Array, _: IntersectionObserver| {
            let entry = entries.get(0).dyn_into::<IntersectionObserverEntry>().unwrap();
            set_visible(entry.is_intersecting());
        }) as Box<dyn FnMut(js_sys::Array, IntersectionObserver)>);

        let observer = IntersectionObserver::new(
            callback.as_ref().unchecked_ref()
        ).unwrap();

        if let Some(el) = document().get_element_by_id(element_id) {
            observer.observe(&el);
        }
        callback.forget();
    });

    visible
}
```

## Wasm binary size strategy

Before splitting, shrink the main bundle first:

```toml
# Cargo.toml
[profile.release]
opt-level = 'z'     # optimize for size
lto = true
codegen-units = 1
panic = "abort"
strip = "symbols"

[profile.release.package."*"]
opt-level = 'z'
```

```bash
# Post-process with wasm-opt
wasm-opt -Oz -o output.wasm input.wasm
```

## `twiggy` for size analysis

```bash
cargo install twiggy
wasm-pack build --release
twiggy top target/pkg/myapp_bg.wasm
```

Sample output:
```
 Shallow Bytes │ Shallow % │ Item
───────────────┼───────────┼──────────────────
        65,432 │    24.3%  │ core::fmt (monomorphized)
        51,209 │    19.0%  │ regex::internal::exec
        32,418 │    12.0%  │ serde_json::de
```

Use this to find which crates are bloating your binary — often `serde_json` or `regex`.

## Splitting large crates out

If `regex` is huge but only used in one place, split it to a separate server function (runs on server, not in Wasm):

```rust
#[server(ValidatePattern, "/api")]
pub async fn validate_pattern(text: String, pattern: String) -> Result<bool, ServerFnError> {
    // regex runs on server — not in Wasm binary
    let re = regex::Regex::new(&pattern)
        .map_err(|e| ServerFnError::ServerError(e.to_string()))?;
    Ok(re.is_match(&text))
}
```
