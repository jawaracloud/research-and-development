# 03 — Core NATS vs JetStream

> **Type:** Explanation  
> **Phase:** Foundations

## Overview

NATS has two operating modes: **Core NATS** (pure pub/sub, no persistence) and **JetStream** (persistent streaming). Knowing when to use each is fundamental.

## Core NATS

Core NATS is a **fire-and-forget** message bus:

- Messages are delivered to **currently connected** subscribers only
- If no subscriber is connected when a message is published → **message is dropped**
- Zero disk I/O → extremely low latency and overhead
- No acknowledgement mechanism

```go
// Publisher
nc.Publish("weather.update", []byte(`{"temp":25}`))

// Subscriber — if not connected at publish time, msg is lost
nc.Subscribe("weather.update", func(msg *nats.Msg) {
    fmt.Println(string(msg.Data))
})
```

**Use core NATS for:**
- Real-time telemetry (latest value is all that matters)
- Service discovery (heartbeats)
- Request/Reply APIs (synchronous RPC)
- Any scenario where message loss is acceptable

## JetStream

JetStream adds **persistence and delivery guarantees** on top of core NATS:

- Messages are written to disk/memory before delivery
- Subscribers can be **offline** and receive messages when they reconnect (replay)
- **Acknowledgements** confirm delivery; unacked messages are redelivered
- Consumers maintain a **cursor** into the stream

```go
// Publisher — publishes to stream that persists messages
js, _ := nc.JetStream()
js.Publish("orders.created", []byte(`{"orderId":"abc"}`))

// Consumer — receives messages even if it was offline
sub, _ := js.Subscribe("orders.created", func(msg *nats.Msg) {
    msg.Ack()  // required — tells JetStream: delivered
}, nats.Durable("payment-svc"), nats.AckExplicit())
```

**Use JetStream for:**
- Order/payment/event processing (cannot lose messages)
- Event sourcing (need full message history)
- Fan-out to slow consumers (audit, analytics)
- Any scenario requiring at-least-once delivery

## Decision Tree

```
Is message loss acceptable?
  Yes → Core NATS pub/sub
  No  → JetStream

Do consumers need to replay history?
  Yes → JetStream (with DeliverAll policy)
  No  → JetStream (with DeliverLast or DeliverNew)

Is this a synchronous API call?
  Yes → Core NATS Request/Reply
  No  → JetStream
```

## Comparison

| Feature | Core NATS | JetStream |
|---------|-----------|-----------|
| Persistence | ❌ | ✅ |
| At-least-once delivery | ❌ | ✅ |
| Replay history | ❌ | ✅ |
| Acknowledgements | ❌ | ✅ (required) |
| Latency overhead | None | ~1–2 ms disk write |
| Offline consumer support | ❌ | ✅ (durable consumers) |
| Memory footprint | Minimal | + stream storage |

---
*Part of the 100-Lesson NATS Series.*
