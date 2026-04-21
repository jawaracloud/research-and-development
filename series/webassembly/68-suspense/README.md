# 68 — <Suspense> and Loading States

> **Type:** How-To + Explanation

## What is Suspense?

`<Suspense>` is a boundary that shows a fallback UI while its children are loading. It integrates with `create_resource` — when any resource inside `<Suspense>` is pending, the fallback is shown.

```rust
view! {
    <Suspense fallback=|| view! { <p class="loading">"Loading..."</p> }>
        // Resources inside here may be pending
        <ContentThatLoadsData />
    </Suspense>
}
```

## Basic Suspense

```rust
use leptos::*;

#[component]
fn UserProfile(id: u32) -> impl IntoView {
    let user = create_resource(move || id, |id| async move {
        fetch_user(id).await
    });

    view! {
        <Suspense
            fallback=move || view! {
                <div class="skeleton">
                    <div class="skeleton-line" style="width: 60%"></div>
                    <div class="skeleton-line" style="width: 40%"></div>
                </div>
            }
        >
            {move || user.get().map(|u| view! {
                <div class="profile">
                    <h1>{u.name}</h1>
                    <p>{u.email}</p>
                </div>
            })}
        </Suspense>
    }
}
```

## Nested Suspense boundaries

Use multiple Suspense boundaries for independent loading regions:

```rust
view! {
    <div class="dashboard">
        <Suspense fallback=|| view! { <UserSkeleton /> }>
            <UserProfile id=current_user_id />
        </Suspense>

        <Suspense fallback=|| view! { <TableSkeleton rows=5 /> }>
            <RecentActivity />
        </Suspense>
    </div>
}
```

This lets each section load independently rather than waiting for all data.

## Transition (keeps old content while loading new)

`<Transition>` is like `<Suspense>` but keeps the previous content visible while new content loads (instead of showing the fallback):

```rust
view! {
    <Transition fallback=|| view! { <p>"Initial load..."</p> }>
        // After first load, subsequent fetches keep old content visible
        {move || data.get().map(|d| view! { <DataTable data=d /> })}
    </Transition>
}
```

This creates a subtle "content updates in place" experience rather than a flicker.

## Loading spinners and skeleton patterns

```rust
#[component]
fn Spinner() -> impl IntoView {
    view! {
        <div class="spinner-overlay">
            <div class="spinner"></div>
        </div>
    }
}

#[component]
fn CardSkeleton() -> impl IntoView {
    view! {
        <div class="card skeleton">
            <div class="skeleton-avatar pulse"></div>
            <div class="skeleton-text">
                <div class="skeleton-line" style="width: 70%"></div>
                <div class="skeleton-line" style="width: 50%"></div>
            </div>
        </div>
    }
}
```

CSS:
```css
.pulse {
    animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
}
.skeleton-line {
    height: 0.875rem;
    background: #313244;
    border-radius: 4px;
    margin-bottom: 0.5rem;
}
```

## Suspense + error boundary

```rust
view! {
    <Suspense fallback=|| view! { <LoadingSpinner /> }>
        <ErrorBoundary fallback=|errors| view! {
            <div class="error-box">
                "Failed to load: "
                {move || errors.get().into_iter().next()
                    .map(|(_, e)| format!("{}", e))
                    .unwrap_or_default()
                }
            </div>
        }>
            <UserList />
        </ErrorBoundary>
    </Suspense>
}
```

## Server-side rendering and Suspense

In SSR mode (lessons 71–80), `<Suspense>` tells the server to either:
- **Wait** for the resource and send complete HTML.
- **Stream** the fallback immediately, then send the resolved content as it's ready.

Choose with `create_resource` vs `create_local_resource` and the Leptos streaming SSR API.
