# 06 — Queue Groups

> **Type:** Explanation  
> **Phase:** Foundations

## Overview

**Queue groups** enable horizontal scaling of message consumers. Multiple subscribers join a named queue group on the same subject; NATS delivers each message to **exactly one** member of the group (round-robin load balancing), rather than all of them.

## How It Works

```
Publisher → "orders.process"
                    │
         [Queue Group: "order-workers"]
          ┌─────────┼─────────┐
       Worker-1  Worker-2  Worker-3
          ↑
     (only one receives each message)
```

Without a queue group all three workers receive every message. With a queue group the workload is distributed.

## Go Implementation

```go
package main

import (
    "fmt"
    "os"
    "github.com/nats-io/nats.go"
)

func main() {
    nc, _ := nats.Connect(nats.DefaultURL)
    defer nc.Drain()

    workerID := os.Getenv("WORKER_ID")

    // All workers subscribe to the same subject + queue group
    nc.QueueSubscribe("orders.process", "order-workers", func(msg *nats.Msg) {
        fmt.Printf("[Worker-%s] Processing: %s\n", workerID, msg.Data)
        // ... process order
    })

    // Block indefinitely
    select {}
}
```

Run 3 instances: `WORKER_ID=1 go run main.go &; WORKER_ID=2 go run main.go &; WORKER_ID=3 go run main.go &`

Publish 9 messages → each worker gets ~3 (round-robin).

## Queue Groups in JetStream

In JetStream, queue groups work via **consumer groups** on a durable consumer:

```go
js, _ := nc.JetStream()

// All instances share the same durable consumer name
js.QueueSubscribe("orders.>", "order-workers", func(msg *nats.Msg) {
    msg.Ack()
    fmt.Printf("Processing: %s\n", msg.Subject)
}, nats.Durable("order-processor"), nats.AckExplicit())
```

## Behaviour Properties

| Property | Queue Group |
|----------|-------------|
| Delivery | Exactly one group member |
| Ordering | Per-subject (within one consumer) |
| Scaling | Add/remove workers at runtime |
| Failover | If worker crashes, others pick up |

## Core pub/sub vs Queue Group

```
pub/sub (no queue group):
  Publish("orders.new") → Worker-1, Worker-2, Worker-3 (all get it)

Queue group:
  QueueSubscribe("orders.new", "workers") → Worker-1 only (or 2, or 3)
```

## When to use Queue Groups

✅ CPU/IO-bound processing (distribute work)  
✅ Horizontal scaling — add workers without config changes  
✅ High-availability — if one worker dies, others consume  
❌ Fan-out (all subscribers must receive) — use regular Subscribe  

---
*Part of the 100-Lesson NATS Series.*
