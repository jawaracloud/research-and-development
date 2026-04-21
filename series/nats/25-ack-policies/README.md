# 25 — Ack Policies

> **Type:** How-To  
> **Phase:** JetStream

## Overview

JetStream acknowledgement policies control how the server knows a message has been successfully processed. Choosing the right policy is critical for correctness and performance.

## The Three Ack Policies

### AckNone — No acknowledgement

Server delivers and forgets. Message is not redelivered even if consumer crashes.

```go
js.Subscribe("notifications.>", func(msg *nats.Msg) {
    sendEmail(msg)   // if this fails, message is lost
    // no ack needed
}, nats.AckNone())
```

**Use when:** Fire-and-forget notifications where duplicate/loss is acceptable.

---

### AckAll — Cumulative acknowledgement

Acking message at sequence N implicitly acks all previous messages (N-1, N-2, …).

```go
js.Subscribe("audit.>", func(msg *nats.Msg) {
    if err := writeAuditLog(msg); err != nil {
        msg.Nak()
        return
    }
    msg.Ack()   // acks this AND all previously unacked messages
}, nats.AckAll())
```

**Use when:** Sequential, ordered processing where partial batches are safe to commit together.

---

### AckExplicit — Individual acknowledgement (recommended)

Each message must be acked independently. This is the safest and most common policy.

```go
js.Subscribe("orders.created", func(msg *nats.Msg) {
    if err := processPayment(msg); err != nil {
        msg.Nak()      // nack → redeliver after AckWait
        return
    }
    msg.Ack()          // success
}, nats.AckExplicit(), nats.Durable("payment-svc"))
```

**Use when:** Critical business logic (payments, inventory) where every message must be confirmed.

## Ack Methods Reference

```go
msg.Ack()            // success — do not redeliver
msg.Nak()            // failure — redeliver after AckWait
msg.NakWithDelay(5 * time.Second)  // redeliver after 5s specifically
msg.Term()           // terminate — do NOT redeliver (poison message)
msg.InProgress()     // extend AckWait timer (still processing)
```

## Handling Slow Processing

```go
js.Subscribe("orders.>", func(msg *nats.Msg) {
    // Long-running operation — keep extending the AckWait
    ticker := time.NewTicker(10 * time.Second)
    done := make(chan struct{})

    go func() {
        for {
            select {
            case <-ticker.C:
                msg.InProgress()   // reset AckWait timer
            case <-done:
                return
            }
        }
    }()

    doSlowWork(msg)    // may take 60+ seconds
    close(done)
    ticker.Stop()
    msg.Ack()
}, nats.AckExplicit(), nats.AckWait(30*time.Second))
```

## Poison Message Handling

```go
msg.AckOpts()   // get metadata
meta, _ := msg.Metadata()

if meta.NumDelivered >= 5 {
    // Too many failures — send to dead letter subject
    nc.Publish("orders.dead-letter", msg.Data)
    msg.Term()   // stop redelivery
    return
}
```

---
*Part of the 100-Lesson NATS Series.*
