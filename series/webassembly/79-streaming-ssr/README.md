# 79 — Streaming SSR

> **Type:** Explanation + How-To

## What is streaming SSR?

Normal SSR waits for ALL data to be fetched before sending any HTML. Streaming SSR sends HTML in chunks as data becomes available:

```
Time 0ms:   Server sends: <html><head>...</head><body><nav>...</nav>
Time 100ms: Server sends: <main><p>Loading...</p>
Time 350ms: User data arrives → Server sends: <script>inject("Alice")</script>
Time 800ms: Posts arrive → Server sends: <script>inject([...])</script>
            </body></html>
```

The browser renders each chunk as it arrives. Users see content faster even though the total data transfer is the same.

## Leptos streaming with Suspense

In Leptos SSR + Axum, `<Suspense>` boundaries automatically trigger streaming:

```rust
#[component]
fn UserDashboard() -> impl IntoView {
    let user = create_resource(|| (), |_| async { fetch_user().await });
    let posts = create_resource(|| (), |_| async { fetch_posts().await });

    view! {
        <h1>"Dashboard"</h1>

        // This Suspense streams independently
        <Suspense fallback=|| view! { <UserSkeleton /> }>
            {move || user.get().map(|u| view! { <UserCard user=u /> })}
        </Suspense>

        // This Suspense also streams independently
        <Suspense fallback=|| view! { <PostsSkeleton /> }>
            {move || posts.get().map(|p| view! { <PostList posts=p /> })}
        </Suspense>
    }
}
```

When the server renders this:
1. Sends everything up to the first `<Suspense>` immediately.
2. Sends skeleton placeholders.
3. As each resource resolves, sends a `<script>` that injects the real content.

## Setting up streaming in Axum

```rust
use leptos_axum::{render_app_to_stream, generate_route_list};

async fn shell(State(opts): State<LeptosOptions>) -> impl IntoResponse {
    render_app_to_stream(opts, App)
}

// In route setup:
let app = Router::new()
    .route("/", axum::routing::get(shell))
    .leptos_routes(&opts, routes, App);
```

Or use `render_app_to_stream_with_context` to inject server context (auth, DB pool):

```rust
async fn shell(req: Request, State(opts): State<LeptosOptions>) -> impl IntoResponse {
    render_app_to_stream_with_context(
        opts,
        move || {
            provide_context(pool.clone());
            provide_context(extract_user(&req));
        },
        App,
    )
}
```

## Streaming vs blocking: choosing the right strategy

| Approach | API | Use when |
|----------|-----|---------|
| Blocking SSR | `render_app_to_string` | Complete HTML needed (CLI, PDF) |
| Streaming SSR | `render_app_to_stream` | Production web apps |
| CSR (no SSR) | `mount_to_body` | Private dashboards, auth-only apps |
| Islands | `#[island]` | Mostly static content with occasional interactivity |

## Out-of-order streaming

Leptos uses **out-of-order streaming** — each `<Suspense>` resolves and injects in whatever order the data arrives, not necessarily document order. This maximizes concurrency.

The Leptos runtime on the server injects replacement HTML like:

```html
<template id="leptos-1">
  <div class="user-card">Alice</div>
</template>
<script>
  // Replace placeholder with real content
  document.querySelector('[leptos-hk="1"]').replaceWith(
    document.getElementById('leptos-1').content
  );
</script>
```

## Handling streaming with `generate_route_list`

```rust
let routes = generate_route_list(App);

for route in &routes {
    println!("Route: {} (static: {})", route.path(), route.static_mode());
}
```

You can mark individual routes as statically generated (pre-rendered at build time) or dynamically rendered per request.

## Performance considerations

- Streaming shines when you have independent data sources that can load in parallel.
- If all data comes from a single query, blocking SSR is equally fast.
- Streaming requires the client to have JS/Wasm to process the injected scripts.
  - For JS-disabled clients, content appears only after full response, which is still correct.
