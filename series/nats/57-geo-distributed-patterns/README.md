# 57 — Geo-Distributed Patterns

> **Type:** Explanation  
> **Phase:** Patterns & Architecture

## Overview

NATS excels at geo-distribution through its **Gateway** and **Leaf Node** features. This lesson covers patterns for building systems that span multiple global regions.

## Topologies

### 1. Superclusters (Core-to-Core)
Connect multiple full NATS clusters using the Gateway protocol.

```
[Cluster US-East] ← Gateway → [Cluster EU-West]
```

- **Subject Interest propagation:** NATS only sends messages across regions if there is an active subscriber in the remote region.
- **Latency optimized:** Clients connect to their local region; cross-region traffic happens between servers.

### 2. Leaf Nodes (Edge-to-Core)
Connect small clusters or single servers to a central hub.

```
[Edge Device] -- Leaf Node --> [Central Hub]
```

- **Autonomous:** Edge node functions even if disconnected from hub.
- **Namespace remapping:** Map local `orders` to `hub.us-east.orders`.

## Patterns

### Geo-Request/Reply
A client makes a request to a subject. NATS routes to the **closest** available responder.

```bash
# Subscriber in US
nats sub svc.lookup --queue q1

# Subscriber in EU
nats sub svc.lookup --queue q1

# Client in US requests svc.lookup -> routed to US responder
```

### Regional Streams & Global Aggregation
Capture events locally for low latency, aggregate globally for analytics.

1. **Source Stream (Region):** `ORDERS_US` in US cluster.
2. **Global Stream (Hub):** `ORDERS_GLOBAL` mirrors `ORDERS_US` and `ORDERS_EU`.

```go
js.AddStream(&nats.StreamConfig{
    Name: "ORDERS_GLOBAL",
    Sources: []*nats.StreamSource{
        { Name: "ORDERS", External: &nats.ExternalStream{ APIPrefix: "$JS.US.API" } },
        { Name: "ORDERS", External: &nats.ExternalStream{ APIPrefix: "$JS.EU.API" } },
    },
})
```

### Follower/Read Replicas
Use JetStream mirrors to create local read copies of data in different regions.

- **Write:** Local region publishes to local stream.
- **Read:** Other regions mirror the stream for low-latency local reads.

## Design Considerations

| Constraint | Solution |
|------------|----------|
| **Latency** | Connect to local region; use mirrors for local reads. |
| **Availability** | Superclusters handle region failure gracefully. |
| **Data Sovereignty** | Keep sensitive data in specific account/region; only export anonymized data. |

---
*Part of the 100-Lesson NATS Series.*
