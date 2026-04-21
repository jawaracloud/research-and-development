# 22 — Streams

> **Type:** Tutorial  
> **Phase:** JetStream

## What you're building

Create and manage JetStream streams programmatically and via the CLI, understanding the full range of stream configuration options.

## Step 1: Create a stream (CLI)

```bash
nats stream add ORDERS \
  --subjects "orders.>" \
  --storage file \
  --retention limits \
  --max-msgs -1 \
  --max-bytes -1 \
  --max-age 7d \
  --replicas 1

nats stream info ORDERS
```

## Step 2: Create a stream (Go)

```go
package main

import (
    "log"
    "time"
    "github.com/nats-io/nats.go"
)

func main() {
    nc, _ := nats.Connect(nats.DefaultURL)
    defer nc.Drain()

    js, _ := nc.JetStream()

    // Create or update a stream
    cfg := &nats.StreamConfig{
        Name:        "ORDERS",
        Description: "All order lifecycle events",
        Subjects:    []string{"orders.>"},       // capture all orders.* subjects
        MaxAge:      7 * 24 * time.Hour,         // retain 7 days
        MaxBytes:    10 * 1024 * 1024 * 1024,    // 10 GB max
        MaxMsgs:     -1,                         // unlimited message count
        Storage:     nats.FileStorage,           // persist to disk
        Replicas:    1,                          // increase for HA
        Retention:   nats.LimitsPolicy,         // delete when limits hit
    }

    stream, err := js.AddStream(cfg)
    if err != nil {
        // Check if stream already exists with same config
        if err == nats.ErrStreamNameAlreadyInUse {
            stream, _ = js.UpdateStream(cfg)
        } else {
            log.Fatal(err)
        }
    }
    log.Printf("Stream %s created: %+v", stream.Config.Name, stream.State)
}
```

## Stream Configuration Reference

```go
&nats.StreamConfig{
    Name:         "ORDERS",               // required, unique name
    Description:  "Order events",
    Subjects:     []string{"orders.>"},   // subject filters
    
    // Retention
    Retention:    nats.LimitsPolicy,      // LimitsPolicy | InterestPolicy | WorkQueuePolicy
    MaxAge:       7 * 24 * time.Hour,     // max age of messages
    MaxBytes:     10 << 30,               // max total size
    MaxMsgs:      -1,                     // -1 = unlimited
    MaxMsgSize:   1 << 20,                // 1 MB per message
    
    // Storage
    Storage:      nats.FileStorage,       // FileStorage | MemoryStorage
    Replicas:     3,                      // for HA (requires cluster)
    
    // Discard
    Discard:      nats.DiscardOld,        // DiscardOld | DiscardNew
    
    // Deduplication
    Duplicates:   5 * time.Minute,        // dedup window
}
```

## Retention Policies

| Policy | Behaviour |
|--------|-----------|
| `LimitsPolicy` | Delete oldest when limits (age/bytes/count) are hit |
| `InterestPolicy` | Delete message once all consumers have acked it |
| `WorkQueuePolicy` | Delete message once one consumer has acked it |

## Managing Streams

```bash
nats stream ls                  # list all streams
nats stream info ORDERS         # detailed info
nats stream view ORDERS         # browse messages
nats stream purge ORDERS        # delete all messages, keep stream
nats stream rm ORDERS           # delete stream entirely
nats stream edit ORDERS         # update config
nats stream copy ORDERS ORDERS-BACKUP  # copy stream config
```

---
*Part of the 100-Lesson NATS Series.*
