# 24 — Consumer Configuration

> **Type:** How-To  
> **Phase:** JetStream

## Overview

This lesson covers every significant JetStream consumer configuration option — how each setting affects delivery behaviour, reliability, and performance.

## Full Consumer Config (Go)

```go
js, _ := nc.JetStream()

_, err := js.AddConsumer("ORDERS", &nats.ConsumerConfig{
    // Identity
    Name:        "payment-processor",
    Durable:     "payment-processor",   // persist consumer state on server
    Description: "Processes order payments",

    // Subject filtering
    FilterSubject: "orders.created",    // only deliver orders.created

    // Delivery
    DeliverPolicy: nats.DeliverAllPolicy,     // replay from beginning
    DeliverSubject: "",                        // empty = pull consumer
    AckPolicy:     nats.AckExplicitPolicy,    // must ack each msg

    // Timing
    AckWait:       30 * time.Second,   // redeliver if not acked within 30s
    MaxDeliver:    5,                  // max delivery attempts (then DLQ)

    // Throttle
    MaxAckPending: 100,                // max in-flight unacked messages
    MaxRequestBatch: 50,               // max batch size for pull

    // Replay
    ReplayPolicy: nats.ReplayInstantPolicy,  // deliver ASAP (not at original rate)

    // Idle heartbeat (push only)
    // Heartbeat: 5 * time.Second,

    // Sampling for observability
    SampleFrequency: "100%",           // emit advisory on every ack
})
```

## Key Options Explained

### `AckWait`
If a message is not acked within `AckWait`, JetStream redelivers it:
```
AckWait: 30s
→ message delivered at T=0
→ not acked by T=30s → redelivered
→ not acked by T=60s → redelivered again (MaxDeliver check)
```

### `MaxDeliver`
Maximum total delivery attempts. After reaching this, the message is considered "dead" and the consumer moves past it (or routes to a dead-letter queue):
```
MaxDeliver: 5
→ attempts 1,2,3,4,5 all nacked/timed out
→ message is skipped / advisory emitted
```

### `FilterSubject`
Narrow which messages from the stream this consumer cares about:
```go
FilterSubject: "orders.created"  // only new orders, not cancellations
```

### `DeliverPolicy` options

```go
nats.DeliverAllPolicy            // all messages from start
nats.DeliverNewPolicy            // only messages after consumer creation
nats.DeliverLastPolicy           // only the most recent message
nats.DeliverLastPerSubjectPolicy // last message per distinct subject
nats.DeliverByStartSequencePolicy// start at specific seq
nats.DeliverByStartTimePolicy    // start at specific time
```

## CLI consumer management

```bash
nats consumer add ORDERS payment-processor --pull --deliver all --ack explicit --wait 30s --max-pending 100
nats consumer info ORDERS payment-processor
nats consumer ls ORDERS
nats consumer rm ORDERS payment-processor
```

---
*Part of the 100-Lesson NATS Series.*
