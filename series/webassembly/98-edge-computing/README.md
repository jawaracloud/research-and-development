# 98 — Wasm on the Edge: Cloudflare Workers

> **Type:** How-To + Tutorial

## What are Cloudflare Workers?

Cloudflare Workers is a serverless platform that runs code at the network edge — in data centers close to users worldwide. Workers support WebAssembly natively, with startup times < 1ms (no cold starts).

Use cases:
- API gateway in front of your Leptos app.
- Authentication / JWT validation at the edge.
- Image resizing and optimization.
- A/B testing and feature flags.
- Geolocation-based routing.

## Wasm Worker vs Leptos SSR

| | Cloudflare Worker | Leptos Axum SSR |
|:|:-----------------:|:---------------:|
| Language | Rust → Wasm | Rust (native) |
| Cold start | < 1ms | N/A (always warm) |
| Max memory | 128MB | No limit |
| Billing | Per request | Per hour |
| DB access | D1, KV, R2 | Any database |
| Use when | Edge caching, API proxy | Full-stack app |

## Hello World Worker in Rust

```toml
# Cargo.toml for a Worker (separate project from Leptos app)
[package]
name = "my-worker"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
worker = "0.3"
serde = { version = "1", features = ["derive"] }
```

```rust
use worker::*;

#[event(fetch)]
async fn fetch(req: Request, env: Env, _ctx: Context) -> Result<Response> {
    let router = Router::new();
    
    router
        .get_async("/api/hello", |_req, _ctx| async move {
            Response::ok("Hello from the edge!")
        })
        .get_async("/api/geo", |req, _ctx| async move {
            let country = req.cf().unwrap().country().unwrap_or("Unknown".into());
            Response::ok(format!("You're in {}", country))
        })
        .run(req, env)
        .await
}
```

## Cloudflare KV (key-value store)

```rust
#[event(fetch)]
async fn fetch(req: Request, env: Env, _ctx: Context) -> Result<Response> {
    let router = Router::new();
    
    router
        .get_async("/cache/:key", |_req, ctx| async move {
            let kv = ctx.env.kv("MY_KV")?;
            let key = ctx.param("key").unwrap();
            
            match kv.get(key).text().await? {
                Some(value) => Response::ok(value),
                None => Response::error("Not found", 404),
            }
        })
        .put_async("/cache/:key", |mut req, ctx| async move {
            let kv = ctx.env.kv("MY_KV")?;
            let key = ctx.param("key").unwrap().to_string();
            let value = req.text().await?;
            
            kv.put(&key, value)?.expiration_ttl(3600).execute().await?;
            Response::ok("Cached")
        })
        .run(req, env)
        .await
}
```

## Building and deploying

```bash
# Install wrangler CLI
npm install -g wrangler

# Login to Cloudflare
wrangler login

# Build
cargo build --target wasm32-unknown-unknown --release

# Deploy
wrangler deploy
```

`wrangler.toml`:
```toml
name = "my-worker"
main = "build/worker/shim.mjs"
compatibility_date = "2024-01-01"

[build]
command = "cargo build --target wasm32-unknown-unknown --release"

[[kv_namespaces]]
binding = "MY_KV"
id = "your-kv-namespace-id"
```

## Using a Worker as an API gateway

```rust
// Proxy requests to your Leptos origin, adding auth headers
#[event(fetch)]
async fn fetch(mut req: Request, env: Env, ctx: Context) -> Result<Response> {
    // Verify JWT at the edge
    let token = req.headers().get("Authorization")?.unwrap_or_default();
    
    if !verify_jwt(&token, &env.secret("JWT_SECRET")?.to_string()) {
        return Response::error("Unauthorized", 401);
    }

    // Forward to origin
    let origin = env.var("ORIGIN_URL")?.to_string();
    let origin_url = format!("{}{}", origin, req.path());
    
    Fetch::Url(origin_url.parse()?)
        .send()
        .await
}

fn verify_jwt(token: &str, secret: &str) -> bool {
    // JWT verification logic using a pure Rust crate
    // (no OS or network access needed — pure computation)
    true // simplified
}
```

## Wasm on other edge platforms

| Platform | Wasm runtime | Key feature |
|----------|-------------|------------|
| Cloudflare Workers | V8 Isolates | KV, D1, R2 storage |
| Fastly Compute | Wasmtime | WASI-based, no JS |
| Deno Deploy | V8 | TypeScript-native |
| Fermyon Spin | Wasmtime | Component Model |
| Vercel Edge | V8 | Next.js integration |
