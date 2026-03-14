# 26 — Replay Policies

> **Type:** How-To  
> **Phase:** JetStream

## Overview

JetStream replay policies control the **rate** at which stored messages are delivered to a consumer — either as fast as possible, or at the original publication rate.

## Replay Policy Options

### ReplayInstant (default)
Deliver messages as fast as the consumer can accept them, regardless of the original publish rate.

```go
js.Subscribe("orders.>", handler,
    nats.Durable("fast-consumer"),
    nats.DeliverAll(),
    nats.ReplayInstant(),    // deliver 1M backlogged msgs ASAP
)
```

**Use when:** Backfill processing, analytics, bulk replay.

### ReplayOriginal
Deliver messages at the same rate they were originally published — useful for replaying audit or simulation scenarios.

```go
js.Subscribe("sensor.readings", handler,
    nats.Durable("simulation"),
    nats.DeliverAll(),
    nats.ReplayOriginal(),   // replays at original sensor publish rate
)
```

**Use when:** Time-series simulation, testing rate-sensitive logic.

## Deliver Policies Combined with Replay

```go
// Replay everything from the beginning at original rate
js.Subscribe("sensor.>", handler,
    nats.DeliverAll(),
    nats.ReplayOriginal(),
)

// Only deliver new messages (no replay)
js.Subscribe("sensor.>", handler,
    nats.DeliverNew(),
    nats.ReplayInstant(),
)

// Start from a specific sequence number
js.Subscribe("sensor.>", handler,
    nats.StartSequence(1000),
    nats.ReplayInstant(),
)

// Start from a specific time
js.Subscribe("sensor.>", handler,
    nats.StartTime(time.Now().Add(-24*time.Hour)),
    nats.ReplayInstant(),
)
```

## Scenario: Catching Up After Downtime

```go
// Service was offline for 2 hours
// Needs to catch up on all missed messages ASAP

sub, _ := js.Subscribe("orders.created",
    func(msg *nats.Msg) {
        processOrder(msg)
        msg.Ack()
    },
    nats.Durable("payment-svc"),   // picks up from last acked position
    nats.AckExplicit(),
    nats.ReplayInstant(),          // catch up fast
)
```

With a **durable** consumer, the server remembers the cursor. The consumer automatically resumes from where it left off — no `DeliverAll` needed.

## Scenario: Time-Series Data Replay

```go
// Replay 7 days of sensor data at original rate for ML training

start := time.Now().Add(-7 * 24 * time.Hour)
sub, _ := js.Subscribe("telemetry.>",
    func(msg *nats.Msg) {
        feedToMLPipeline(msg)
        msg.Ack()
    },
    nats.StartTime(start),
    nats.ReplayOriginal(),   // respects original 1Hz sampling rate
    nats.AckExplicit(),
)
```

---
*Part of the 100-Lesson NATS Series.*
