# 29 — Stream Limits & Discard Policies

> **Type:** How-To  
> **Phase:** JetStream

## Overview

Stream limits control the maximum size of a stream in messages, bytes, and age. Knowing when limits trigger — and what the server does when they're hit — prevents surprise data loss or publish failures.

## Available Limits

```go
&nats.StreamConfig{
    MaxMsgs:          1_000_000,         // max message count across whole stream
    MaxMsgsPerSubject: 100,              // max messages per unique subject
    MaxBytes:         10 * 1024 << 20,  // max total bytes (10 GB)
    MaxAge:           7 * 24 * time.Hour, // max age of any message
    MaxMsgSize:       1 * 1024 * 1024,  // max bytes for a single message (1 MB)
}
```

## Discard Policies

When a limit is hit, the server applies the `Discard` policy:

### DiscardOld (default)
Delete the oldest message to make room for the new one. The stream always accepts new messages.

```go
Discard: nats.DiscardOld
```

Behaviour:
```
Stream at MaxMsgs=1000 → seq 1001 arrives → seq 1 is deleted → seq 1001 stored
```

### DiscardNew
Reject the new message with an error. Oldest messages are preserved.

```go
Discard: nats.DiscardNew
```

```go
_, err := js.Publish("orders.created", data)
if err != nil {
    // Stream is full — handle the rejection
    var jerr nats.APIError
    if errors.As(err, &jerr) && jerr.ErrorCode == 10077 {
        log.Println("Stream full — applying backpressure")
        time.Sleep(5 * time.Second)
        // retry
    }
}
```

## Per-Subject Limits (Last-N Pattern)

Keep only the N most recent messages per subject (useful as a key-value store):

```go
&nats.StreamConfig{
    Name:              "CONFIG",
    Subjects:          []string{"config.>"},
    MaxMsgsPerSubject: 1,     // only keep the latest value per config key
    Retention:         nats.LimitsPolicy,
    Storage:           nats.FileStorage,
}
```

Now each config key only stores the latest value — like a KV store backed by a stream.

## Combining Limits

All limits are active simultaneously:

```go
&nats.StreamConfig{
    MaxMsgs:  10_000,                   // at most 10K messages
    MaxBytes: 1 * 1024 * 1024 * 1024,  // at most 1 GB
    MaxAge:   24 * time.Hour,           // at most 24 hours old
    // Whichever limit is hit first triggers discard
}
```

## Monitoring Limits

```bash
nats stream info ORDERS
# State:
#   Messages: 9,998
#   Bytes:    950 MB
#   First: Seq 1  (2026-03-01)
#   Last:  Seq 9,998 (2026-03-14)
# Limits:
#   Max Messages: 10,000
#   Max Bytes:    1.0 GB
#   Max Age:      24h
```

```promql
# Alert when stream is near limit
nats_js_stream_total_messages / nats_js_stream_max_messages > 0.9
```

---
*Part of the 100-Lesson NATS Series.*
