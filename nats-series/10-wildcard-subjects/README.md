# 10 — Wildcard Subjects

> **Type:** Tutorial  
> **Phase:** Foundations

## What you're building

Use NATS subject wildcards to implement flexible subscription patterns — consuming messages from dynamic hierarchies without knowing every subject name in advance.

## NATS Wildcard Tokens

| Wildcard | Matches | Example |
|----------|---------|---------|
| `*` (single) | One token at the position | `orders.*` matches `orders.created` but NOT `orders.v1.created` |
| `>` (multi) | One or more tokens | `orders.>` matches `orders.created`, `orders.v1.created`, `orders.us.v2.created` |

## Step 1: Subject hierarchy example

```
sensors.zone-a.temperature
sensors.zone-a.humidity
sensors.zone-b.temperature
sensors.zone-b.pressure
```

## Step 2: Wildcard subscriptions

```go
package main

import (
    "fmt"
    "log"
    "github.com/nats-io/nats.go"
)

func main() {
    nc, _ := nats.Connect(nats.DefaultURL)
    defer nc.Drain()

    // Single wildcard — only matches temperature in any zone
    nc.Subscribe("sensors.*.temperature", func(msg *nats.Msg) {
        fmt.Printf("[Temp Monitor] %s → %s\n", msg.Subject, msg.Data)
    })

    // Multi wildcard — matches ALL sensor readings
    nc.Subscribe("sensors.>", func(msg *nats.Msg) {
        fmt.Printf("[All Sensors] %s → %s\n", msg.Subject, msg.Data)
    })

    // Exact — only zone-a
    nc.Subscribe("sensors.zone-a.>", func(msg *nats.Msg) {
        fmt.Printf("[Zone-A] %s → %s\n", msg.Subject, msg.Data)
    })

    // Publisher
    subjects := []string{
        "sensors.zone-a.temperature",
        "sensors.zone-a.humidity",
        "sensors.zone-b.temperature",
        "sensors.zone-b.pressure",
    }
    for _, s := range subjects {
        nc.Publish(s, []byte(`{"value":42}`))
    }

    nc.Flush()
    // brief sleep to allow async callbacks to fire
    select {}
}
```

## Step 3: Run and observe

```bash
go run main.go
# [All Sensors] sensors.zone-a.temperature → {"value":42}
# [Temp Monitor] sensors.zone-a.temperature → {"value":42}
# [Zone-A] sensors.zone-a.temperature → {"value":42}
# [All Sensors] sensors.zone-a.humidity → {"value":42}
# [Zone-A] sensors.zone-a.humidity → {"value":42}
# (zone-b messages only match [All Sensors] and [Temp Monitor])
```

## Extracting subject tokens

```go
nc.Subscribe("sensors.*.>", func(msg *nats.Msg) {
    tokens := strings.Split(msg.Subject, ".")
    // tokens[0] = "sensors"
    // tokens[1] = "zone-a" (matched by *)
    // tokens[2] = "temperature" (matched by >)
    zone := tokens[1]
    metric := strings.Join(tokens[2:], ".")
    fmt.Printf("Zone: %s, Metric: %s\n", zone, metric)
})
```

## Subject naming anti-patterns

```
❌ user-created      (hyphens limit wildcard routing)
❌ USER.CREATED      (inconsistent case)
✅ users.created
✅ orders.v2.created
✅ telemetry.zone-a.cpu.usage
```

---
*Part of the 100-Lesson NATS Series.*
