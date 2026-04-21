# 75 — Database Access from Server Functions (SQLx)

> **Type:** How-To + Tutorial

## Setup

```toml
[dependencies]
sqlx = { version = "0.8", features = ["sqlite", "runtime-tokio-native-tls", "macros"] }
tokio = { version = "1", features = ["full"] }
```

For PostgreSQL: replace `sqlite` with `postgres`.

## Connecting to the database

```rust
// In main.rs (server only)
use sqlx::sqlite::SqlitePool;

#[tokio::main]
async fn main() {
    let pool = SqlitePool::connect("sqlite:./app.db").await
        .expect("Failed to connect to database");

    // Run migrations
    sqlx::migrate!("./migrations").run(&pool).await
        .expect("Failed to run migrations");

    // Provide pool to Leptos
    let app = Router::new()
        .leptos_routes_with_context(
            &leptos_options,
            routes,
            move || provide_context(pool.clone()),
            App,
        )
        .with_state(leptos_options);
    // ...
}
```

## Migrations

Create `migrations/0001_init.sql`:
```sql
CREATE TABLE IF NOT EXISTS todos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    done BOOLEAN NOT NULL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## Define models

```rust
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Todo {
    pub id: i64,
    pub title: String,
    pub done: bool,
}
```

## Server functions with database access

```rust
#[server(GetTodos, "/api")]
pub async fn get_todos() -> Result<Vec<Todo>, ServerFnError> {
    let pool = use_context::<SqlitePool>()
        .ok_or_else(|| ServerFnError::ServerError("No DB pool".into()))?;

    sqlx::query_as::<_, Todo>("SELECT id, title, done FROM todos ORDER BY id")
        .fetch_all(&pool)
        .await
        .map_err(|e| ServerFnError::ServerError(e.to_string()))
}

#[server(AddTodo, "/api")]
pub async fn add_todo(title: String) -> Result<i64, ServerFnError> {
    let pool = use_context::<SqlitePool>()
        .ok_or_else(|| ServerFnError::ServerError("No DB pool".into()))?;

    let result = sqlx::query("INSERT INTO todos (title) VALUES (?)")
        .bind(&title)
        .execute(&pool)
        .await
        .map_err(|e| ServerFnError::ServerError(e.to_string()))?;

    Ok(result.last_insert_rowid())
}

#[server(ToggleTodo, "/api")]
pub async fn toggle_todo(id: i64) -> Result<(), ServerFnError> {
    let pool = use_context::<SqlitePool>()
        .ok_or_else(|| ServerFnError::ServerError("No DB pool".into()))?;

    sqlx::query("UPDATE todos SET done = NOT done WHERE id = ?")
        .bind(id)
        .execute(&pool)
        .await
        .map_err(|e| ServerFnError::ServerError(e.to_string()))?;

    Ok(())
}

#[server(DeleteTodo, "/api")]
pub async fn delete_todo(id: i64) -> Result<(), ServerFnError> {
    let pool = use_context::<SqlitePool>()
        .ok_or_else(|| ServerFnError::ServerError("No DB pool".into()))?;

    sqlx::query("DELETE FROM todos WHERE id = ?")
        .bind(id)
        .execute(&pool)
        .await
        .map_err(|e| ServerFnError::ServerError(e.to_string()))?;

    Ok(())
}
```

## Compile-time query verification (sqlx macros)

```rust
// Checked at compile time — errors if SQL is wrong:
let todos = sqlx::query_as!(
    Todo,
    "SELECT id, title, done FROM todos WHERE done = ?",
    false
)
.fetch_all(&pool)
.await?;
```

Required: `DATABASE_URL` env var set during build:
```bash
DATABASE_URL=sqlite:./app.db cargo build
```

## Transactions

```rust
let mut tx = pool.begin().await
    .map_err(|e| ServerFnError::ServerError(e.to_string()))?;

sqlx::query("INSERT INTO audit_log (action) VALUES ('create')")
    .execute(&mut *tx)
    .await
    .map_err(|e| ServerFnError::ServerError(e.to_string()))?;

sqlx::query("INSERT INTO todos (title) VALUES (?)")
    .bind(&title)
    .execute(&mut *tx)
    .await
    .map_err(|e| ServerFnError::ServerError(e.to_string()))?;

tx.commit().await.map_err(|e| ServerFnError::ServerError(e.to_string()))?;
```
