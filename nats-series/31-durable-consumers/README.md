# 31 — Durable Consumers

> **Type:** Tutorial  
> **Phase:** JetStream

## What you're building

Durable consumers remember their position in a stream across restarts — the backbone of reliable at-least-once processing.

## What Makes a Consumer "Durable"

A durable consumer has:
1. A **name** persisted on the NATS server
2. A **cursor** (last acked sequence number) stored server-side
3. Automatic **resume from last position** on reconnect

```
Time 0:  Consumer "payment-svc" created, queue at seq 1
Time 5m: Processed seq 1–100, cursor at 100
Time 6m: Service restarts
Time 6m: Consumer "payment-svc" reconnects → server resumes at seq 101
```

## Go Implementation

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

    js, _ := nc.JetStream()

    // Pre-create the stream (idempotent)
    js.AddStream(&nats.StreamConfig{
        Name:    "ORDERS",
        Subjects: []string{"orders.>"},
    })

    // Durable consumer — server remembers position
    sub, err := js.Subscribe("orders.>",
        func(msg *nats.Msg) {
            meta, _ := msg.Metadata()
            fmt.Printf("[Seq:%d] %s: %s\n",
                meta.Sequence.Stream, msg.Subject, msg.Data)
            msg.Ack()
        },
        nats.Durable("payment-svc"),    // ← this makes it durable
        nats.AckExplicit(),
        nats.DeliverAll(),
    )
    if err != nil {
        log.Fatal(err)
    }
    defer sub.Drain()

    select {}
}
```

Run, publish some messages, stop the service, publish more, restart — the consumer picks up from where it left off.

## Verifying Durability

```bash
# Stop consumer, publish messages, check pending
nats consumer info ORDERS payment-svc
# Num Pending: 47    ← 47 messages waiting for this consumer
# Num Ack Pending: 0
# Num Redelivered: 0
# Last Delivered: Seq 53 at 2026-03-14T07:00:00

# Start consumer → it processes the 47 pending messages
```

## Multiple Instances of a Durable Consumer

Multiple processes using the same durable name → load-balanced delivery (pull consumers):

```bash
# Start 3 payment processors, all share "payment-svc" durable
INSTANCE=1 go run main.go &
INSTANCE=2 go run main.go &
INSTANCE=3 go run main.go &
```

Each message goes to exactly one instance (queue group semantics via JetStream).

## Consumer vs Subscription Lifetime

```go
// Create consumer without subscribing (server-side only)
js.AddConsumer("ORDERS", &nats.ConsumerConfig{
    Durable:     "payment-svc",
    AckPolicy:   nats.AckExplicitPolicy,
    FilterSubject: "orders.created",
})

// Later, bind a subscription to the existing consumer
sub, _ := js.PullSubscribe("orders.created",
    "payment-svc",
    nats.Bind("ORDERS", "payment-svc"),
)
```

---
*Part of the 100-Lesson NATS Series.*
