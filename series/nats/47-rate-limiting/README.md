# 47 — Rate Limiting

> **Type:** How-To  
> **Phase:** Patterns & Architecture

## Overview

Rate limiting in NATS prevents fast producers from overwhelming slow consumers. This lesson covers three complementary approaches: consumer-side rate limits, publisher-side throttling, and JetStream flow control.

## 1. Consumer Delivery Rate Limit

Limit how fast the NATS server delivers messages to a push consumer:

```go
js.Subscribe("sensor.readings",
    func(msg *nats.Msg) {
        processSensorData(msg)
        msg.Ack()
    },
    nats.Durable("metrics-aggregator"),
    nats.AckExplicit(),
    nats.RateLimit(1*1024*1024),   // max 1 MB/s delivery rate
)
```

## 2. MaxAckPending (Flow Control)

Limit in-flight (delivered but unacked) messages. Server pauses when limit is hit:

```go
js.Subscribe("orders.>", handler,
    nats.Durable("payment-svc"),
    nats.AckExplicit(),
    nats.MaxAckPending(50),     // server waits when 50 msgs are unacked
)
```

```
Messages delivered:  1, 2, 3 ... 50
Server PAUSES delivery
Consumer acks 1, 2, 3 → server unblocks and delivers 51, 52, 53
```

## 3. Publisher-Side Token Bucket

Implement token bucket rate limiting on the publisher:

```go
type TokenBucket struct {
    tokens float64
    max    float64
    refill float64  // tokens per second
    mu     sync.Mutex
    last   time.Time
}

func NewTokenBucket(rps float64) *TokenBucket {
    return &TokenBucket{tokens: rps, max: rps, refill: rps, last: time.Now()}
}

func (tb *TokenBucket) Allow() bool {
    tb.mu.Lock()
    defer tb.mu.Unlock()
    now := time.Now()
    tb.tokens = math.Min(tb.max, tb.tokens+tb.refill*now.Sub(tb.last).Seconds())
    tb.last = now
    if tb.tokens < 1 { return false }
    tb.tokens--
    return true
}

// Rate-limited publisher
bucket := NewTokenBucket(100)   // 100 msgs/sec
for _, order := range orders {
    for !bucket.Allow() {
        time.Sleep(5 * time.Millisecond)
    }
    js.Publish("orders.created", mustJSON(order))
}
```

## 4. Pull Consumer Batch Size Control

Use pull consumers to control exactly how many messages are processed at once:

```go
sub, _ := js.PullSubscribe("sensor.>", "aggregator")

for {
    // Fetch exactly 100 messages or wait up to 1s
    msgs, _ := sub.Fetch(100, nats.MaxWait(time.Second))

    processBatch(msgs)

    for _, msg := range msgs {
        msg.Ack()
    }

    time.Sleep(50 * time.Millisecond)   // 50ms between batches → ~2000 msgs/sec
}
```

## Monitoring Rate Limits

```bash
nats consumer info ORDERS payment-svc
# Rate Limit: 1.0 MB/s
# Max Ack Pending: 50
# Num Ack Pending: 12
```

---
*Part of the 100-Lesson NATS Series.*
