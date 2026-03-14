# 82 — Gateways & Superclusters

> **Type:** Explanation  
> **Phase:** Advanced & Real-World

## Overview

When a single cluster isn't enough (e.g., for multi-region or multi-cloud deployments), NATS uses **Gateways** to form a **Supercluster**.

## 1. What is a Supercluster?

A Supercluster is a collection of clusters linked together.
- **L3 Connectivity:** Unlike standard clusters, Gateways can work over high-latency WAN links.
- **Interest-Based Routing:** Messages are only sent to another cluster if there is matching subscription interest there. This saves massive bandwidth.

## 2. Gateway Configuration

Each cluster needs a gateway configuration block.

`cluster-us.conf`:
```
gateway {
    name: "US-EAST"
    port: 7222
    gateways: [
        { name: "EU-WEST", url: "nats://eu-west-lb:7222" }
    ]
}
```

## 3. Global Subject Space

In a supercluster, subjects are global.
1. **Service `A`** in US-East subscribes to `help.request`.
2. **Client `B`** in EU-West publishes to `help.request`.
3. NATS routes the message across the gateway to the US-East cluster.

## 4. JetStream in Superclusters

JetStream streams can be mirrored or sourced across gateways.
- **Pattern:** Create a stream in US and a mirror in EU.
- **Pattern:** Use a "Source" stream to aggregate data from 5 global clusters into one central master stream.

## 5. Supercluster Management

- **Splitting the brain:** If the gateway link fails, each cluster continues to operate independently. When the link returns, they automatically reconcile subscription interest.
- **Monitoring:** Use `nats server report gateways` to see the health and traffic stats of the inter-cluster links.

---
*Part of the 100-Lesson NATS Series.*
