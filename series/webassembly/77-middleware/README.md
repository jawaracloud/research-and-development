# 77 — Middleware and Request Extraction

> **Type:** How-To + Reference

## What is middleware?

In Axum, middleware is a `Tower` layer that sits between the HTTP server and your route handlers. It can inspect, modify, or short-circuit requests and responses.

Leptos apps use Axum middleware for:
- Authentication/authorization checks.
- Rate limiting.
- Request logging.
- CORS.
- Compression.
- Response caching.

## Adding common middleware

```rust
use axum::Router;
use tower_http::{
    compression::CompressionLayer,
    cors::CorsLayer,
    trace::TraceLayer,
};

let app = Router::new()
    .leptos_routes(&opts, routes, App)
    .layer(CompressionLayer::new())
    .layer(
        CorsLayer::new()
            .allow_origin("https://myapp.com".parse::<axum::http::HeaderValue>().unwrap())
            .allow_methods([axum::http::Method::GET, axum::http::Method::POST]),
    )
    .layer(TraceLayer::new_for_http());
```

## Custom middleware: logging

```rust
use axum::{middleware::Next, extract::Request, response::Response};
use std::time::Instant;

pub async fn log_requests(req: Request, next: Next) -> Response {
    let method = req.method().clone();
    let uri = req.uri().clone();
    let start = Instant::now();

    let response = next.run(req).await;

    let elapsed = start.elapsed();
    log::info!(
        "{} {} → {} ({:?})",
        method, uri,
        response.status(),
        elapsed
    );

    response
}

// In app setup:
use axum::middleware;
let app = Router::new()
    // ...
    .layer(middleware::from_fn(log_requests));
```

## Extracting request data in server functions

Leptos provides `use_context` to access Axum extractors in server functions:

```rust
use leptos_axum::extract;
use axum::extract::ConnectInfo;
use std::net::SocketAddr;

#[server(GetClientInfo, "/api")]
pub async fn get_client_info() -> Result<String, ServerFnError> {
    // Extract from the request context
    let ConnectInfo(addr) = extract::<ConnectInfo<SocketAddr>>()
        .await
        .map_err(|e| ServerFnError::ServerError(e.to_string()))?;

    Ok(addr.ip().to_string())
}
```

## Extracting headers

```rust
use axum::http::HeaderMap;

#[server(CheckHeader, "/api")]
pub async fn check_header() -> Result<String, ServerFnError> {
    let headers = extract::<HeaderMap>().await.unwrap();
    
    let user_agent = headers
        .get("user-agent")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("unknown")
        .to_string();

    Ok(user_agent)
}
```

## Rate limiting with tower-governor

```toml
[dependencies]
tower-governor = "0.4"
```

```rust
use tower_governor::{governor::GovernorConfigBuilder, GovernorLayer};

let governor_conf = Arc::new(
    GovernorConfigBuilder::default()
        .per_second(2)          // 2 requests per second
        .burst_size(10)         // burst up to 10
        .finish().unwrap()
);

let app = Router::new()
    .route("/api/search", axum::routing::get(search))
    .layer(GovernorLayer { config: governor_conf });
```

## Response modification from server functions

```rust
use leptos_axum::ResponseOptions;
use axum::http::{header, HeaderValue};

#[server(SetHeaders, "/api")]
pub async fn set_cache_headers() -> Result<String, ServerFnError> {
    let response_opts = use_context::<ResponseOptions>()
        .ok_or_else(|| ServerFnError::ServerError("no response opts".into()))?;

    response_opts.insert_header(
        header::CACHE_CONTROL,
        HeaderValue::from_static("public, max-age=3600"),
    );

    Ok("ok".into())
}
```

## Redirect from server code

```rust
use leptos_axum::redirect;

#[server(ProtectedAction, "/api")]
pub async fn protected_action() -> Result<(), ServerFnError> {
    let user = get_current_user().await?;
    
    if user.is_none() {
        redirect("/login");
        return Ok(());
    }

    // ... do protected work
    Ok(())
}
```

`redirect` sets the appropriate HTTP redirect headers on the response.
