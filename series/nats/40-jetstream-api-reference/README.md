# 40 — JetStream API Reference

> **Type:** Reference  
> **Phase:** JetStream

## Overview

Quick-reference for the most commonly used JetStream Go API methods, CLI commands, and management endpoints.

## Go API — nats.JetStreamContext

```go
js, err := nc.JetStream(
    nats.PublishAsyncMaxPending(256),  // async publish buffer
    nats.MaxWait(5*time.Second),       // default timeout
)
```

### Stream operations

```go
js.AddStream(cfg *nats.StreamConfig) (*nats.StreamInfo, error)
js.UpdateStream(cfg *nats.StreamConfig) (*nats.StreamInfo, error)
js.DeleteStream(name string) error
js.StreamInfo(name string) (*nats.StreamInfo, error)
js.StreamNames() <-chan string
js.PurgeStream(name string, opts ...nats.JSOpt) error
js.GetMsg(stream string, seq uint64) (*nats.RawStreamMsg, error)
js.DeleteMsg(stream string, seq uint64) error
```

### Consumer operations

```go
js.AddConsumer(stream string, cfg *nats.ConsumerConfig) (*nats.ConsumerInfo, error)
js.UpdateConsumer(stream string, cfg *nats.ConsumerConfig) (*nats.ConsumerInfo, error)
js.DeleteConsumer(stream, consumer string) error
js.ConsumerInfo(stream, consumer string) (*nats.ConsumerInfo, error)
js.ConsumerNames(stream string) <-chan string
```

### Publish

```go
js.Publish(subj string, data []byte, opts ...nats.PubOpt) (*nats.PubAck, error)
js.PublishMsg(msg *nats.Msg, opts ...nats.PubOpt) (*nats.PubAck, error)
js.PublishAsync(subj string, data []byte, opts ...nats.PubOpt) (nats.PubAckFuture, error)
js.PublishAsyncComplete() <-chan struct{}
```

### Subscribe

```go
js.Subscribe(subj string, cb nats.MsgHandler, opts ...nats.SubOpt) (*nats.Subscription, error)
js.SubscribeSync(subj string, opts ...nats.SubOpt) (*nats.Subscription, error)
js.QueueSubscribe(subj, queue string, cb nats.MsgHandler, opts ...nats.SubOpt) (*nats.Subscription, error)
js.PullSubscribe(subj, durable string, opts ...nats.SubOpt) (*nats.Subscription, error)
```

### Message Ack (on received msg)

```go
msg.Ack()
msg.Nak()
msg.NakWithDelay(d time.Duration)
msg.Term()
msg.InProgress()
meta, err := msg.Metadata()  // *nats.MsgMetadata
```

## NATS CLI — JetStream

```bash
# Streams
nats stream ls
nats stream add NAME [flags]
nats stream info NAME
nats stream edit NAME
nats stream rm NAME
nats stream purge NAME [--subject <filter>] [--keep N]
nats stream view NAME [--subject <filter>]
nats stream report

# Consumers
nats consumer ls STREAM
nats consumer add STREAM NAME [flags]
nats consumer info STREAM NAME
nats consumer next STREAM NAME [--count N]  # pull one/batch
nats consumer rm STREAM NAME

# KV
nats kv ls
nats kv add BUCKET [--history N]
nats kv put BUCKET KEY VALUE
nats kv get BUCKET KEY
nats kv watch BUCKET

# Object Store
nats object ls
nats object add BUCKET
nats object put BUCKET FILE
nats object get BUCKET OBJECT
```

## Key Configuration Types Reference

```go
nats.StreamConfig{...}    // stream definition
nats.ConsumerConfig{...}  // consumer definition
nats.PubAck{...}          // publish acknowledgement
nats.StreamInfo{...}      // stream metadata + state
nats.ConsumerInfo{...}    // consumer metadata + state
nats.MsgMetadata{...}     // per-message delivery metadata
```

---
*Part of the 100-Lesson NATS Series.*
