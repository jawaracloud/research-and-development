# 70 — Server Actions and Progressive Forms

> **Type:** How-To + Tutorial

## What are server actions?

Server actions are Leptos's pattern for mutating data on the server from the client. They:
- Run on the server (serialized as a function call over HTTP).
- Can be called from both the browser and the server.
- Work progressively — even without JavaScript (just a regular form POST).

## Defining a server action

```rust
use leptos::*;
use leptos_axum::extract;

#[server(AddTodo, "/api")]
pub async fn add_todo(title: String) -> Result<(), ServerFnError> {
    // This code runs on the SERVER only
    let pool = use_context::<sqlx::SqlitePool>().ok_or(ServerFnError::ServerError(
        "No database connection".to_string()
    ))?;

    sqlx::query("INSERT INTO todos (title, done) VALUES (?, false)")
        .bind(&title)
        .execute(&pool)
        .await
        .map_err(|e| ServerFnError::ServerError(e.to_string()))?;

    Ok(())
}
```

The `#[server]` macro:
- Compiles this function only on the server (`cfg(feature = "ssr")`).
- On the client, generates a stub that sends an HTTP request to `/api/add_todo`.
- Handles serialization/deserialization automatically.

## Using an action in a component

```rust
#[component]
fn AddTodoForm() -> impl IntoView {
    let add_todo = create_server_action::<AddTodo>();
    // Signals for loading/error state
    let pending = add_todo.pending();
    let error = move || add_todo.value().get().and_then(|r| r.err());

    view! {
        <ActionForm action=add_todo>
            <input
                type="text"
                name="title"
                placeholder="Add a todo..."
                disabled=pending
            />
            <button type="submit" disabled=pending>
                {move || if pending.get() { "Adding..." } else { "Add" }}
            </button>
        </ActionForm>

        <Show when=move || error().is_some()>
            <p class="error">{move || error().map(|e| e.to_string())}</p>
        </Show>
    }
}
```

## ActionForm — progressive enhancement

`<ActionForm action=add_todo>` is special: it renders a real `<form>` with a proper `action` and `method`. This means it works even without JavaScript (graceful degradation).

With JS: the form submits via `fetch`, stays on the same page.  
Without JS: normal form POST, full page reload.

## Reacting to action completion

```rust
let add_todo = create_server_action::<AddTodo>();
let todo_list = create_resource(
    move || add_todo.version().get(), // version increments on each action call
    |_| async { fetch_todos().await }
);

// Every time add_todo completes, todo_list refetches automatically
```

## Action vs Resource

| | `create_resource` | `create_server_action` |
|:|:-----------------|:----------------------|
| Trigger | Source signal changes | Explicit `.dispatch(input)` call |
| Purpose | Read data | Mutate data |
| Method | GET semantics | POST semantics |
| Progressive | via Suspense | via ActionForm |

## Dispatching an action programmatically

```rust
let add_todo = create_server_action::<AddTodo>();

let on_click = move |_| {
    add_todo.dispatch(AddTodoArgs { title: "From button".to_string() });
};

view! {
    <button on:click=on_click>"Quick add"</button>
}
```

## Optimistic updates

For a snappy UI, update the local state immediately before the server responds:

```rust
let (local_todos, set_local_todos) = create_signal(vec![]);
let add_todo = create_server_action::<AddTodo>();

let on_add = move |title: String| {
    // Optimistically add to local list
    set_local_todos.update(|v| v.push(title.clone()));
    // Send to server
    add_todo.dispatch(AddTodoArgs { title });
};
```

If the server fails, reconcile with the server's truth by refetching.
