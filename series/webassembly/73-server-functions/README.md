# 73 — Server Functions in Depth

> **Type:** How-To + Reference

## What are server functions?

Server functions are regular Rust `async fn`s annotated with `#[server]`. They:
- **Run on the server** (compile flag `ssr`).
- **Are called from the client** via an auto-generated HTTP stub.
- **Serialize arguments and return values** automatically.

```rust
#[server(MyFunction, "/api")]
pub async fn my_function(arg: String) -> Result<String, ServerFnError> {
    Ok(format!("Hello, {}!", arg))
}
```

The macro generates:
1. A `POST /api/my_function` route on the server.
2. A client-side async function that sends the request.
3. Serialization/deserialization boilerplate.

## ServerFnError

All server functions return `Result<T, ServerFnError>`. `ServerFnError` is an enum that covers:

```rust
pub enum ServerFnError<E = NoCustomError> {
    ServerError(String),       // generic server error
    Request(String),           // transport error
    Response(String),          // response parsing error
    Deserialization(String),   // JSON decode error
    Serialization(String),     // JSON encode error
    Args(String),              // argument parsing error
    MissingArg(String),        // required arg not provided
    Registration(String),      // routing error
    Custom(E),                 // your custom error type
}
```

## Custom error types

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum AppError {
    Unauthorized,
    NotFound(String),
    Database(String),
}

impl std::fmt::Display for AppError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            AppError::Unauthorized => write!(f, "Not authorized"),
            AppError::NotFound(r) => write!(f, "Not found: {}", r),
            AppError::Database(e) => write!(f, "Database error: {}", e),
        }
    }
}

#[server(GetUser, "/api")]
pub async fn get_user(id: u32) -> Result<User, ServerFnError<AppError>> {
    let pool = use_context::<sqlx::PgPool>()
        .ok_or(ServerFnError::ServerError("no pool".into()))?;

    sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = $1")
        .bind(id as i32)
        .fetch_optional(&pool)
        .await
        .map_err(|e| ServerFnError::Custom(AppError::Database(e.to_string())))?
        .ok_or(ServerFnError::Custom(AppError::NotFound(format!("user {}", id))))
}
```

## Encoding formats

By default, server functions use `Cbor` or `PostUrl` encoding. You can specify:

```rust
#[server(
    name = "SavePost",
    prefix = "/api",
    endpoint = "save_post",
    input = Json,
    output = Json,
)]
pub async fn save_post(title: String, content: String) -> Result<u32, ServerFnError> {
    // ...
}
```

Available encodings: `Cbor`, `Json`, `GetUrl`, `PostUrl`, `MultipartFormData`.

## Middleware on server functions

Server functions are Axum routes under the hood — you can add middleware:

```rust
// Wrap a server function in a session check
#[server(ProtectedAction, "/api")]
pub async fn protected_action(data: String) -> Result<String, ServerFnError> {
    // Check session cookie
    let session = use_context::<Session>()
        .ok_or_else(|| ServerFnError::ServerError("no session".into()))?;

    if !session.is_authenticated() {
        return Err(ServerFnError::ServerError("unauthorized".into()));
    }

    Ok(format!("Processed: {}", data))
}
```

## Multipart uploads

```rust
use server_fn::codec::MultipartFormData;

#[server(
    UploadFile,
    "/api",
    input = MultipartFormData,
)]
pub async fn upload_file(data: MultipartData) -> Result<String, ServerFnError> {
    let mut data = data.into_inner().unwrap();
    
    while let Some(mut field) = data.next_field().await.unwrap() {
        let name = field.name().unwrap_or("unknown").to_string();
        let bytes = field.bytes().await.unwrap();
        log::info!("Received field '{}': {} bytes", name, bytes.len());
    }
    
    Ok("Upload complete".into())
}
```

## Reference: server function vs Action vs Resource

| | `#[server]` fn | `create_resource` | `create_server_action` |
|:|:--------------|:-----------------|:----------------------|
| Purpose | Define RPC | Read data | Mutate data |
| Calling convention | HTTP POST | GET semantics | POST semantics |
| Called from Leptos | Via `create_resource` or `create_server_action` | Wraps a server fn | Wraps a server fn |
| Direct call | `my_fn(args).await` | No | No |
