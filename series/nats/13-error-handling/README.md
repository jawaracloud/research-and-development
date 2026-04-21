# 13 — Error Handling

> **Type:** How-To  
> **Phase:** Foundations

## Overview

NATS has multiple layers where errors can occur — connection errors, subscription errors, async message errors, and JetStream publish errors. This lesson shows how to handle each correctly.

## Connection Errors

```go
nc, err := nats.Connect("nats://localhost:4222")
if err != nil {
    switch {
    case errors.Is(err, nats.ErrNoServers):
        log.Fatal("No NATS servers available")
    case errors.Is(err, nats.ErrTimeout):
        log.Fatal("Connection timed out")
    case errors.Is(err, nats.ErrAuthorization):
        log.Fatal("Authentication failed")
    default:
        log.Fatalf("Connect error: %v", err)
    }
}
```

## Request/Reply Errors

```go
reply, err := nc.Request("users.get", req, 2*time.Second)
switch {
case err == nil:
    // success
case errors.Is(err, nats.ErrNoResponders):
    // no service is listening on "users.get"
    // implement fallback or return 503
case errors.Is(err, nats.ErrTimeout):
    // service responded too slowly
    // implement retry with backoff
default:
    log.Printf("request error: %v", err)
}
```

## Async Subscription Error Handler

The global error handler fires for "slow consumer" and other async errors:

```go
nc, _ := nats.Connect(nats.DefaultURL,
    nats.ErrorHandler(func(nc *nats.Conn, sub *nats.Subscription, err error) {
        if errors.Is(err, nats.ErrSlowConsumer) {
            dropped, _ := sub.Dropped()
            log.Printf("SLOW CONSUMER on %s — dropped %d messages", sub.Subject, dropped)
            // Increase buffer, scale consumers, or implement backpressure
        }
    }),
)
```

## JetStream Publish Errors

```go
js, _ := nc.JetStream()

// Synchronous publish — errors immediately if stream doesn't exist
ack, err := js.Publish("orders.created", data)
if err != nil {
    switch {
    case errors.Is(err, nats.ErrNoStreamResponse):
        log.Println("No stream configured for this subject")
    case errors.Is(err, nats.ErrTimeout):
        log.Println("JetStream publish timeout")
    default:
        log.Printf("publish error: %v", err)
    }
}
log.Printf("Published seq %d", ack.Sequence)
```

## JetStream Consumer Errors

```go
js.Subscribe("orders.>", func(msg *nats.Msg) {
    err := processOrder(msg)
    if err != nil {
        // Negative ack — will be redelivered after AckWait expires
        msg.Nak()
        return
    }
    msg.Ack()
}, nats.Durable("order-processor"), nats.AckExplicit())
```

## Slow Consumer Prevention

```go
// Increase per-subscription pending limits
sub, _ := nc.Subscribe("high-volume.>", handler)
sub.SetPendingLimits(
    100_000,             // max pending messages (default: 65536)
    100*1024*1024,       // max pending bytes (100 MB)
)
```

## Error Sentinel Values Reference

| Error | Meaning |
|-------|---------|
| `ErrNoServers` | No NATS servers reachable |
| `ErrTimeout` | Operation exceeded timeout |
| `ErrAuthorization` | Auth failed |
| `ErrNoResponders` | No subscriber on request subject |
| `ErrSlowConsumer` | Consumer can't keep up |
| `ErrMaxPayload` | Message exceeds max payload |

---
*Part of the 100-Lesson NATS Series.*
