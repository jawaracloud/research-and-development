# 69 — Error Boundaries and Recovery

> **Type:** How-To + Explanation

## What is an Error Boundary?

An **error boundary** is a component that catches errors from its children and displays a fallback UI instead of crashing the entire app.

In Leptos, errors come from resources that return `Result<T, E>`.

## Creating an error boundary

```rust
use leptos::*;

// A resource that may fail
async fn fetch_data() -> Result<Vec<String>, String> {
    let response = reqwest::get("https://api.example.com/data")
        .await
        .map_err(|e| e.to_string())?;

    if !response.status().is_success() {
        return Err(format!("HTTP {}", response.status()));
    }

    response.json().await.map_err(|e| e.to_string())
}

#[component]
fn DataDisplay() -> impl IntoView {
    let data = create_resource(|| (), |_| async { fetch_data().await });

    view! {
        <ErrorBoundary
            fallback=|errors| view! {
                <div class="error-container">
                    <h2>"Something went wrong"</h2>
                    <ul>
                        {move || errors.get().into_iter().map(|(_, e)| view! {
                            <li class="error-msg">{e.to_string()}</li>
                        }).collect_view()}
                    </ul>
                    <button on:click=move |_| errors.clear()>"Dismiss"</button>
                </div>
            }
        >
            <Suspense fallback=|| view! { <p>"Loading..."</p> }>
                {move || data.get().map(|result| match result {
                    Ok(items) => view! {
                        <ul>{items.iter().map(|item| view! {
                            <li>{item}</li>
                        }).collect_view()}</ul>
                    }.into_view(),
                    Err(e) => view! {
                        // Throwing an error to the boundary
                        {Err::<(), _>(e.clone())}
                    }.into_view(),
                })}
            </Suspense>
        </ErrorBoundary>
    }
}
```

## The `errors` signal in fallback

The `fallback` closure receives an `Errors` object — a reactive map of errors:

```rust
fallback=|errors| view! {
    <div>
        // Total error count
        <p>{move || errors.get().len()} " error(s)"</p>

        // List all errors
        {move || errors.get().into_iter().map(|(id, err)| view! {
            <p>
                "Error " {format!("{:?}", id)} ": " {err.to_string()}
            </p>
        }).collect_view()}

        // Clear all errors (shows children again)
        <button on:click=move |_| errors.clear()>"Retry"</button>
    </div>
}
```

## Retry pattern

```rust
let (retry_count, set_retry_count) = create_signal(0u32);

let data = create_resource(
    move || retry_count.get(), // refetch when retry_count changes
    |_| async { fetch_data().await },
);

view! {
    <ErrorBoundary
        fallback=move |_errors| view! {
            <div class="error-box">
                <p>"Failed to load data"</p>
                <button on:click=move |_| {
                    set_retry_count.update(|n| *n += 1);
                }>
                    "Retry"
                </button>
            </div>
        }
    >
        <Suspense fallback=|| view! { <p>"Loading..."</p> }>
            {move || data.get().map(|r| r.map(|items| view! {
                <ul>{items.iter().map(|i| view! { <li>{i}</li> }).collect_view()}</ul>
            }))}
        </Suspense>
    </ErrorBoundary>
}
```

## Global error handling with on_error

For logging errors to a monitoring service:

```rust
#[wasm_bindgen(start)]
pub fn main() {
    console_error_panic_hook::set_once();
    mount_to_body(App);
}
```

For Leptos-level errors you can create a global error context:

```rust
provide_context(create_rw_signal::<Vec<String>>(vec![]));
```

Then push to it from anywhere to display a toast notification.

## toast notification pattern

```rust
#[derive(Clone)]
struct Toast { id: u32, message: String, error: bool }

#[derive(Clone, Copy)]
struct ToastStore(RwSignal<Vec<Toast>>);

impl ToastStore {
    fn show_error(&self, msg: String) {
        let id = js_sys::Date::now() as u32;
        self.0.update(|v| v.push(Toast { id, message: msg, error: true }));
        let store = *self;
        gloo::timers::callback::Timeout::new(5000, move || {
            store.0.update(|v| v.retain(|t| t.id != id));
        }).forget();
    }
}
```
