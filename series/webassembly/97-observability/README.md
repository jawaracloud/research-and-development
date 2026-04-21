# 97 — Error Monitoring, Logging, and Observability

> **Type:** How-To + Reference

## Three pillars of observability

| Pillar | Tool | What it answers |
|--------|------|-----------------|
| **Logging** | `tracing`, `console_log`, Loki | "What happened?" |
| **Metrics** | Prometheus, OpenTelemetry | "How much / how often?" |
| **Tracing** | OpenTelemetry, Jaeger | "Which request caused it?" |

## Client-side logging (Wasm)

```toml
[dependencies]
log = "0.4"
console_log = "1"
console_error_panic_hook = "0.1"
```

```rust
#[wasm_bindgen(start)]
pub fn start() {
    // Capture panics with useful stack traces
    console_error_panic_hook::set_once();

    // Initialize logger (shows in browser console)
    console_log::init_with_level(log::Level::Debug)
        .expect("failed to init logger");

    log::info!("App started");
    leptos::mount_to_body(App);
}
```

Browser Console will show:
```
[INFO] App started
[DEBUG] Component mounted: UserList
[WARN] Slow render: TodoItem took 150ms
[ERROR] Failed to fetch: network timeout
```

## Server-side logging with tracing

```toml
[dependencies]
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }
```

```rust
use tracing_subscriber::{fmt, EnvFilter, layer::SubscriberExt, util::SubscriberInitExt};

fn init_tracing() {
    tracing_subscriber::registry()
        .with(EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| EnvFilter::new("info")))
        .with(fmt::layer().json())  // JSON logs for production
        .init();
}

// In server functions:
#[server(GetUser, "/api")]
async fn get_user(id: u32) -> Result<User, ServerFnError> {
    tracing::info!(user_id = id, "Fetching user");

    let user = db::get_user(id).await.map_err(|e| {
        tracing::error!(user_id = id, error = %e, "Failed to fetch user");
        ServerFnError::ServerError(e.to_string())
    })?;

    tracing::debug!(user_id = id, username = %user.name, "User fetched");
    Ok(user)
}
```

## Axum request tracing layer

```rust
use tower_http::trace::TraceLayer;
use tracing::Span;

let app = Router::new()
    .layer(
        TraceLayer::new_for_http()
            .make_span_with(|request: &Request<_>| {
                tracing::info_span!(
                    "http_request",
                    method = %request.method(),
                    uri = %request.uri(),
                )
            })
            .on_response(|response: &Response, latency: Duration, _span: &Span| {
                tracing::info!(
                    status = %response.status(),
                    latency = %latency.as_millis(),
                    "Response"
                );
            })
    );
```

## Error monitoring with Sentry

Browser:
```toml
[dependencies]
sentry-wasm = "0.32"
```

```rust
#[wasm_bindgen(start)]
pub fn start() {
    let _guard = sentry_wasm::init("https://your-dsn@sentry.io/project-id");
    console_error_panic_hook::set_once();
    leptos::mount_to_body(App);
}
```

Server:
```toml
[dependencies]
sentry = "0.32"
```

```rust
let _guard = sentry::init(("https://your-dsn@sentry.io/project-id", sentry::ClientOptions {
    release: sentry::release_name!(),
    environment: Some(std::env::var("LEPTOS_ENV")
        .unwrap_or("development".into()).into()),
    ..Default::default()
}));
```

## Prometheus metrics

```toml
[dependencies]
prometheus = "0.13"
lazy_static = "1"
```

```rust
use prometheus::{Counter, Histogram, register_counter, register_histogram};
use lazy_static::lazy_static;

lazy_static! {
    static ref REQUEST_COUNT: Counter = register_counter!(
        "http_requests_total", "Total HTTP requests"
    ).unwrap();

    static ref REQUEST_DURATION: Histogram = register_histogram!(
        "http_request_duration_seconds", "HTTP request duration"
    ).unwrap();
}

// In middleware:
async fn metrics_middleware(req: Request, next: Next) -> Response {
    REQUEST_COUNT.inc();
    let timer = REQUEST_DURATION.start_timer();
    let resp = next.run(req).await;
    timer.observe_duration();
    resp
}

// Expose /metrics endpoint for Prometheus scraping:
async fn metrics_handler() -> String {
    use prometheus::Encoder;
    let encoder = prometheus::TextEncoder::new();
    let mut buffer = Vec::new();
    encoder.encode(&prometheus::gather(), &mut buffer).unwrap();
    String::from_utf8(buffer).unwrap()
}
```

## Structured logging for production

Use JSON log output to integrate with log aggregators (Loki, CloudWatch, Datadog):

```bash
# Set environment variable
RUST_LOG=info cargo run --features ssr 2>&1 | jq '.'
```

Output:
```json
{"timestamp":"2024-01-15T10:23:01Z","level":"INFO","target":"myapp::server","user_id":42,"message":"User fetched"}
```
