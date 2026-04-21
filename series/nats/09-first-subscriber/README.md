# 09 — First Subscriber

> **Type:** Tutorial  
> **Phase:** Foundations

## What you're building

A Go program that subscribes to a NATS subject, processes messages with structured handlers, and demonstrates both async and sync subscription patterns.

## Step 1: Async subscriber

`subscriber/main.go`:

```go
package main

import (
    "encoding/json"
    "fmt"
    "log"
    "os"
    "os/signal"
    "syscall"

    "github.com/nats-io/nats.go"
)

type HelloMessage struct {
    Seq int    `json:"seq"`
    Ts  string `json:"ts"`
    Msg string `json:"msg"`
}

func main() {
    nc, err := nats.Connect("nats://localhost:4222",
        nats.Name("lesson-09-subscriber"),
    )
    if err != nil {
        log.Fatalf("connect: %v", err)
    }
    defer nc.Drain()

    log.Println("Connected. Waiting for messages on hello.world...")

    // Async subscription — handler runs in a background goroutine
    sub, err := nc.Subscribe("hello.world", func(msg *nats.Msg) {
        var m HelloMessage
        if err := json.Unmarshal(msg.Data, &m); err != nil {
            log.Printf("parse error: %v", err)
            return
        }
        fmt.Printf("[Seq:%d] %s — received at %s\n", m.Seq, m.Msg, m.Ts)
    })
    if err != nil {
        log.Fatalf("subscribe: %v", err)
    }
    defer sub.Unsubscribe()

    // Wait for SIGINT/SIGTERM
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit
    log.Println("Shutting down gracefully...")
}
```

## Step 2: Run subscriber, then publisher

```bash
# Terminal 1
go run subscriber/main.go

# Terminal 2
go run ../08-first-publisher/publisher/main.go
```

## Step 3: Subscription statistics

```bash
# Check messages received
nats sub --count 10 hello.world   # stop after 10 messages
```

## Sync subscription (testing)

Useful in tests where you want to block until a message arrives:

```go
sub, _ := nc.SubscribeSync("hello.world")

// Block until message arrives (or timeout)
msg, err := sub.NextMsg(5 * time.Second)
if err != nil {
    log.Fatal("no message received:", err)
}
fmt.Println("Got:", string(msg.Data))
```

## Channel-based subscription

```go
ch := make(chan *nats.Msg, 64)
sub, _ := nc.ChanSubscribe("hello.world", ch)

for msg := range ch {
    fmt.Println(string(msg.Data))
}
```

## Auto-unsubscribe after N messages

```go
// Unsubscribe automatically after receiving 5 messages
sub, _ := nc.Subscribe("hello.world", handler)
sub.AutoUnsubscribe(5)
```

## Monitoring subscriber counts

```bash
# See subscriber count per subject
curl http://localhost:8222/subsz | jq '.subscriptions[] | select(.subject=="hello.world")'
```

---
*Part of the 100-Lesson NATS Series.*
