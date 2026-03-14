# 14 — Authentication & Authorization

> **Type:** How-To  
> **Phase:** Foundations

## Overview

NATS supports multiple authentication mechanisms. This lesson covers the most common: token auth, username/password, and TLS client certificates, progressing from simplest to most production-ready.

## Authentication Methods Compared

| Method | Complexity | Best for |
|--------|-----------|---------|
| No auth | None | Local development only |
| Token | Low | Simple shared secret |
| Username/Password | Low | Per-client credentials |
| NKey | Medium | Secure key-pair auth |
| JWT + NKey | High | Multi-tenant, full RBAC |
| TLS Client Certs | Medium | mTLS environments |

## Method 1: Token Authentication

`nats-server.conf`:
```
authorization {
  token: "my-secret-token-change-me"
}
```

```go
nc, _ := nats.Connect("nats://localhost:4222",
    nats.Token("my-secret-token-change-me"),
)
```

```bash
nats pub test "hello" --server nats://token:my-secret-token-change-me@localhost:4222
```

## Method 2: Username/Password

`nats-server.conf`:
```
authorization {
  users = [
    { user: "publisher", password: "pub-pass", permissions: { publish: ">" } }
    { user: "subscriber", password: "sub-pass", permissions: { subscribe: ">" } }
  ]
}
```

```go
nc, _ := nats.Connect("nats://localhost:4222",
    nats.UserInfo("publisher", "pub-pass"),
)
```

## Method 3: NKeys (Ed25519 key pairs)

```bash
# Generate NKey seed
nats auth nkeys create user --store
# Output: SUAKDGDMUBPVQJK... (seed — keep secret)
#         UBHQPJ... (public key — share in config)
```

`nats-server.conf`:
```
authorization {
  users = [
    { nkey: "UBHQPJ..." }
  ]
}
```

```go
nkeyOpt, _ := nats.NkeyOptionFromSeed("SUAKDGDMUBPVQJK...")
nc, _ := nats.Connect("nats://localhost:4222", nkeyOpt)
```

## Method 4: Credentials file (JWT + NKey)

Used with NATS accounts and JWT-based auth (production standard):

```bash
# Create operator, account, user
nats auth create operator Jawaracloud
nats auth account create APP
nats auth user create app-service --account APP

# Export credentials
nats auth user push app-service --account APP
# Saves: ~/.local/share/nats/nsc/keys/creds/Jawaracloud/APP/app-service.creds
```

```go
nc, _ := nats.Connect("nats://localhost:4222",
    nats.UserCredentials("/path/to/app-service.creds"),
)
```

## Subject-Level Authorization

```
authorization {
  users = [
    {
      user: "order-svc"
      password: "secret"
      permissions: {
        publish:   ["orders.>"]          # can only publish to orders.*
        subscribe: ["payments.results"]  # can only receive payment results
      }
    }
  ]
}
```

Unauthorized publish/subscribe results in `nats.ErrAuthorization`.

---
*Part of the 100-Lesson NATS Series.*
