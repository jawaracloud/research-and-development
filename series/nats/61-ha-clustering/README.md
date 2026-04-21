# 61 — High Availability & Clustering

> **Type:** Explanation  
> **Phase:** Production & Operations

## Overview

NATS achieves High Availability (HA) through clustering. A cluster is a group of NATS servers that communicate with each other to share client connection and subscription information.

## How Clustering Works

- **Gossip Protocol:** Servers share information about which clients are connected where.
- **Full Mesh:** Typically, every server in a cluster connects to every other server.
- **Interest propagation:** If a client on Server A publishes a message that a client on Server B is interested in, the message is automatically routed between servers.

## Configuring a Cluster

`server.conf`:
```
cluster {
  name: "NATS-PROD"
  listen: "0.0.0.0:6222"
  routes = [
    "nats://nats-1:6222",
    "nats://nats-2:6222",
    "nats://nats-3:6222"
  ]
}
```

## The "Rule of Three"

A production cluster should have at least **3 nodes**. This allows:
- **Resilience:** The cluster remains operational if 1 node fails.
- **JetStream Quorum:** Raft-based consensus requires a majority (2 out of 3) to function.

## Client Failover

Clients should be configured with all server addresses:

```go
nc, _ := nats.Connect("nats://nats-1:4222,nats://nats-2:4222,nats://nats-3:4222")
```

If the connected server fails, the client automatically picks another from the list and reconnects, including transparently re-establishing subscriptions.

## Monitoring Cluster Health

```bash
# Check routes from CLI
nats server ls

# Check varz for cluster info
curl -s http://localhost:8222/varz | jq .cluster
```

## Key Metrics

| Metric | Description |
|--------|-------------|
| `connected_nodes` | Number of peers this node is connected to. |
| `route_msgs_in` | Messages received from other nodes. |
| `route_msgs_out` | Messages sent to other nodes. |

---
*Part of the 100-Lesson NATS Series.*
