# 74 — Resource Quotas & Limits

> **Type:** How-To  
> **Phase:** Production & Operations

## Overview

Quotas prevent a single team or application from consuming all the resources of a shared NATS cluster (The "Noisy Neighbor" problem).

## 1. JetStream Account Limits

Control the total footprint of an account's JetStream usage.

```
accounts {
  TEAM_X {
    jetstream {
        max_mem: 1GB        # Max memory storage for JS
        max_file: 100GB     # Max disk storage for JS
        max_streams: 10     # Max number of streams
        max_consumers: 50   # Max number of consumers
    }
  }
}
```

## 2. Stream-Level Limits

Each individual stream should have limits to avoid runaway data growth.

- `MaxMsgs`: Maximum number of messages.
- `MaxBytes`: Maximum total size.
- `MaxAge`: Maximum age of a message (TTL).

## 3. Connection Limits

Limit the number of clients a user can connect.

```
users = [
  {
    user: "web-client"
    max_payload: 1024       # Limit msg size specifically for this user
    max_subs: 10            # Limit subscriptions
  }
]
```

## 4. Monitoring the Caps

Use the NATS CLI to see how much of their quota an account has used:

```bash
nats account info
# JetStream Account Information:
#   Memory: 512.0 MB of 1.0 GB (50%)
#   Storage: 12.4 GB of 100.0 GB (12%)
```

## Handling Quota Errors
When a quota is hit, the operation will fail with a `nats: quota exceeded` error. Your application code should handle this gracefully (logging/alerting) rather than crashing.

---
*Part of the 100-Lesson NATS Series.*
