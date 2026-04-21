# 91 — Project: Full-Stack Todo App (Leptos + SQLite)

> **Type:** Tutorial

## What you will build

A production-quality full-stack Todo application that brings together everything from the series:
- Server-side rendering with streaming.
- SQLite database with migrations.
- Server functions for CRUD operations.
- Authentication (user sessions).
- Leptos reactive UI with `<For>`.
- Optimistic UI updates.

## Architecture

```
Browser (Wasm)           Server (native Rust)
┌──────────────┐         ┌────────────────────┐
│ Leptos CSR   │ ◄────── │ Axum + Leptos SSR  │
│ + hydration  │ ──────► │ Server Functions   │
│              │         │ SQLite (sqlx)      │
└──────────────┘         └────────────────────┘
```

## Project layout

```
fullstack-todo/
├── Cargo.toml
├── Leptos.toml
├── migrations/
│   └── 0001_init.sql
├── public/
│   └── favicon.ico
├── style/
│   └── app.css
└── src/
    ├── main.rs        # Axum server (ssr)
    ├── lib.rs         # Hydration entry (hydrate)
    ├── app.rs         # Router + App component
    ├── models.rs      # Todo, User structs
    ├── pages/
    │   ├── home.rs    # Todo list page
    │   └── login.rs   # Login page
    ├── components/
    │   ├── todo_item.rs
    │   ├── todo_form.rs
    │   └── filter_bar.rs
    └── server/
        ├── todos.rs   # CRUD server functions
        └── auth.rs    # Login/register server fns
```

## Database model

```sql
-- migrations/0001_init.sql
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS todos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    done BOOLEAN NOT NULL DEFAULT 0,
    priority INTEGER NOT NULL DEFAULT 0,  -- 0=normal, 1=high
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## Key server functions

```rust
// src/server/todos.rs

#[server(GetTodos, "/api")]
pub async fn get_todos() -> Result<Vec<Todo>, ServerFnError> {
    let pool = use_context::<SqlitePool>().expect("db pool");
    let user_id = get_current_user_id().await?;

    Ok(sqlx::query_as!(
        Todo,
        "SELECT * FROM todos WHERE user_id = ? ORDER BY priority DESC, created_at DESC",
        user_id
    )
    .fetch_all(&pool).await?)
}

#[server(AddTodo, "/api")]
pub async fn add_todo(title: String, priority: i32) -> Result<Todo, ServerFnError> {
    let pool = use_context::<SqlitePool>().expect("db pool");
    let user_id = get_current_user_id().await?;

    let id = sqlx::query!(
        "INSERT INTO todos (user_id, title, priority) VALUES (?, ?, ?)",
        user_id, title, priority
    )
    .execute(&pool).await?.last_insert_rowid();

    let todo = sqlx::query_as!(Todo, "SELECT * FROM todos WHERE id = ?", id)
        .fetch_one(&pool).await?;
    Ok(todo)
}
```

## Main page component

```rust
// src/pages/home.rs
#[component]
pub fn HomePage() -> impl IntoView {
    let add_todo = create_server_action::<AddTodo>();
    let todos = create_resource(
        move || add_todo.version().get(),
        |_| async { get_todos().await },
    );

    let (filter, set_filter) = create_signal(Filter::All);
    
    let visible_todos = create_memo(move |_| {
        todos.get().and_then(|r| r.ok()).map(|items| {
            items.into_iter().filter(|t| match filter.get() {
                Filter::All => true,
                Filter::Active => !t.done,
                Filter::Completed => t.done,
            }).collect::<Vec<_>>()
        })
    });

    view! {
        <div class="todo-app">
            <header>
                <h1>"My Todos"</h1>
                <FilterBar filter set_filter />
            </header>

            <ActionForm action=add_todo class="todo-form">
                <input name="title" placeholder="What needs to be done?" required />
                <input name="priority" type="hidden" value="0" />
                <button type="submit">"Add"</button>
            </ActionForm>

            <Suspense fallback=|| view! { <div class="loading">"Loading..."</div> }>
                {move || visible_todos.get().flatten().map(|items| view! {
                    <ul class="todo-list">
                        <For
                            each=move || items.clone()
                            key=|todo| todo.id
                            children=|todo| view! { <TodoItem todo /> }
                        />
                    </ul>
                })}
            </Suspense>
        </div>
    }
}
```

## Running the project

```bash
# Install tools
cargo install cargo-leptos
rustup target add wasm32-unknown-unknown

# Create database
sqlx database create
sqlx migrate run

# Run in dev mode
cargo leptos watch
```

## Deployment

```bash
cargo leptos build --release
docker build -t fullstack-todo .
docker run -p 3000:3000 \
  -e DATABASE_URL=sqlite:/data/app.db \
  -e SESSION_SECRET=your-secret \
  fullstack-todo
```

## What this project demonstrates

- SSR + hydration working in tandem.
- Server functions as the API layer (no separate REST API needed).
- `create_server_action` for mutations that automatically retrigger `create_resource`.
- `<For>` with server-fetched data.
- Authentication integrated at the server function level.
- Single Rust codebase for both server and client.
