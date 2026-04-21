# 35 — Exactly-Once Delivery

> **Type:** How-To  
> **Phase:** JetStream

## Overview

True exactly-once delivery in distributed systems requires coordination at both the publisher and consumer sides. JetStream provides the building blocks; this lesson shows how to wire them together.

## The Two-Part Problem

```
At-least-once = publisher retries + consumer acks
Exactly-once  = at-least-once + idempotent consumer
```

JetStream guarantees **at-least-once** delivery natively. Exactly-once requires:
1. **Publisher deduplication** — prevent the same message from being stored twice
2. **Idempotent consumer** — process the same message N times with the same result

## Part 1: Publisher Deduplication

Set a unique `Nats-Msg-Id` header on each message. JetStream will reject duplicates within the stream's `Duplicates` window.

```go
js, _ := nc.JetStream()

// Configure deduplication window on stream
js.AddStream(&nats.StreamConfig{
    Name:       "ORDERS",
    Subjects:   []string{"orders.>"},
    Duplicates: 5 * time.Minute,    // dedup window
})

// Publish with idempotency key
func publishOnce(js nats.JetStreamContext, subject string, data []byte, idempotencyKey string) error {
    msg := &nats.Msg{
        Subject: subject,
        Data:    data,
        Header:  nats.Header{},
    }
    msg.Header.Set(nats.MsgIdHdr, idempotencyKey)

    ack, err := js.PublishMsg(msg)
    if err != nil {
        return err
    }
    if ack.Duplicate {
        log.Printf("Duplicate detected for key %s — skipping", idempotencyKey)
    }
    return nil
}

// Usage: use a deterministic key based on business entity
publishOnce(js, "orders.created", data, "order-abc-123-v1")
```

## Part 2: Idempotent Consumer

```go
js.Subscribe("orders.created",
    func(msg *nats.Msg) {
        orderID := extractOrderID(msg.Data)

        // Check if already processed (use a DB or Redis dedup table)
        if alreadyProcessed(orderID) {
            log.Printf("Order %s already processed — acking duplicate", orderID)
            msg.Ack()
            return
        }

        // Process
        if err := processPayment(orderID, msg.Data); err != nil {
            msg.Nak()
            return
        }

        // Mark as processed
        markAsProcessed(orderID)
        msg.Ack()
    },
    nats.Durable("payment-svc"),
    nats.AckExplicit(),
)
```

## Tracking with PostgreSQL

```sql
CREATE TABLE processed_events (
    msg_id     TEXT PRIMARY KEY,
    processed_at TIMESTAMPTZ DEFAULT now()
);
```

```go
func alreadyProcessed(msgID string) bool {
    var count int
    db.QueryRow("SELECT COUNT(*) FROM processed_events WHERE msg_id=$1", msgID).Scan(&count)
    return count > 0
}

func markAsProcessed(msgID string) {
    db.Exec("INSERT INTO processed_events (msg_id) VALUES ($1) ON CONFLICT DO NOTHING", msgID)
}
```

## Summary

```
Publisher:  Set Nats-Msg-Id → JetStream deduplicates within window
Consumer:   Check + record msgID in DB → application-level dedup
Result:     Exactly-once business effect even under retries
```

---
*Part of the 100-Lesson NATS Series.*
