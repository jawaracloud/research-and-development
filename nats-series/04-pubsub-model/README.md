# 04 — Pub/Sub Model

> **Type:** Explanation  
> **Phase:** Foundations

## Overview

The **publish/subscribe** pattern is the foundational communication model in NATS. Publishers send messages to a subject; all current subscribers on that subject receive a copy.

## How It Works

```
Publisher: nc.Publish("prices.BTC", price)
                    │
             [nats-server routes by subject]
                    │
           ┌────────┴────────┐
      Subscriber-1       Subscriber-2
    (dashboard-svc)    (alert-svc)
```

Every subscriber receives **every message** — this is fan-out (1-to-many delivery).

## Go Implementation

```go
package main

import (
    "fmt"
    "log"
    "time"

    "github.com/nats-io/nats.go"
)

func main() {
    nc, _ := nats.Connect(nats.DefaultURL)
    defer nc.Drain()

    // Subscriber 1
    nc.Subscribe("prices.BTC", func(msg *nats.Msg) {
        fmt.Printf("[Dashboard] BTC price: %s\n", msg.Data)
    })

    // Subscriber 2
    nc.Subscribe("prices.BTC", func(msg *nats.Msg) {
        fmt.Printf("[Alerts] Received BTC update: %s\n", msg.Data)
    })

    // Publisher
    for i := 0; i < 5; i++ {
        nc.Publish("prices.BTC", []byte(fmt.Sprintf(`{"usd":%d}`, 60000+i*100)))
        time.Sleep(500 * time.Millisecond)
    }
}
```

## Wildcard Subjects

```
prices.BTC           → exact
prices.*             → prices.BTC, prices.ETH, prices.SOL (one token)
prices.>             → prices.BTC, prices.ETH.USD (any depth)

nc.Subscribe("prices.*", handler)   // single wildcard
nc.Subscribe("prices.>", handler)   // multi-level wildcard
```

## Pub/Sub Guarantees

| Guarantee | Core Pub/Sub | JetStream Pub/Sub |
|-----------|-------------|------------------|
| Message delivery | Best-effort | At-least-once |
| Offline consumer | ❌ | ✅ |
| Fan-out | ✅ | ✅ |
| Order guarantee | Per-subject | Per-stream |

## Subject Naming Best Practices

```
<domain>.<entity>.<event>.<qualifier>

examples:
  orders.created
  orders.us.cancelled
  payments.processed.success
  telemetry.sensor.temperature.zone-a
```

## Async vs Sync Subscribe

```go
// Async (callback — runs in background goroutine)
nc.Subscribe("orders.>", func(msg *nats.Msg) {
    process(msg)
})

// Sync (polling — useful in tests)
sub, _ := nc.SubscribeSync("orders.>")
msg, _ := sub.NextMsg(5 * time.Second)
```

---
*Part of the 100-Lesson NATS Series.*
