# 56 — Multi-Tenant Architecture

> **Type:** How-To  
> **Phase:** Patterns & Architecture

## Overview

Multi-tenancy in NATS is achieved using **Accounts**. Each account is a complete virtual NATS server with its own namespace for subjects, streams, and consumers, while sharing the underlying cluster infrastructure.

## Key Concepts

- **Accounts:** Isolated namespaces for subjects and JetStream data.
- **Imports/Exports:** Controlled sharing of subjects between accounts.
- **Operators:** The root authority that signs Account JWTs.

## Defining Accounts in nats-server.conf

For static configuration:

```
accounts {
  APP_A {
    users = [ { user: "user-a", password: "password-a" } ]
    jetstream: enabled
  }
  APP_B {
    users = [ { user: "user-b", password: "password-b" } ]
    jetstream: enabled
  }
}
```

## Isolation in Action

```bash
# Client in APP_A publishes to "orders.created"
nats pub orders.created "data" --user user-a --password password-a

# Client in APP_B subscribes to "orders.created" -- NOT RECEIVED
nats sub orders.created --user user-b --password password-b
```

## Cross-Account Sharing (Service Export)

If `APP_B` needs to call a service in `APP_A`:

```
accounts {
  APP_A {
    exports [
      { service: "api.users.>" }
    ]
  }
  APP_B {
    imports [
      { service: { account: "APP_A", subject: "api.users.>" }, to: "app_a.users.>" }
    ]
  }
}
```

Now `APP_B` can request `app_a.users.get` and it will be routed to `APP_A`.

## Dynamic Multi-Tenancy (JWT/NSC)

For production, use `nsc` to manage multi-tenancy:

```bash
# Create operator
nsc add operator MY_CORP

# Create account per tenant
nsc add account TENANT_1
nsc add account TENANT_2

# Generate credentials for tenants
nsc add user -a TENANT_1 user-1
nsc gen creds -a TENANT_1 -n user-1 > tenant1.creds
```

## Why Multi-Tenancy?

| Benefit | Description |
|---------|-------------|
| **Security** | Subjects are isolated by default. |
| **Governance** | Different teams own their own namespaces. |
| **Quotas** | Limit JetStream resources per account. |
| **Simplicity** | Reuse subjects (every tenant can have "orders.>") without collision. |

---
*Part of the 100-Lesson NATS Series.*
