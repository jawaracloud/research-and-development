# 76 — Authentication and Session Management

> **Type:** How-To + Tutorial

## Setup

```toml
[dependencies]
axum-login = "0.16"
axum-sessions = "0.6"   # or tower-sessions
bcrypt = "0.15"
uuid = { version = "1", features = ["v4"] }
```

## The auth flow

```
1. User submits login form (username + password)
2. Server looks up user in DB
3. Server verifies password hash with bcrypt::verify()
4. Server creates session cookie
5. Client stores session cookie automatically (browser handles this)
6. Subsequent requests: cookie sent automatically
7. Server validates session, loads user from DB
8. Leptos renders with user context
```

## Password hashing

```rust
// On registration (server function):
use bcrypt::{hash, verify, DEFAULT_COST};

#[server(RegisterUser, "/api")]
pub async fn register_user(username: String, password: String) -> Result<(), ServerFnError> {
    let hashed = hash(&password, DEFAULT_COST)
        .map_err(|e| ServerFnError::ServerError(e.to_string()))?;

    let pool = use_context::<SqlitePool>()
        .ok_or_else(|| ServerFnError::ServerError("no pool".into()))?;

    sqlx::query("INSERT INTO users (username, password_hash) VALUES (?, ?)")
        .bind(&username)
        .bind(&hashed)
        .execute(&pool)
        .await
        .map_err(|e| ServerFnError::ServerError(e.to_string()))?;

    Ok(())
}
```

## Login server function

```rust
use axum::http::header::{HeaderMap, SET_COOKIE};
use leptos_axum::ResponseOptions;

#[server(Login, "/api")]
pub async fn login(username: String, password: String) -> Result<(), ServerFnError> {
    let pool = use_context::<SqlitePool>()
        .ok_or_else(|| ServerFnError::ServerError("no pool".into()))?;

    let user = sqlx::query_as!(
        User,
        "SELECT id, username, password_hash FROM users WHERE username = ?",
        username
    )
    .fetch_optional(&pool)
    .await
    .map_err(|e| ServerFnError::ServerError(e.to_string()))?
    .ok_or_else(|| ServerFnError::ServerError("invalid credentials".into()))?;

    if !bcrypt::verify(&password, &user.password_hash)
        .map_err(|e| ServerFnError::ServerError(e.to_string()))? {
        return Err(ServerFnError::ServerError("invalid credentials".into()));
    }

    // Set session cookie
    let session_token = uuid::Uuid::new_v4().to_string();
    sqlx::query("INSERT INTO sessions (token, user_id) VALUES (?, ?)")
        .bind(&session_token)
        .bind(user.id)
        .execute(&pool).await
        .map_err(|e| ServerFnError::ServerError(e.to_string()))?;

    let response = use_context::<ResponseOptions>()
        .ok_or_else(|| ServerFnError::ServerError("no response options".into()))?;

    let cookie = format!(
        "session={}; HttpOnly; SameSite=Strict; Path=/; Max-Age=86400",
        session_token
    );
    response.insert_header(SET_COOKIE, cookie.parse().unwrap());

    Ok(())
}
```

## Auth middleware (Axum layer)

```rust
use axum::{middleware, Extension};

async fn require_auth(
    req: axum::extract::Request,
    next: axum::middleware::Next,
) -> Result<axum::response::Response, axum::http::StatusCode> {
    // Check cookie header
    let cookie_header = req.headers()
        .get(axum::http::header::COOKIE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");

    if let Some(token) = parse_session_cookie(cookie_header) {
        // Validate token against DB...
        Ok(next.run(req).await)
    } else {
        Err(axum::http::StatusCode::UNAUTHORIZED)
    }
}
```

## Providing auth context to Leptos

```rust
// In the Leptos context provider:
.leptos_routes_with_context(
    &leptos_options,
    routes,
    move || {
        provide_context(pool.clone());
        provide_context(current_user()); // extracted from request
    },
    App,
)
```

## Auth-aware component

```rust
#[component]
fn NavBar() -> impl IntoView {
    let user = use_context::<Option<User>>();

    view! {
        <nav>
            {match user {
                Some(u) => view! {
                    <span>{u.username}</span>
                    <a href="/logout">"Log out"</a>
                }.into_view(),
                None => view! {
                    <a href="/login">"Log in"</a>
                }.into_view(),
            }}
        </nav>
    }
}
```
