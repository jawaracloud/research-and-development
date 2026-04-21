# 19 — Drain & Graceful Shutdown

> **Type:** How-To  
> **Phase:** Foundations

## Overview

This lesson covers the correct shutdown sequence for NATS clients and JetStream consumers — ensuring all in-flight messages are processed before the process exits.

## The Problem: Abrupt Shutdown

```
SIGTERM received
os.Exit(0)          ← immediate exit
                    ← in-flight messages lost
                    ← JetStream consumer cursor not advanced
                    ← messages will be redelivered to another instance
```

## The Solution: Drain

`nc.Drain()` performs a graceful shutdown sequence:

1. Unsubscribes all subscriptions (no new messages accepted from server)
2. Processes all messages already in local buffers
3. Waits for all async handlers to complete
4. Flushes any pending published messages
5. Closes the connection

```go
func main() {
    nc, _ := nats.Connect(nats.DefaultURL)

    nc.Subscribe("orders.>", func(msg *nats.Msg) {
        time.Sleep(100 * time.Millisecond)   // simulate processing
        fmt.Printf("Processed: %s\n", msg.Subject)
    })

    // Wait for OS signal
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    log.Println("Draining — processing remaining messages...")
    // Drain with custom timeout
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    doneCh := nc.DrainChannel()  // returns channel that closes when drain completes
    select {
    case <-doneCh:
        log.Println("Drain complete")
    case <-ctx.Done():
        log.Println("Drain timeout — forcing close")
        nc.Close()
    }
}
```

## JetStream Consumer Drain

For JetStream subscriptions, drain ensures all acks are sent before shutdown:

```go
js, _ := nc.JetStream()

sub, _ := js.Subscribe("orders.>", func(msg *nats.Msg) {
    processOrder(msg)
    msg.Ack()   // ack is queued
}, nats.Durable("order-processor"))

// On shutdown:
sub.Drain()  // drain the subscription first
nc.Drain()   // then drain the connection (flushes acks)
```

## Kubernetes Pod Shutdown

In Kubernetes, `SIGTERM` is sent before `SIGKILL` (default 30s grace period):

```yaml
spec:
  containers:
    - name: order-processor
      lifecycle:
        preStop:
          exec:
            command: ["/bin/sh", "-c", "sleep 5"]  # give time for SIGTERM handling
  terminationGracePeriodSeconds: 45   # allow 45s total
```

## Complete Shutdown Pattern

```go
func run(nc *nats.Conn) error {
    subs := []*nats.Subscription{}

    sub, _ := nc.Subscribe("orders.>", handler)
    subs = append(subs, sub)

    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    // Drain each subscription
    for _, s := range subs {
        s.Drain()
    }

    // Drain connection (flushes and closes)
    return nc.Drain()
}
```

---
*Part of the 100-Lesson NATS Series.*
