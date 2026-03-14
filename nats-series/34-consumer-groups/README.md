# 34 — Consumer Groups (Queue Groups in JetStream)

> **Type:** Tutorial  
> **Phase:** JetStream

## What you're building

Scale JetStream consumers horizontally by sharing a single durable consumer across multiple worker instances — only one worker receives each message.

## How JetStream Queue Groups Work

In core NATS, queue groups work via `QueueSubscribe`. In JetStream, the equivalent is multiple workers binding to the **same durable consumer**, combined with a pull model or push with `InactiveThreshold`.

## Push Consumer Queue Group

```go
// worker/main.go — run multiple instances
func main() {
    workerID := os.Getenv("WORKER_ID")
    nc, _ := nats.Connect(nats.DefaultURL)
    defer nc.Drain()

    js, _ := nc.JetStream()

    // All workers use the same durable name + queue group
    sub, _ := js.QueueSubscribe("orders.>", "order-workers",
        func(msg *nats.Msg) {
            meta, _ := msg.Metadata()
            fmt.Printf("[Worker-%s] Seq:%d %s\n",
                workerID, meta.Sequence.Stream, msg.Data)
            time.Sleep(100 * time.Millisecond)  // simulate work
            msg.Ack()
        },
        nats.Durable("order-workers"),
        nats.AckExplicit(),
        nats.BindStream("ORDERS"),
    )
    defer sub.Drain()
    select {}
}
```

Run 3 workers and publish 30 messages:
```bash
WORKER_ID=1 go run worker/main.go &
WORKER_ID=2 go run worker/main.go &
WORKER_ID=3 go run worker/main.go &
nats pub orders.created --count 30 '{"id":"{{.Count}}"}'
# Each worker processes ~10 messages
```

## Pull Consumer Queue Group (preferred for high-throughput)

All workers share a durable **pull** consumer. Each worker fetches its own batch:

```go
sub, _ := js.PullSubscribe("orders.>", "order-pull-workers",
    nats.BindStream("ORDERS"),
)

// Each worker independently fetches and processes batches
for {
    msgs, err := sub.Fetch(20, nats.MaxWait(5*time.Second))
    if err != nil { continue }
    for _, msg := range msgs {
        processOrder(msg)
        msg.Ack()
    }
}
```

## Scaling Rules

```
Queue Group Add:
  Worker-4 starts → immediately begins receiving 1/4 of messages
  No config change needed

Queue Group Remove:
  Worker-1 exits → server drains its in-flight messages
  Other workers pick up → no message loss
```

## Monitoring Queue Group Progress

```bash
nats consumer info ORDERS order-workers
# Num Pending: 1,245  ← messages waiting to be consumed
# Num Ack Pending: 20  ← messages in-flight (being processed)
# Num Redelivered: 3   ← messages reenqueued due to timeout
```

---
*Part of the 100-Lesson NATS Series.*
