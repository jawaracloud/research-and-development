# 65 — Nested Routes and Layouts

> **Type:** How-To + Tutorial

## What are nested routes?

Nested routes allow a "layout" component to wrap multiple child routes — much like a shared shell (nav, sidebar, footer) that persists across page changes.

```
/dashboard           → DashboardLayout
/dashboard/overview  → DashboardLayout + Overview
/dashboard/users     → DashboardLayout + Users
/dashboard/settings  → DashboardLayout + Settings
```

## Basic nested routing

```rust
use leptos::*;
use leptos_router::*;

#[component]
fn App() -> impl IntoView {
    view! {
        <Router>
            <Routes>
                <Route path="/" view=HomePage />
                // Parent route — renders DashboardLayout
                <Route path="/dashboard" view=DashboardLayout>
                    // Children render inside <Outlet />
                    <Route path="" view=DashboardOverview />
                    <Route path="users" view=UsersPage />
                    <Route path="settings" view=SettingsPage />
                </Route>
            </Routes>
        </Router>
    }
}
```

## The layout component

The parent `view` must include `<Outlet />` — this is where the active child route renders:

```rust
#[component]
fn DashboardLayout() -> impl IntoView {
    view! {
        <div class="dashboard-shell">
            <aside class="sidebar">
                <nav>
                    <A href="/dashboard">"Overview"</A>
                    <A href="/dashboard/users">"Users"</A>
                    <A href="/dashboard/settings">"Settings"</A>
                </nav>
            </aside>
            <main class="dashboard-content">
                // The matched child route renders here
                <Outlet />
            </main>
        </div>
    }
}
```

## Multi-level nesting

```rust
<Route path="/app" view=AppLayout>
    <Route path="dashboard" view=DashboardLayout>
        <Route path="" view=Overview />
        <Route path="analytics" view=Analytics />
    </Route>
    <Route path="profile" view=ProfilePage />
</Route>
```

## Index routes

An empty path `""` is the "index" — renders when the parent route exactly matches:

```rust
<Route path="/dashboard" view=DashboardLayout>
    <Route path="" view=DashboardIndex />  // /dashboard → this
    <Route path="users" view=UsersPage />  // /dashboard/users → this
</Route>
```

## Passing data to nested routes via context

```rust
#[component]
fn DashboardLayout() -> impl IntoView {
    let user = create_rw_signal(User::current());
    provide_context(user);

    view! {
        <div>
            <header>
                <UserMenu user=user />
            </header>
            <Outlet />
        </div>
    }
}

// In a child route:
#[component]
fn SettingsPage() -> impl IntoView {
    let user = use_context::<RwSignal<User>>().expect("user context");
    view! {
        <p>"Settings for: " {move || user.get().name}</p>
    }
}
```

## Handling 404 for nested routes

```rust
<Route path="/dashboard" view=DashboardLayout>
    <Route path="" view=Overview />
    <Route path="users" view=Users />
    // Catch-all within the dashboard
    <Route path="*" view=|| view! { <h2>"Page not found in dashboard"</h2> } />
</Route>
```

## Dynamic layouts based on route

You can conditionally swap layouts based on authentication or role:

```rust
#[component]
fn AdminLayout() -> impl IntoView {
    let is_admin = use_context::<Signal<bool>>().expect("auth context");
    view! {
        <Show
            when=move || is_admin.get()
            fallback=|| view! { <Redirect path="/login" /> }
        >
            <div class="admin-shell">
                <AdminSidebar />
                <Outlet />
            </div>
        </Show>
    }
}
```
