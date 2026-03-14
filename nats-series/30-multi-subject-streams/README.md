# 30 — Multi-Subject Streams

> **Type:** Tutorial  
> **Phase:** JetStream

## What you're building

Create streams that capture messages from multiple subjects, enabling a single stream to serve as a unified event log across multiple services.

## Why Multi-Subject Streams?

```
Single subject stream:
  Stream ORDERS: subjects = ["orders.created"]
  Stream PAYMENTS: subjects = ["payments.processed"]
  Stream INVENTORY: subjects = ["inventory.updated"]
  → 3 streams to manage

Multi-subject stream:
  Stream EVENTS: subjects = ["orders.>", "payments.>", "inventory.>"]
  → 1 stream for all business events
```

A single stream can:
- Provide a **global event log** (audit trail)
- Allow **per-consumer filtering** via `FilterSubject`
- Simplify stream management

## Step 1: Create a multi-subject stream

```go
js, _ := nc.JetStream()

_, err := js.AddStream(&nats.StreamConfig{
    Name:    "BUSINESS-EVENTS",
    Subjects: []string{
        "orders.>",
        "payments.>",
        "inventory.>",
        "users.>",
    },
    MaxAge:  30 * 24 * time.Hour,  // 30-day retention
    Storage: nats.FileStorage,
    Replicas: 3,
})
```

## Step 2: Per-service consumers with filter

Each service subscribes to the multi-subject stream with a filter:

```go
// Payment service — only sees orders.created
paymentSub, _ := js.Subscribe("orders.created",
    func(msg *nats.Msg) {
        // process payment
        msg.Ack()
    },
    nats.BindStream("BUSINESS-EVENTS"),
    nats.Durable("payment-svc"),
    nats.AckExplicit(),
)

// Audit service — sees everything
auditSub, _ := js.Subscribe(">",
    func(msg *nats.Msg) {
        auditLog(msg)
        msg.Ack()
    },
    nats.BindStream("BUSINESS-EVENTS"),
    nats.Durable("audit-svc"),
    nats.DeliverAll(),    // full history
)
```

## Step 3: Publish to any subject

```go
// All of these go into BUSINESS-EVENTS stream
js.Publish("orders.created",    orderData)
js.Publish("payments.processed", paymentData)
js.Publish("inventory.updated",  inventoryData)
```

## Step 4: Verify messages in stream

```bash
nats stream info BUSINESS-EVENTS
nats stream view BUSINESS-EVENTS --subject "orders.>"

# Count messages per subject
nats stream report BUSINESS-EVENTS
```

## Anti-pattern: Too many subjects in one stream

Don't put unrelated subjects in the same stream if:
- They have vastly different retention requirements
- They have very different throughput (one subject drowns out others in limits)
- Different teams own them (governance nightmare)

**Rule of thumb:** One stream per bounded context / domain.

---
*Part of the 100-Lesson NATS Series.*
