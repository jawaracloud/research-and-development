# 27 — Retention Policies

> **Type:** Reference  
> **Phase:** JetStream

## Overview

JetStream retention policies determine **when messages are removed** from a stream. Choosing the right policy is fundamental to your stream's storage, durability, and consistency semantics.

## The Three Retention Policies

### LimitsPolicy (default)

Messages are retained based on configurable limits. When a limit is hit, the oldest messages are deleted.

```go
&nats.StreamConfig{
    Retention: nats.LimitsPolicy,
    MaxAge:    7 * 24 * time.Hour,   // delete messages older than 7 days
    MaxBytes:  10 << 30,             // delete oldest when over 10 GB
    MaxMsgs:   1_000_000,            // delete oldest when over 1M messages
    Discard:   nats.DiscardOld,      // default: discard old
}
```

**Use when:** Time-series data, audit logs, event stores with known data volume.

### InterestPolicy

Messages are retained **until every consumer has acked them**. When all consumers have processed a message, it's deleted.

```go
&nats.StreamConfig{
    Retention: nats.InterestPolicy,
    Subjects:  []string{"orders.>"},
}
```

**Requirements:**
- At least one consumer must exist, otherwise all messages are immediately deleted
- Every consumer must ack for retention to apply

**Use when:** Fan-out scenarios where all downstream services must process each event before it's purged.

### WorkQueuePolicy

Message is deleted **as soon as one consumer acks it**. Implements a true work queue: each message is processed by exactly one worker.

```go
&nats.StreamConfig{
    Retention: nats.WorkQueuePolicy,
    Subjects:  []string{"tasks.>"},
}
```

**Use when:** Job queues, task processing, work distribution.

## Discard Policies

When stream limits are hit, what happens to **new** messages?

```go
Discard: nats.DiscardOld    // default: delete oldest to make room for new
Discard: nats.DiscardNew    // reject new messages when full (publisher gets error)
```

## Per-Subject Message Limits

Limit how many messages per unique subject are retained:

```go
&nats.StreamConfig{
    MaxMsgsPerSubject: 1,    // keep only the LAST message per subject
    // Useful for: configuration store, last-known-value cache
}
```

## Comparison Table

| Policy | When deleted | Use case |
|--------|-------------|---------|
| `LimitsPolicy` | When size/age/count limit hit | General purpose |
| `InterestPolicy` | When all consumers ack | Fan-out, confirmed delivery |
| `WorkQueuePolicy` | When any one consumer acks | Job queue |

```bash
# Check stream state and limits
nats stream info ORDERS
# State:
#   Messages: 45,123
#   Bytes:    2.3 GB
#   First:    Seq 1
#   Last:     Seq 45,123
```

---
*Part of the 100-Lesson NATS Series.*
