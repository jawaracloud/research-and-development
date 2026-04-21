# 12 — Connection Handling

> **Type:** How-To  
> **Phase:** Foundations

## Overview

Robust connection handling is critical in production. This lesson covers auto-reconnect, connection lifecycle callbacks, graceful shutdown, and connection pooling patterns.

## Connection Options

```go
nc, err := nats.Connect("nats://localhost:4222",
    // Identity
    nats.Name("my-service"),

    // Timeouts
    nats.Timeout(5 * time.Second),          // Initial connect timeout
    nats.PingInterval(20 * time.Second),    // Keepalive ping interval
    nats.MaxPingsOutstanding(5),            // Pings before disconnect

    // Reconnection
    nats.MaxReconnects(-1),                 // -1 = infinite
    nats.ReconnectWait(2 * time.Second),    // Wait between reconnects
    nats.ReconnectJitter(500*time.Millisecond, 2*time.Second), // Jitter

    // Buffering during reconnect
    nats.ReconnectBufSize(8 * 1024 * 1024), // 8 MB buffer

    // Custom server list (for cluster)
    // nats.Connect("nats://nats-1:4222,nats://nats-2:4222,nats://nats-3:4222")
)
```

## Lifecycle Callbacks

```go
nc, _ := nats.Connect("nats://localhost:4222",
    nats.ConnectHandler(func(nc *nats.Conn) {
        log.Printf("Connected to %s", nc.ConnectedUrl())
    }),
    nats.DisconnectErrHandler(func(nc *nats.Conn, err error) {
        log.Printf("Disconnected: %v", err)
        // nc will attempt to reconnect automatically
    }),
    nats.ReconnectHandler(func(nc *nats.Conn) {
        log.Printf("Reconnected to %s", nc.ConnectedUrl())
    }),
    nats.ClosedHandler(func(nc *nats.Conn) {
        // Permanent close — all reconnect attempts exhausted
        log.Println("Connection permanently closed")
    }),
    nats.ErrorHandler(func(nc *nats.Conn, sub *nats.Subscription, err error) {
        log.Printf("Async error on %s: %v", sub.Subject, err)
    }),
)
```

## Graceful Shutdown

```go
func main() {
    nc, _ := nats.Connect(nats.DefaultURL)

    // Register subscriptions
    nc.Subscribe("orders.>", handler)

    // Wait for shutdown signal
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    // Drain — waits for in-flight messages to be processed
    // then closes connection gracefully
    log.Println("Draining connection...")
    nc.Drain()
    log.Println("Goodbye!")
}
```

`nc.Drain()` vs `nc.Close()`:
- `Drain()` — processes all in-flight messages, unsubscribes, closes. **Always prefer Drain.**
- `Close()` — immediate close, drops in-flight messages.

## Multi-server cluster connection

```go
// Provide all cluster nodes — client picks one and fails over automatically
nc, _ := nats.Connect(
    "nats://nats-1:4222,nats://nats-2:4222,nats://nats-3:4222",
    nats.MaxReconnects(-1),
)
```

## Connection Status

```go
switch nc.Status() {
case nats.CONNECTED:
    fmt.Println("connected")
case nats.RECONNECTING:
    fmt.Println("reconnecting...")
case nats.CONNECTING:
    fmt.Println("connecting...")
case nats.CLOSED:
    fmt.Println("closed")
}
```

---
*Part of the 100-Lesson NATS Series.*
