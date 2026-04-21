# 46 — Dead Letter Queue

> **Type:** How-To  
> **Phase:** Patterns & Architecture

## Overview

A Dead Letter Queue (DLQ) captures messages that have exhausted all delivery attempts — preventing poison messages from blocking queue processing while preserving them for investigation.

## How JetStream DLQ Works

Configure `MaxDeliver` on the consumer. After that many attempts, publish to a DLQ subject:

```go
js.Subscribe("orders.created",
    func(msg *nats.Msg) {
        meta, _ := msg.Metadata()

        if err := processOrder(msg); err != nil {
            // Check delivery count
            if meta.NumDelivered >= 5 {
                // Exhausted — route to DLQ
                dlqMsg := &nats.Msg{
                    Subject: "dlq.orders.created",
                    Data:    msg.Data,
                    Header:  msg.Header.Clone(),
                }
                dlqMsg.Header.Set("X-DLQ-Reason", err.Error())
                dlqMsg.Header.Set("X-DLQ-Source-Subject", msg.Subject)
                dlqMsg.Header.Set("X-DLQ-Attempts", strconv.Itoa(int(meta.NumDelivered)))
                js.PublishMsg(dlqMsg)

                msg.Term()   // stop infinite redelivery
                return
            }
            msg.Nak()
            return
        }
        msg.Ack()
    },
    nats.Durable("order-processor"),
    nats.AckExplicit(),
    nats.AckWait(30*time.Second),
    nats.MaxDeliver(5),
)
```

## DLQ Stream Setup

```go
// Create a stream to persist DLQ messages
js.AddStream(&nats.StreamConfig{
    Name:     "DLQ",
    Subjects: []string{"dlq.>"},
    MaxAge:   30 * 24 * time.Hour,  // 30-day retention
    Storage:  nats.FileStorage,
})
```

## DLQ Inspector

A monitoring service that alerts and allows manual reprocessing:

```go
js.Subscribe("dlq.>",
    func(msg *nats.Msg) {
        reason     := msg.Header.Get("X-DLQ-Reason")
        srcSubject := msg.Header.Get("X-DLQ-Source-Subject")
        attempts   := msg.Header.Get("X-DLQ-Attempts")

        // Alert
        sendSlackAlert(fmt.Sprintf(
            "⚠️ DLQ: subject=%s, attempts=%s, reason=%s",
            srcSubject, attempts, reason))

        // Persist for later
        logToDB(msg)
        msg.Ack()
    },
    nats.Durable("dlq-inspector"),
    nats.AckExplicit(),
)
```

## Manual Replay from DLQ

```bash
# View DLQ messages
nats stream view DLQ --subject "dlq.orders.created"

# Replay a specific DLQ message back to the original subject
nats stream get DLQ 42 | nats pub orders.created  # re-inject for reprocessing

# Bulk replay
nats consumer next DLQ dlq-replayer --count 100
```

## JetStream Advisory DLQ

NATS also publishes built-in advisories when `MaxDeliver` is exceeded:

```
Subject: $JS.EVENT.ADVISORY.CONSUMER.MAX_DELIVERIES.ORDERS.order-processor
```

```go
nc.Subscribe("$JS.EVENT.ADVISORY.CONSUMER.MAX_DELIVERIES.>", func(msg *nats.Msg) {
    log.Printf("Max deliveries exceeded: %s", msg.Data)
})
```

---
*Part of the 100-Lesson NATS Series.*
