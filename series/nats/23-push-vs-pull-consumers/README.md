# 23 — Consumers: Push vs Pull

> **Type:** Tutorial  
> **Phase:** JetStream

## What you're building

Implement and compare push-based and pull-based JetStream consumers, understanding the tradeoffs.

## Push Consumer

The server **pushes** messages to the subscriber as fast as they arrive. Simpler to write, but can overwhelm a slow consumer.

```go
js, _ := nc.JetStream()

// Push subscription — server delivers to this client
sub, err := js.Subscribe("orders.>", func(msg *nats.Msg) {
    fmt.Printf("[Push] %s: %s\n", msg.Subject, msg.Data)
    msg.Ack()
},
    nats.Durable("payment-push-consumer"),
    nats.AckExplicit(),
    nats.DeliverAll(),           // start from beginning of stream
    nats.MaxAckPending(50),      // flow control: server pauses after 50 unacked
)
defer sub.Drain()
```

## Pull Consumer

The client **explicitly fetches** messages in controlled batches. Provides precise flow control, ideal for high-throughput or slow processing.

```go
js, _ := nc.JetStream()

// Create durable pull consumer
sub, _ := js.PullSubscribe("orders.>",
    "payment-pull-consumer",
    nats.BindStream("ORDERS"),
)

// Fetch in batches with timeout
for {
    msgs, err := sub.Fetch(10, nats.MaxWait(5*time.Second))
    if err != nil {
        if errors.Is(err, nats.ErrTimeout) {
            continue   // no messages — try again
        }
        log.Printf("fetch error: %v", err)
        break
    }

    for _, msg := range msgs {
        fmt.Printf("[Pull] %s: %s\n", msg.Subject, msg.Data)
        msg.Ack()
    }
}
```

## Comparison

| | Push | Pull |
|-|------|------|
| **Flow Control** | `MaxAckPending` | Explicit batch size |
| **Backpressure** | Server-managed | Client-managed |
| **Scaling** | One push consumer per subject | Many pullers share one consumer |
| **Latency** | Lower (server pushes instantly) | Slightly higher (polling) |
| **Complexity** | Simpler | More control |
| **Best for** | Single consumer, event-driven | Worker pools, high-throughput |

## Pull with FetchNoWait

```go
// Non-blocking fetch — returns immediately with available messages
msgs, _ := sub.FetchNoWait(100)
```

## Push consumer with rate limiting

```go
js.Subscribe("orders.>", handler,
    nats.Durable("slow-consumer"),
    nats.RateLimit(1024*1024),     // max 1 MB/s delivery rate
    nats.AckExplicit(),
)
```

---
*Part of the 100-Lesson NATS Series.*
