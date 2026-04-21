# 08 — First Publisher

> **Type:** Tutorial  
> **Phase:** Foundations

## What you're building

A Go program that publishes messages to a NATS subject — your first hands-on interaction with the NATS server.

**Hypothesis**: A message published to `hello.world` is received by all subscribers on that subject within 1 ms.

## Step 1: Write the publisher

`publisher/main.go`:

```go
package main

import (
    "fmt"
    "log"
    "time"

    "github.com/nats-io/nats.go"
)

func main() {
    // Connect to NATS
    nc, err := nats.Connect("nats://localhost:4222",
        nats.Name("lesson-08-publisher"),
        nats.Timeout(5*time.Second),
        nats.MaxReconnects(5),
        nats.ReconnectWait(2*time.Second),
    )
    if err != nil {
        log.Fatalf("connect: %v", err)
    }
    defer nc.Drain()

    log.Println("Connected to NATS:", nc.ConnectedUrl())

    // Publish 10 messages
    for i := 1; i <= 10; i++ {
        msg := fmt.Sprintf(`{"seq":%d,"ts":"%s","msg":"hello from lesson 08"}`,
            i, time.Now().Format(time.RFC3339))

        err := nc.Publish("hello.world", []byte(msg))
        if err != nil {
            log.Printf("publish error: %v", err)
            continue
        }
        log.Printf("[%d] Published: %s", i, msg)
        time.Sleep(500 * time.Millisecond)
    }

    // Flush ensures all messages are sent to the server
    nc.Flush()
    log.Println("Done. All messages published.")
}
```

## Step 2: Start a subscriber (NATS CLI)

In a separate terminal before running the publisher:

```bash
nats sub hello.world
```

## Step 3: Run the publisher

```bash
go run publisher/main.go
```

## Expected output

**Publisher terminal:**
```
Connected to NATS: nats://localhost:4222
[1] Published: {"seq":1,"ts":"2026-03-14T07:00:00Z","msg":"hello from lesson 08"}
[2] Published: {"seq":2,...}
...
Done. All messages published.
```

**Subscriber terminal (nats sub):**
```
[#1] Received on "hello.world"
{"seq":1,"ts":"2026-03-14T07:00:00Z","msg":"hello from lesson 08"}
```

## Key Connection Options

| Option | Purpose |
|--------|---------|
| `nats.Name("...")` | Sets client name visible in monitoring |
| `nats.Timeout(5s)` | Connection timeout |
| `nats.MaxReconnects(5)` | Auto-reconnect attempts |
| `nats.ReconnectWait(2s)` | Delay between reconnects |

## Step 4: Verify via NATS monitoring

```bash
# See connection in monitoring
curl http://localhost:8222/connz | jq '.connections[] | .name'
# "lesson-08-publisher"
```

---
*Part of the 100-Lesson NATS Series.*
