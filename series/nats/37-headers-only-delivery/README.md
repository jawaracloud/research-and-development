# 37 — Headers-Only Delivery

> **Type:** How-To  
> **Phase:** JetStream

## Overview

JetStream can deliver only the message headers to a consumer, without the payload body. This is useful for lightweight routing, filtering, and metadata inspection without transferring large payloads.

## Use Cases

- **Routing agents** that only need metadata to decide where to forward
- **Metrics collectors** that read stats from headers (e.g., latency, source service)
- **Preview consumers** that determine if full payload is needed
- **Event deduplication services** that only need the `Nats-Msg-Id`

## Consumer Configuration

```go
js.AddConsumer("ORDERS", &nats.ConsumerConfig{
    Durable:         "routing-agent",
    FilterSubject:   "orders.>",
    AckPolicy:       nats.AckExplicitPolicy,
    DeliverPolicy:   nats.DeliverAllPolicy,
    HeadersOnly:     true,    // ← do not deliver body
})
```

## Subscribe with headers-only

```go
sub, _ := js.Subscribe("orders.>",
    func(msg *nats.Msg) {
        // Body is empty — only headers are populated
        source := msg.Header.Get("X-Source-Service")
        schema := msg.Header.Get("Schema-Version")
        msgID  := msg.Header.Get(nats.MsgIdHdr)

        fmt.Printf("Source: %s, Schema: %s, ID: %s\n", source, schema, msgID)

        // If we need the full body, fetch it via sequence number:
        meta, _ := msg.Metadata()
        fullMsg, _ := js.GetMsg("ORDERS", meta.Sequence.Stream)
        process(fullMsg.Data)

        msg.Ack()
    },
    nats.Durable("routing-agent"),
    nats.AckExplicit(),
    nats.HeadersOnly(),   // shorthand option in nats.go
)
```

## Combined with Message Routing

```go
// Router: headers-only consumer routes to dedicated processors
sub, _ := js.Subscribe("events.>", func(msg *nats.Msg) {
    eventType := msg.Header.Get("X-Event-Type")
    meta, _ := msg.Metadata()

    switch eventType {
    case "OrderCreated":
        nc.Publish("internal.processors.order", []byte(fmt.Sprintf("%d", meta.Sequence.Stream)))
    case "PaymentFailed":
        nc.Publish("internal.processors.payment-retry", []byte(fmt.Sprintf("%d", meta.Sequence.Stream)))
    }

    msg.Ack()
}, nats.HeadersOnly(), nats.Durable("event-router"))
```

## Fetching Full Message by Sequence

```go
// After routing agent publishes the sequence number
nc.Subscribe("internal.processors.order", func(msg *nats.Msg) {
    seq, _ := strconv.ParseUint(string(msg.Data), 10, 64)
    fullMsg, err := js.GetMsg("ORDERS", seq)
    if err != nil { return }
    processOrder(fullMsg.Data)
})
```

---
*Part of the 100-Lesson NATS Series.*
