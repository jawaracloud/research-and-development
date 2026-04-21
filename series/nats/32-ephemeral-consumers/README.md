# 32 — Ephemeral Consumers

> **Type:** How-To  
> **Phase:** JetStream

## Overview

Ephemeral consumers are temporary consumers that exist only while a client is connected. They're deleted automatically when the client disconnects (after a configurable inactivity period).

## When to Use Ephemeral vs Durable

| | Ephemeral | Durable |
|-|-----------|---------|
| **State persistence** | ❌ Lost on disconnect | ✅ Preserved |
| **Resume on reconnect** | ❌ Starts fresh | ✅ From last ack |
| **Server cleanup** | ✅ Automatic | ❌ Manual deletion |
| **Use case** | Temporary queries, ad-hoc | Long-running services |

## Creating an Ephemeral Consumer

Omit the `Durable` option:

```go
js, _ := nc.JetStream()

// No nats.Durable() → ephemeral consumer
sub, err := js.Subscribe("orders.>",
    func(msg *nats.Msg) {
        fmt.Printf("Ephemeral recv: %s\n", msg.Subject)
        msg.Ack()
    },
    nats.AckExplicit(),
    nats.DeliverLast(),    // start from last message (common for ephemeral)
)
```

The server assigns a random name to the consumer. When `sub.Drain()` or disconnect occurs, the consumer is deleted after `InactiveThreshold`.

## Inactive Threshold

Configure how long before an ephemeral consumer is reaped:

```go
js.AddConsumer("ORDERS", &nats.ConsumerConfig{
    // No Durable = ephemeral
    AckPolicy:         nats.AckExplicitPolicy,
    InactiveThreshold: 30 * time.Second,   // delete if no activity for 30s
})
```

## Ordered Consumer (Special Ephemeral)

An **ordered consumer** is a special ephemeral that guarantees strict message ordering and auto-recreates itself if the server resets the sequence:

```go
// Read stream history in order — no ack needed
sub, _ := js.SubscribeSync("orders.>",
    nats.OrderedConsumer(),
    nats.DeliverAll(),
)

for {
    msg, err := sub.NextMsg(5 * time.Second)
    if err != nil { break }
    process(msg)
    // no ack needed — ordered consumers don't require ack
}
```

**Use cases for ephemeral:**
- Admin tools (inspect stream state)
- One-time data migrations or backfills
- Frontend WebSocket clients (each connection = unique cursor)
- CLI tooling

## Inspecting Ephemeral Consumers

```bash
nats consumer ls ORDERS
# NAME                           DURABLE     LAST-DELIVERED  ACK-PENDING
# orders.durable.payment-svc    payment-svc  Seq 100         0
# orders.ephemeral.kZfBa92X     -            Seq 50          5
```

---
*Part of the 100-Lesson NATS Series.*
