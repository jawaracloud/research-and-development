# 33 — Ordered Consumers

> **Type:** How-To  
> **Phase:** JetStream

## Overview

Ordered consumers are a special JetStream consumer variant that guarantees strict message delivery in stream order, automatically handles resets, and requires no acknowledgements.

## Properties

| Property | Value |
|----------|-------|
| Type | Push-based, ephemeral |
| Ordering | Strict sequence order guaranteed |
| Ack | Not required (AckNone) |
| Auto-reset | ✅ Recreates consumer if sequence gap detected |
| Concurrent subscribers | ❌ One subscription only |

## Use Case: Stream Auditing

```go
js, _ := nc.JetStream()

// Read all historical orders in order — no ack needed
sub, err := js.Subscribe("orders.>",
    func(msg *nats.Msg) {
        meta, _ := msg.Metadata()
        fmt.Printf("[Seq:%d] %s\n", meta.Sequence.Stream, msg.Subject)
        // No msg.Ack() needed
    },
    nats.OrderedConsumer(),
    nats.DeliverAll(),  // full history
)
if err != nil {
    log.Fatal(err)
}
defer sub.Drain()
```

## Use Case: Live Tail (like `tail -f`)

```go
// Follow the stream in real time (new messages only)
sub, _ := js.Subscribe("logs.>",
    func(msg *nats.Msg) {
        fmt.Printf("%s\n", msg.Data)
    },
    nats.OrderedConsumer(),
    nats.DeliverNew(),   // only new messages
)
```

## How Auto-Reset Works

If the server resets the consumer (e.g., after a reconnect that missed messages), the ordered consumer automatically:
1. Detects the sequence gap
2. Recreates itself at the correct position
3. Continues delivery without interruption

```go
// Behind the scenes in the nats.go library:
// If seq received = expected-1 >= 0 → gap detected
// → delete and recreate consumer from last known good seq
```

## Sync Version (for scripts/tests)

```go
sub, _ := js.SubscribeSync("orders.>",
    nats.OrderedConsumer(),
    nats.DeliverAll(),
)

count := 0
for {
    msg, err := sub.NextMsg(time.Second)
    if err != nil { break }
    count++
    fmt.Printf("[%d] %s\n", count, msg.Subject)
}
fmt.Printf("Total: %d messages\n", count)
```

## CLI Equivalent

```bash
# Stream all messages in order from beginning
nats stream view ORDERS --all

# Tail new messages live
nats sub --stream ORDERS "orders.>" --last 0
```

## When NOT to use ordered consumers

- ❌ Work queues (ordered consumers don't parallelise)
- ❌ Long processing per message (no ack = no redelivery on failure)
- ❌ Multiple competing consumers on same stream

---
*Part of the 100-Lesson NATS Series.*
