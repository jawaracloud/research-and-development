# 73 — Account Isolation

> **Type:** Explanation  
> **Phase:** Production & Operations

## Overview

Account isolation is the primary multi-tenancy mechanism in NATS. It provides a clean boundary between different applications or teams sharing the same cluster.

## Why use Accounts?

- **Subject Namespacing:** `PROD_A` and `PROD_B` can both have a subject named `orders`. They are completely distinct.
- **Resource Quotas:** You can limit JetStream storage per account.
- **Security:** One account cannot see or touch messages in another account unless explicitly imported/exported.

## The Global Account (Default)
If you don't define accounts, everything runs in the `$G` (Global) account. This is fine for development but not for production.

## Defining Accounts

`server.conf`:
```
accounts {
  AUTH_SERVICE {
    jetstream: enabled
    users = [ {user: "auth", password: "p"} ]
  }
  PAYMENT_SERVICE {
    jetstream: enabled
    users = [ {user: "pay", password: "p"} ]
  }
}
```

## The System Account ($SYS)
NATS uses a special internal account for administration and monitoring.
- **NEVER** run your application logic in the system account.
- Use it only for metrics and cluster management.

## Cross-Account Communication
To bridge the gap between accounts, use **Service Exports/Imports** (Streams) or **Service Mapping**. (See Lesson 56 for implementation).

## Summary Table

| Scope | Visibility | Usage |
|-------|------------|-------|
| **Subject** | Global to Account | App messaging |
| **Stream** | Global to Account | Persistent data |
| **Account** | Isolated | Security boundary |
| **Cluster** | Shares hardware | Infrastructure |

---
*Part of the 100-Lesson NATS Series.*
