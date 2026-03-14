# 72 — Access Control Lists (ACL)

> **Type:** How-To  
> **Phase:** Production & Operations

## Overview

ACLs define exactly what a user or service is allowed to do within an account. This is the cornerstone of the "Principle of Least Privilege" in NATS.

## 1. Subject-Level Permissions

Restrict which subjects a user can publish to or subscribe from.

```
# nats-server.conf (Static)
users = [
  {
    user: "order-svc"
    password: "pwd"
    permissions {
      publish: ["orders.created", "orders.updated"]
      subscribe: ["orders.delete"]
    }
  }
]
```

## 2. Wildcard ACLs

You can use standard NATS wildcards (`*`, `>`) in ACLs.

```
publish: ["orders.v1.*"]  # Only v1 subjects
subscribe: ["orders.>"]   # Everything under orders
```

## 3. "Deny" Rules (Advanced)

Exclude specific subjects from a broader permission.

```
permissions {
  subscribe {
    allow: [">"]
    deny: ["_audit.>"]
  }
}
```

## 4. Connection Restrictions

Limit based on network location or time.

```
users = [
  {
    user: "internal-worker"
    allowed_ips: ["10.0.0.0/24"]  # Only from internal subnet
  }
]
```

## 5. NSC (JWT) Implementation

When using `nsc`, permissions are encoded in the User JWT.

```bash
# Update user permissions
nsc edit user -a MY_APP -n order-svc \
    --allow-pub "orders.created" \
    --allow-sub "orders.update"

# Push the changes to the server
nsc push
```

## Best Practice: The Deny-By-Default Policy
Always start with no permissions and add only what is strictly necessary. Never use `allow: [">"]` for a production service.

---
*Part of the 100-Lesson NATS Series.*
