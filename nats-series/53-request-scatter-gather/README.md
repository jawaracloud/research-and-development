# 53 — Request Scatter/Gather

> **Type:** Tutorial  
> **Phase:** Patterns & Architecture

## What you're building

Implement the scatter/gather pattern: broadcast a single request to multiple services in parallel, collect all responses within a timeout, and process the aggregated results.

## Use Cases

- Price aggregation across multiple vendors
- Health checks across all service instances
- Parallel query with fastest-response wins
- Voting / quorum reads

## Basic Scatter/Gather

```go
func gatherAll(nc *nats.Conn, subject string, req []byte, timeout time.Duration) [][]byte {
    inbox := nats.NewInbox()

    sub, _ := nc.SubscribeSync(inbox)
    defer sub.Unsubscribe()

    // Scatter — broadcast request to all subscribers
    nc.PublishRequest(subject, inbox, req)

    // Gather — collect until timeout
    results := [][]byte{}
    deadline := time.Now().Add(timeout)
    for time.Now().Before(deadline) {
        msg, err := sub.NextMsg(time.Until(deadline))
        if err != nil { break }
        results = append(results, msg.Data)
    }
    return results
}

// Example: Get price from all pricing providers
prices := gatherAll(nc, "pricing.get", mustJSON(map[string]string{"sku": "A123"}), 300*time.Millisecond)
fmt.Printf("Got %d price quotes\n", len(prices))
```

## Typed Scatter/Gather with Cancellation

```go
type PriceQuote struct {
    Provider string  `json:"provider"`
    Price    float64 `json:"price"`
}

func gatherPrices(nc *nats.Conn, sku string) []PriceQuote {
    inbox := nats.NewInbox()
    ch := make(chan *nats.Msg, 20)

    sub, _ := nc.ChanSubscribe(inbox, ch)
    defer sub.Unsubscribe()

    nc.PublishRequest("pricing.providers", inbox,
        mustJSON(map[string]string{"sku": sku}))

    ctx, cancel := context.WithTimeout(context.Background(), 400*time.Millisecond)
    defer cancel()

    var quotes []PriceQuote
    for {
        select {
        case msg := <-ch:
            var q PriceQuote
            json.Unmarshal(msg.Data, &q)
            quotes = append(quotes, q)
        case <-ctx.Done():
            return quotes
        }
    }
}
```

## Best-Of-N (Fastest Response Wins)

```go
func fastestResponse(nc *nats.Conn, subject string, req []byte, n int) []byte {
    inbox := nats.NewInbox()
    sub, _ := nc.SubscribeSync(inbox)
    defer sub.Unsubscribe()
    nc.PublishRequest(subject, inbox, req)

    // Return first response (fastest responder)
    msg, err := sub.NextMsg(500 * time.Millisecond)
    if err != nil { return nil }
    return msg.Data
}
```

## Quorum Read

```go
func quorumRead(nc *nats.Conn, key string, quorum int) ([]byte, bool) {
    responses := gatherAll(nc, "kv.get", []byte(key), 300*time.Millisecond)

    // Count responses
    if len(responses) < quorum {
        return nil, false  // not enough respondents
    }

    // Majority-vote: return value seen by >= quorum nodes
    counts := map[string]int{}
    for _, r := range responses {
        counts[string(r)]++
        if counts[string(r)] >= quorum {
            return r, true
        }
    }
    return nil, false  // no quorum
}
```

---
*Part of the 100-Lesson NATS Series.*
