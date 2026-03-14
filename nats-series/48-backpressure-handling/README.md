# 48 — Backpressure Handling

> **Type:** How-To  
> **Phase:** Patterns & Architecture

## Overview

Backpressure prevents system overload by signalling producers to slow down when consumers can't keep up. Properly implemented, it prevents message loss, OOM crashes, and cascading failures.

## The Problem

```
Producer: 10,000 msgs/sec
Consumer: 1,000 msgs/sec

Without backpressure:
  NATS buffer fills → slow consumer warning → messages dropped ❌

With backpressure:
  Consumer signals capacity → producer throttles to 1,000 msgs/sec ✅
```

## Approach 1: MaxAckPending (built-in JetStream backpressure)

```go
// Server pauses delivery after 100 unacked messages
js.Subscribe("events.>", handler,
    nats.Durable("processor"),
    nats.AckExplicit(),
    nats.MaxAckPending(100),   // natural backpressure
)
```

When processor slows down, ack pending grows → server pauses → automatic backpressure.

## Approach 2: Semaphore-Based Consumer

```go
const maxConcurrent = 50
sem := make(chan struct{}, maxConcurrent)

js.Subscribe("tasks.>",
    func(msg *nats.Msg) {
        sem <- struct{}{}   // acquire slot (blocks if 50 in-flight)
        go func() {
            defer func() { <-sem }()   // release slot when done
            processTask(msg)
            msg.Ack()
        }()
    },
    nats.Durable("task-processor"),
    nats.AckExplicit(),
    nats.MaxAckPending(maxConcurrent),
)
```

## Approach 3: Pull with Adaptive Batch Size

Dynamically adjust batch size based on processing latency:

```go
sub, _ := js.PullSubscribe("events.>", "adaptive-consumer")

batchSize := 10
for {
    start := time.Now()
    msgs, _ := sub.Fetch(batchSize, nats.MaxWait(time.Second))

    for _, msg := range msgs {
        process(msg)
        msg.Ack()
    }

    latency := time.Since(start)

    // Adapt batch size based on processing speed
    switch {
    case latency < 100*time.Millisecond:
        batchSize = min(batchSize*2, 500)   // speed up
    case latency > 500*time.Millisecond:
        batchSize = max(batchSize/2, 1)     // slow down
    }
}
```

## Approach 4: Publisher-Side Check

Have the publisher check consumer lag before publishing:

```go
func isConsumerHealthy(js nats.JetStreamContext, stream, consumer string) bool {
    info, err := js.ConsumerInfo(stream, consumer)
    if err != nil { return false }
    return info.NumPending < 10_000   // back off if > 10K pending
}

for _, event := range events {
    if !isConsumerHealthy(js, "ORDERS", "payment-svc") {
        time.Sleep(time.Second)
        continue
    }
    js.Publish("orders.created", mustJSON(event))
}
```

## Monitoring

```promql
# Alert when consumer lag exceeds threshold
nats_js_consumer_num_pending > 50000
```

---
*Part of the 100-Lesson NATS Series.*
