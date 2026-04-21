# 17 — Subject Naming Conventions

> **Type:** Reference  
> **Phase:** Foundations

## Overview

Well-designed subject hierarchies make NATS systems easier to maintain, monitor, and secure. This lesson establishes naming conventions for production use.

## Recommended Pattern

```
<domain>.<entity>.<event>.<qualifier>
```

| Segment | Purpose | Example |
|---------|---------|---------|
| `domain` | Business domain or service name | `orders`, `payments`, `users` |
| `entity` | Resource being acted on | `order`, `invoice`, `session` |
| `event` | What happened | `created`, `updated`, `deleted` |
| `qualifier` | Optional: region, version, source | `us-east`, `v2`, `stripe` |

## Examples

```
orders.created
orders.cancelled
payments.processed
payments.refund.issued
users.verified.email
users.login.failed
inventory.stock.depleted
sensors.temperature.zone-a
```

## Versioning

```
# Include version in subject for schema evolution
orders.v1.created
orders.v2.created       # new schema; both streams can coexist
```

## Environment Namespacing

```
# Avoid cross-environment message leakage with accounts (preferred)
# Or use subject prefix:
staging.orders.created
prod.orders.created

# But prefer NATS accounts over subject prefixes for isolation!
```

## Internal vs External

```
# Internal service communication
_INTERNAL_.payments.processed   # leading _ = internal convention
payments.processed               # public subject for fan-out

# API gateway subjects
api.users.get
api.orders.create
```

## Anti-Patterns

```
❌ OrderCreated                   # no hierarchy, hard to wildcard
❌ order-created                  # hyphen as separator (breaks * wildcard)
❌ order/created                  # slash is not valid in NATS subjects
❌ o.c                            # too abbreviated, unreadable
❌ orders.created.for.user.123   # too deep, prefer data in payload
```

## Wildcard Design Table

```
Your subjects:
  orders.created
  orders.cancelled
  payments.processed
  users.login.failed

Subject patterns and what they match:
  orders.*       → orders.created, orders.cancelled
  orders.>       → same
  *.created      → orders.created (NOT payments, since no 'created')
  >              → everything (use sparingly in production)
  orders.*       → only orders events
```

## Multi-Team Governance

Create a `subjects.md` registry in your repo:

```markdown
| Subject | Producer | Consumer(s) | Schema |
|---------|---------|-------------|--------|
| orders.created | order-svc | payment-svc, inventory-svc | v2 |
| payments.processed | payment-svc | order-svc, notification-svc | v1 |
```

---
*Part of the 100-Lesson NATS Series.*
