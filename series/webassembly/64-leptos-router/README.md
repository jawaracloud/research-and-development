# 64 — Client-Side Routing with leptos_router

> **Type:** Tutorial + Reference

## Setup

```toml
[dependencies]
leptos = { version = "0.7", features = ["csr"] }
leptos_router = { version = "0.7", features = ["csr"] }
```

## Basic routing setup

```rust
use leptos::*;
use leptos_router::*;

#[component]
fn App() -> impl IntoView {
    view! {
        <Router>
            <nav>
                <A href="/">"Home"</A>
                <A href="/about">"About"</A>
                <A href="/posts">"Posts"</A>
            </nav>
            <main>
                <Routes>
                    <Route path="/" view=HomePage />
                    <Route path="/about" view=AboutPage />
                    <Route path="/posts" view=PostsPage />
                    <Route path="/posts/:id" view=PostDetailPage />
                    <Route path="/*" view=NotFoundPage />
                </Routes>
            </main>
        </Router>
    }
}
```

## Page components

```rust
#[component]
fn HomePage() -> impl IntoView {
    view! { <h1>"Home"</h1> }
}

#[component]
fn AboutPage() -> impl IntoView {
    view! { <h1>"About"</h1> }
}
```

## The `<A>` component (link)

`<A>` is Leptos's special link that integrates with the router:

```rust
view! {
    // Basic link
    <A href="/about">"About"</A>

    // Active class (when current route matches)
    <A href="/about" active_class="nav-active">"About"</A>

    // Exact match only
    <A href="/" exact=true active_class="nav-active">"Home"</A>
}
```

## Route parameters

```rust
use leptos_router::use_params_map;

#[component]
fn PostDetailPage() -> impl IntoView {
    let params = use_params_map();

    let post_id = create_memo(move |_| {
        params.with(|p| p.get("id").cloned().unwrap_or_default())
    });

    view! {
        <h1>"Post " {post_id}</h1>
    }
}
```

## Query parameters

```rust
use leptos_router::use_query_map;

#[component]
fn SearchPage() -> impl IntoView {
    let query = use_query_map();
    let search = create_memo(move |_| {
        query.with(|q| q.get("q").cloned().unwrap_or_default())
    });

    view! {
        <h1>"Search results for: " {search}</h1>
    }
}
// URL: /search?q=leptos
```

## Programmatic navigation

```rust
use leptos_router::use_navigate;

let navigate = use_navigate();

let go_home = move |_| {
    navigate("/", Default::default());
};

let go_to_post = move |id: u32| {
    navigate(&format!("/posts/{}", id), Default::default());
};
```

## Redirect

```rust
use leptos_router::Redirect;

#[component]
fn OldPage() -> impl IntoView {
    view! { <Redirect path="/new-path" /> }
}
```

## Protected routes

```rust
#[component]
fn AuthGuard(children: Children) -> impl IntoView {
    let is_authenticated = use_context::<Signal<bool>>()
        .expect("auth context must be provided");

    view! {
        <Show
            when=move || is_authenticated.get()
            fallback=|| view! { <Redirect path="/login" /> }
        >
            {children()}
        </Show>
    }
}

// Usage:
view! {
    <AuthGuard>
        <DashboardPage />
    </AuthGuard>
}
```

## Current location

```rust
use leptos_router::use_location;

let location = use_location();
let path = move || location.pathname.get();
```
