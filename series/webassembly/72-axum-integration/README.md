# 72 — Integrating Leptos with Axum

> **Type:** Tutorial

## Setup

```toml
[workspace]
members = ["app"]

[package]
name = "app"
version = "0.1.0"
edition = "2021"

[features]
ssr = ["leptos/ssr", "leptos_axum/ssr", "dep:axum", "dep:tokio"]
hydrate = ["leptos/hydrate"]

[dependencies]
leptos = { version = "0.7" }
leptos_router = { version = "0.7" }
leptos_axum = { version = "0.7", optional = true }
axum = { version = "0.7", optional = true, features = ["macros"] }
tokio = { version = "1", features = ["full"], optional = true }
serde = { version = "1", features = ["derive"] }
console_error_panic_hook = "0.1"
wasm-bindgen = "0.2"
```

## App component (shared)

```rust
// src/app.rs — runs on both server AND browser
use leptos::*;
use leptos_router::*;

#[component]
pub fn App() -> impl IntoView {
    view! {
        <Router>
            <Routes>
                <Route path="/" view=HomePage />
                <Route path="/about" view=AboutPage />
            </Routes>
        </Router>
    }
}

#[component]
fn HomePage() -> impl IntoView {
    view! { <h1>"Welcome!"</h1> }
}

#[component]
fn AboutPage() -> impl IntoView {
    view! { <h1>"About"</h1> }
}
```

## Server entry point

```rust
// src/main.rs (compiled only with feature "ssr")
#[cfg(feature = "ssr")]
#[tokio::main]
async fn main() {
    use axum::Router;
    use leptos::get_configuration;
    use leptos_axum::{generate_route_list, LeptosRoutes};

    let conf = get_configuration(None).await.unwrap();
    let leptos_options = conf.leptos_options;
    let addr = leptos_options.site_addr;

    // Generate routes from Leptos router
    let routes = generate_route_list(App);

    let app = Router::new()
        .leptos_routes(&leptos_options, routes, App)
        .fallback(leptos_axum::file_and_error_handler(shell))
        .with_state(leptos_options);

    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

#[cfg(feature = "ssr")]
async fn shell(options: axum::extract::State<leptos::LeptosOptions>) -> axum::response::Response {
    use leptos_axum::render_app_to_stream;
    render_app_to_stream(options.0.clone(), App).await
}
```

## Browser entry point

```rust
// src/lib.rs (for Wasm / hydrate feature)
#[cfg(feature = "hydrate")]
#[wasm_bindgen::prelude::wasm_bindgen(start)]
pub fn hydrate() {
    use crate::app::App;
    console_error_panic_hook::set_once();
    leptos::mount_to_body(App);
}
```

## Leptos.toml

```toml
[package]
name = "app"
bin-features = ["ssr"]
lib-features = ["hydrate"]

[package.metadata.leptos]
output-name = "app"
site-root = "target/site"
site-pkg-dir = "pkg"
site-addr = "127.0.0.1:3000"
reload-port = 3001
end2end-cmd = "npx playwright test"
end2end-dir = "end2end"
browserquery = "defaults"
watch = false
env = "DEV"
bin-default-features = false
lib-default-features = false
```

## Serving static files and the Wasm package

`leptos_axum::file_and_error_handler` serves the Wasm package and all static assets automatically. Your Leptos options configure `site-root` where they're placed at build time.

## Running in development

```bash
# Install cargo-leptos if not installed
cargo install cargo-leptos

# Run with hot reload
cargo leptos watch
```

## Adding custom Axum routes

```rust
let app = Router::new()
    // Custom REST API endpoints:
    .route("/api/health", axum::routing::get(health_check))
    .route("/api/users", axum::routing::get(list_users))
    // Leptos SSR routes:
    .leptos_routes(&leptos_options, routes, App)
    .with_state(leptos_options);

async fn health_check() -> &'static str { "OK" }
```

## State sharing between Axum and Leptos

Use `provide_context` inside the Leptos handler to give components access to server-side state (e.g., DB pool):

```rust
let app = Router::new()
    .leptos_routes_with_context(
        &leptos_options,
        routes,
        move || provide_context(pool.clone()),
        App,
    )
    .with_state(leptos_options);
```

Then in any server-side component or server function:
```rust
let pool = use_context::<sqlx::PgPool>().expect("pool must be provided");
```
