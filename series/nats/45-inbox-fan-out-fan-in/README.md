# 45 — Inbox Pattern (Fan-Out / Fan-In)

> **Type:** Tutorial  
> **Phase:** Patterns & Architecture

## What you're building

Implement fan-out (broadcast) and fan-in (aggregation) communication patterns with NATS, enabling parallel processing and result aggregation.

## Fan-Out

One publisher, many consumers — each receives every message:

```go
nc, _ := nats.Connect(nats.DefaultURL)

// Publishers
nc.Subscribe("orders.created", func(msg *nats.Msg) {
    // Payment service
    processPayment(msg)
})
nc.Subscribe("orders.created", func(msg *nats.Msg) {
    // Inventory service
    reserveInventory(msg)
})
nc.Subscribe("orders.created", func(msg *nats.Msg) {
    // Notification service
    sendEmail(msg)
})

// One publish → all 3 handlers fire
nc.Publish("orders.created", orderData)
```

With JetStream and durable consumers — each service has its own independent cursor:

```go
js.Subscribe("orders.created", paymentHandler,
    nats.Durable("payment-svc"), nats.AckExplicit())
js.Subscribe("orders.created", inventoryHandler,
    nats.Durable("inventory-svc"), nats.AckExplicit())
js.Subscribe("orders.created", notificationHandler,
    nats.Durable("notification-svc"), nats.AckExplicit())
```

## Fan-In (Scatter/Gather)

Request multiple services simultaneously and aggregate results:

```go
func gatherPrices(nc *nats.Conn, productID string) []Price {
    inbox := nats.NewInbox()
    
    // Subscribe to collect replies
    results := []Price{}
    sub, _ := nc.SubscribeSync(inbox)
    defer sub.Unsubscribe()

    // Scatter — broadcast request to all pricing providers
    req := []byte(`{"productId":"` + productID + `"}`)
    nc.PublishRequest("pricing.providers.>", inbox, req)

    // Gather — collect for 500ms
    deadline := time.Now().Add(500 * time.Millisecond)
    for time.Now().Before(deadline) {
        msg, err := sub.NextMsg(time.Until(deadline))
        if err != nil { break }
        var p Price
        json.Unmarshal(msg.Data, &p)
        results = append(results, p)
    }

    return results
}
```

## Inbox Pattern (Guaranteed Reply Routing)

NATS auto-creates per-request inbox subjects (`_INBOX.<random>`):

```go
// Each nc.Request() auto-generates a unique reply-to inbox:
reply, _ := nc.Request("users.get", req, 2*time.Second)
// Reply subject was: _INBOX.abcdefgh123456
// Only this caller receives the response
```

Manually create persistent inboxes for longer-lived aggregation:

```go
inbox := "_INBOX.audit-aggregator"  // well-known inbox
nc.Subscribe(inbox, func(msg *nats.Msg) {
    collectResult(msg)
})

// Broadcast to all workers with this inbox as reply-to
nc.PublishRequest("workers.status", inbox, []byte("ping"))
```

## Sequential Fan-Out with JetStream

```go
// Pipeline: each stage consumes and produces
js.Subscribe("raw.events", enricher, nats.Durable("enricher"))
// enricher publishes to → enriched.events

js.Subscribe("enriched.events", transformer, nats.Durable("transformer"))
// transformer publishes to → normalised.events

js.Subscribe("normalised.events", loader, nats.Durable("loader"))
// loader writes to data warehouse
```

---
*Part of the 100-Lesson NATS Series.*
