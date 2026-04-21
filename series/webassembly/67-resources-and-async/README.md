# 67 — Fetching Data with Resources (create_resource)

> **Type:** How-To + Explanation

## What is a Resource?

A **resource** is an async signal — a reactive wrapper around an async operation (like an API call) that produces a value. It automatically re-fetches when its source signal changes.

```rust
let resource = create_resource(
    || (), // source: unit — fetches once on mount
    |_| async { fetch_todos().await },
);
```

## Basic usage

```rust
use leptos::*;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone)]
struct Post { id: u32, title: String, body: String }

async fn fetch_posts() -> Vec<Post> {
    reqwest::get("https://jsonplaceholder.typicode.com/posts")
        .await.unwrap()
        .json().await.unwrap()
}

#[component]
fn PostList() -> impl IntoView {
    let posts = create_resource(|| (), |_| async { fetch_posts().await });

    view! {
        <Suspense fallback=|| view! { <p>"Loading..."</p> }>
            {move || posts.get().map(|data| view! {
                <ul>
                    {data.iter().map(|post| view! {
                        <li><strong>{post.id}</strong>": " {post.title.clone()}</li>
                    }).collect_view()}
                </ul>
            })}
        </Suspense>
    }
}
```

## Resource with a reactive source

The first argument is a *source* — when it changes, the resource re-fetches:

```rust
let (user_id, set_user_id) = create_signal(1u32);

let user = create_resource(
    move || user_id.get(),  // reactive source
    |id| async move {
        reqwest::get(format!("https://jsonplaceholder.typicode.com/users/{}", id))
            .await.unwrap()
            .json::<serde_json::Value>().await.unwrap()
    },
);

// When user_id changes, user re-fetches automatically
view! {
    <button on:click=move |_| set_user_id(2)>"Load user 2"</button>
    <Suspense fallback=|| view! { <p>"Loading..."</p> }>
        {move || user.get().map(|u| view! {
            <p>{u["name"].as_str().unwrap_or("").to_string()}</p>
        })}
    </Suspense>
}
```

## Resource states

`resource.get()` returns `Option<T>`:
- `None` — still loading (or not yet started).
- `Some(value)` — loaded.

For error handling:
```rust
// Use Result<T, E> as the resource type
let posts = create_resource(|| (), |_| async {
    reqwest::get("https://api.example.com/posts")
        .await
        .map_err(|e| e.to_string())?
        .json::<Vec<Post>>()
        .await
        .map_err(|e| e.to_string())
});

view! {
    <Suspense fallback=|| view! { <p>"Loading..."</p> }>
        <ErrorBoundary fallback=|errors| view! {
            <p>"Error: " {format!("{:?}", errors.get())}</p>
        }>
            {move || posts.get().map(|result| result.map(|posts| view! {
                // render posts
            }))}
        </ErrorBoundary>
    </Suspense>
}
```

## Triggering manual refresh

```rust
let resource = create_resource(|| (), |_| async { fetch_data().await });

// Refetch button
view! {
    <button on:click=move |_| resource.refetch()>"Refresh"</button>
}
```

## create_local_resource vs create_resource

| | `create_resource` | `create_local_resource` |
|:|:-----------------|:----------------------|
| SSR support | ✅ (serializes to HTML) | ❌ (client-only) |
| Can use `!Send` types | ❌ | ✅ |
| Use when | Full-stack apps | Browser-only operations |

For CSR-only apps or when using non-`Send` types (like `web_sys` callbacks), use `create_local_resource`.

## Combining multiple resources

```rust
let user = create_resource(move || user_id.get(), fetch_user);
let posts = create_resource(move || user_id.get(), fetch_posts_for_user);

view! {
    <Suspense fallback=|| view! { <p>"Loading profile..."</p> }>
        {move || {
            let user = user.get();
            let posts = posts.get();
            match (user, posts) {
                (Some(u), Some(p)) => view! {
                    <UserProfile user=u posts=p />
                }.into_view(),
                _ => view! { <p>"Loading..."</p> }.into_view(),
            }
        }}
    </Suspense>
}
```
