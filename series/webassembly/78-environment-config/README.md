# 78 — Environment Variables and Configuration

> **Type:** How-To + Reference

## Configuration sources

| Source | When loaded | Who reads it |
|--------|------------|-------------|
| `.env` file | Development | `dotenvy` at startup |
| Shell env vars | Production | `std::env::var` |
| `Leptos.toml` | Build time | `cargo-leptos` |
| Config file (TOML/JSON) | Startup | `config` crate |

## Method 1: dotenvy + std::env (simple)

```toml
[dependencies]
dotenvy = "0.15"
```

`.env` (development only — never commit secrets):
```
DATABASE_URL=sqlite:./dev.db
SESSION_SECRET=super-secret-dev-key
PORT=3000
RUST_LOG=debug
```

```rust
// In main.rs
fn main() {
    // Load .env for development (silently ignores missing file in production)
    dotenvy::dotenv().ok();

    let db_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    let port: u16 = std::env::var("PORT")
        .unwrap_or("3000".into())
        .parse()
        .expect("PORT must be a number");
}
```

## Method 2: config crate (structured)

For complex applications with multiple environments:

```toml
[dependencies]
config = "0.14"
serde = { version = "1", features = ["derive"] }
```

`config/default.toml`:
```toml
[server]
host = "127.0.0.1"
port = 3000

[database]
url = "sqlite:./app.db"
max_connections = 5

[auth]
session_duration_hours = 24
```

`config/production.toml`:
```toml
[server]
port = 8080

[database]
max_connections = 20
```

```rust
use config::{Config, Environment, File};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct Settings {
    pub server: ServerConfig,
    pub database: DatabaseConfig,
    pub auth: AuthConfig,
}

#[derive(Debug, Deserialize)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
}

#[derive(Debug, Deserialize)]
pub struct DatabaseConfig {
    pub url: String,
    pub max_connections: u32,
}

#[derive(Debug, Deserialize)]
pub struct AuthConfig {
    pub session_duration_hours: u64,
}

impl Settings {
    pub fn load() -> Result<Self, config::ConfigError> {
        let env = std::env::var("APP_ENV").unwrap_or_else(|_| "development".into());

        Config::builder()
            // Base defaults
            .add_source(File::with_name("config/default"))
            // Environment-specific overrides
            .add_source(File::with_name(&format!("config/{}", env)).required(false))
            // Environment variable overrides (e.g., APP_DATABASE_URL)
            .add_source(Environment::with_prefix("APP").separator("_"))
            .build()?
            .try_deserialize()
    }
}
```

## Method 3: Leptos environment config

Leptos uses `Leptos.toml` for build-time configuration and `LEPTOS_*` env vars at runtime:

```toml
# Leptos.toml
[package.metadata.leptos]
env = "DEV"
site-addr = "127.0.0.1:3000"
```

```bash
# Production override:
LEPTOS_ENV=PROD LEPTOS_SITE_ADDR=0.0.0.0:8080 ./myapp
```

## Sharing config with Leptos context

```rust
#[tokio::main]
async fn main() {
    let settings = Settings::load().expect("Failed to load config");
    let settings = Arc::new(settings);

    let app = Router::new()
        .leptos_routes_with_context(
            &leptos_options,
            routes,
            {
                let settings = settings.clone();
                move || provide_context(settings.clone())
            },
            App,
        )
        .with_state(leptos_options);
}

// In server functions:
#[server(ConfigCheck, "/api")]
async fn config_check() -> Result<String, ServerFnError> {
    let settings = use_context::<Arc<Settings>>()
        .ok_or_else(|| ServerFnError::ServerError("no config".into()))?;
    
    Ok(format!("Running on port {}", settings.server.port))
}
```

## Secrets management

Never hardcode secrets. For production:
- **Development**: `.env` file (gitignored).
- **CI/CD**: Pipeline secret variables.
- **Production servers**: System environment variables or secret manager (AWS Secrets Manager, HashiCorp Vault).

```bash
# .gitignore
.env
*.secret
config/production.toml
```

## Build-time constants

For values baked into the binary at compile time:

```rust
// In build.rs:
fn main() {
    println!("cargo:rustc-env=BUILD_VERSION={}", env!("CARGO_PKG_VERSION"));
    println!("cargo:rustc-env=BUILD_DATE={}", chrono::Utc::now().format("%Y-%m-%d"));
}

// In app:
const VERSION: &str = env!("BUILD_VERSION");
const BUILD_DATE: &str = env!("BUILD_DATE");
```
