# NATS: The 100-Lesson Series 🚀

Welcome to the **NATS 100-Lesson Series**, a comprehensive, practical guide to mastering the NATS messaging system. From core pub/sub to global JetStream clusters, this series covers everything you need to build and operate world-class event-driven architectures.

## What is NATS?

NATS is a high-performance, open-source cloud native messaging system. It provides a simple, secure, and scalable way for applications to communicate across any cloud, on-premises, or edge environment.

---

## 🗺 Course Curriculum

### Phase 1: Foundations (Lessons 01-20)
*Grounding in core NATS concepts, the protocol, and local setup.*

- [01 — What is NATS?](01-what-is-nats/README.md)
- [02 — High-Level Architecture](02-nats-architecture/README.md)
- [03 — Core NATS vs. JetStream](03-core-vs-jetstream/README.md)
- [04 — Pub-Sub Model Deep Dive](04-pubsub-model/README.md)
- [05 — Request-Reply Model](05-request-reply/README.md)
- [06 — Queue Groups](06-queue-groups/README.md)
- [07 — Local Lab Setup](07-local-lab-setup/README.md)
- [08 — Your First Publisher](08-first-publisher/README.md)
- [09 — Your First Subscriber](09-first-subscriber/README.md)
- [10 — Wildcard Subjects](10-wildcard-subjects/README.md)
- [11 — NATS CLI Deep Dive](11-nats-cli/README.md)
- [12 — Connection Handling](12-connection-handling/README.md)
- [13 — Error Handling](13-error-handling/README.md)
- [14 — Authentication & Authorization](14-auth-authorization/README.md)
- [15 — TLS Encryption](15-tls-encryption/README.md)
- [16 — Monitoring NATS](16-nats-monitoring/README.md)
- [17 — Subject Naming Conventions](17-subject-naming/README.md)
- [18 — Message Headers](18-message-headers/README.md)
- [19 — Drain & Graceful Shutdown](19-drain-graceful-shutdown/README.md)
- [20 — NATS on Docker & Kubernetes](20-nats-docker-kubernetes/README.md)

### Phase 2: JetStream Persistance (Lessons 21-40)
*Mastering streams, consumers, and data durability.*

- [21 — JetStream Concepts](21-jetstream-concepts/README.md)
- [22 — Streams Management](22-streams/README.md)
- [23 — Consumers: Push vs. Pull](23-push-vs-pull-consumers/README.md)
- [24 — Consumer Configuration](24-consumer-configuration/README.md)
- [25 — Ack Policies](25-ack-policies/README.md)
- [26 — Replay Policies](26-replay-policies/README.md)
- [27 — Retention Policies](27-retention-policies/README.md)
- [28 — Storage Types: File vs. Memory](28-storage-types/README.md)
- [29 — Stream Limits & Discard Policies](29-stream-limits-discard/README.md)
- [30 — Multi-Subject Streams](30-multi-subject-streams/README.md)
- [31 — Durable Consumers](31-durable-consumers/README.md)
- [32 — Ephemeral Consumers](32-ephemeral-consumers/README.md)
- [33 — Ordered Consumers](33-ordered-consumers/README.md)
- [34 — Consumer Groups (JetStream)](34-consumer-groups/README.md)
- [35 — Exactly-Once Delivery](35-exactly-once-delivery/README.md)
- [36 — Message Deduplication](36-message-deduplication/README.md)
- [37 — Headers-Only Delivery](37-headers-only-delivery/README.md)
- [38 — Stream Mirrors & Sources](38-mirrors-and-sources/README.md)
- [39 — Stream Purge & Delete](39-stream-purge-delete/README.md)
- [40 — JetStream API Reference](40-jetstream-api-reference/README.md)

### Phase 3: Patterns & Architecture (Lessons 41-60)
*Building complex systems using NATS patterns.*

- [41 — Event-Driven Architecture](41-event-driven-architecture/README.md)
- [42 — CQRS with NATS](42-cqrs-with-nats/README.md)
- [43 — Event Sourcing with JetStream](43-event-sourcing/README.md)
- [44 — Saga Pattern](44-saga-pattern/README.md)
- [45 — Inbox Pattern (Fan-Out/In)](45-inbox-fan-out-fan-in/README.md)
- [46 — Dead Letter Queue](46-dead-letter-queue/README.md)
- [47 — Rate Limiting](47-rate-limiting/README.md)
- [48 — Backpressure Handling](48-backpressure-handling/README.md)
- [49 — Idempotent Consumers](49-idempotent-consumers/README.md)
- [50 — Message Versioning](50-message-versioning/README.md)
- [51 — Service Discovery](51-service-discovery/README.md)
- [52 — NATS Micro Framework](52-nats-micro-framework/README.md)
- [53 — Request Scatter/Gather](53-request-scatter-gather/README.md)
- [54 — Circuit Breaker](54-circuit-breaker/README.md)
- [55 — Priority Queues](55-priority-queues/README.md)
- [56 — Multi-Tenant Architecture](56-multi-tenant-architecture/README.md)
- [57 — Geo-Distributed Patterns](57-geo-distributed-patterns/README.md)
- [58 — Data Locality & Sharding](58-sharding-patterns/README.md)
- [59 — Hybrid Cloud Bridge (Leaf Nodes)](59-hybrid-cloud-bridge/README.md)
- [60 — Architectural Best Practices](60-architectural-best-practices/README.md)

### Phase 4: Production & Operations (Lessons 61-80)
*Running NATS clusters at scale with confidence.*

- [61 — High Availability & Clustering](61-ha-clustering/README.md)
- [62 — JetStream Placement & Replicas](62-jetstream-placement-replicas/README.md)
- [63 — Raft & Quorum](63-raft-and-quorum/README.md)
- [64 — Observability with Prometheus](64-prometheus-observability/README.md)
- [65 — Grafana Dashboards](65-grafana-dashboards/README.md)
- [66 — Logging & Tracing](66-logging-tracing/README.md)
- [67 — NATS Surveyor Deep Dive](67-nats-surveyor/README.md)
- [68 — Troubleshooting Connections](68-troubleshooting-connections/README.md)
- [69 — Performance Tuning](69-performance-tuning/README.md)
- [70 — Benchmarking with nats-bench](70-benchmarking-nats-bench/README.md)
- [71 — Security Hardening](71-security-hardening/README.md)
- [72 — Access Control Lists (ACL)](72-acl-permissions/README.md)
- [73 — Account Isolation](73-account-isolation/README.md)
- [74 — Resource Quotas & Limits](74-resource-quotas/README.md)
- [75 — Backup & Recovery](75-backup-recovery/README.md)
- [76 — Disaster Recovery (DR)](76-disaster-recovery/README.md)
- [77 — Upgrading Clusters](77-upgrading-clusters/README.md)
- [78 — Capacity Planning](78-capacity-planning/README.md)
- [79 — Cost Optimization](79-cost-optimization/README.md)
- [80 — Operations Checklist](80-operations-checklist/README.md)

### Phase 5: Advanced & Real-World (Lessons 81-100)
*Edge cases, migrations, and niche use cases.*

- [81 — Leaf Nodes in Depth](81-leaf-nodes-in-depth/README.md)
- [82 — Gateways & Superclusters](82-gateways-superclusters/README.md)
- [83 — WebSockets & NATS.js](83-websockets-nats-js/README.md)
- [84 — Mobile & NATS](84-mobile-nats/README.md)
- [85 — IoT & MQTT Bridge](85-iot-mqtt-bridge/README.md)
- [86 — Edge Computing](86-edge-computing/README.md)
- [87 — Advanced KV Patterns](87-advanced-kv-patterns/README.md)
- [88 — Object Store Patterns](88-object-store-patterns/README.md)
- [89 — Custom JetStream Placement](89-custom-placement/README.md)
- [90 — NATS for AI/ML Pipelines](90-nats-for-ai-ml/README.md)
- [91 — Streaming Video over NATS](91-streaming-video/README.md)
- [92 — Large File Transfers](92-large-file-transfers/README.md)
- [93 — Security Auditing](93-security-auditing/README.md)
- [94 — Compliance (GDPR/HIPAA)](94-compliance-eda/README.md)
- [95 — Migration: Kafka to NATS](95-kafka-to-nats/README.md)
- [96 — Migration: RabbitMQ to NATS](96-rabbitmq-to-nats/README.md)
- [97 — Building a PaaS with NATS](97-building-a-paas/README.md)
- [98 — Custom Bridges](98-custom-bridges/README.md)
- [99 — The Future of NATS](99-the-future-of-nats/README.md)
- [100 — Course Wrap-up](100-wrap-up/README.md)

---

## 🛠 Prerequisites

To follow along with the hands-on exercises, you will need:
- **Go** (1.21+)
- **NATS CLI** (`brew install nats-io/nats-tools/nats`)
- **Docker** and **Docker Compose**
- **Terraform** (for some infrastructure lessons)

---

## 🚀 Getting Started

1. Clone the repository.
2. Navigate to [07 — Local Lab Setup](07-local-lab-setup/README.md) to initialize your development environment.
3. Start with [01 — What is NATS?](01-what-is-nats/README.md).

---
*Created as part of the JawaraCloud R&D Initiatives.*
