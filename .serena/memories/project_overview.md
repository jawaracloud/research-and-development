# Jawaracloud Research & Development — Project Overview

## Purpose
A mono-repository of experimental, cloud-native projects and production-grade case studies maintained by **Jawaracloud**. Every sub-project follows the **Diátaxis** documentation framework with real-world scenarios.

## Repository Layout
```
research-and-development/
├── README.md
├── webassembly-series/       # 100-lesson: Rust + Wasm + Leptos + Axum
├── web3-series/              # 100-lesson: Go, Rust, Solidity, Ethereum, Solana
├── playwright-series/        # 100-lesson: Playwright, TypeScript, Node.js
├── ebpf-series/              # 100-lesson: Go 1.26, cilium/ebpf, Docker, K8s
├── chaos-engineering-series/ # Chaos engineering experiments (LitmusChaos, K8s)
├── nats-event-driven-demo/   # Event-driven microservices: Go, NATS JetStream
├── golang-pubsub/            # Real-time TUI pub/sub dashboard: Go, Bubble Tea, Redis
├── k8s-operator-pubsub/      # K8s operator with auto-scaling: Go, controller-runtime, Redis
└── waiting-room-demo/        # Cloudflare-style waiting room: Go, DragonFlyDB, NATS
```

## Standards
- **Automation-first**: All projects include Docker Compose or K8s manifests.
- **Production-ready**: Focus on scalability, security, and observability.
- **Documented ROI**: Each README includes a case study with quantifiable results.

## Primary Languages
| Language | Used By |
|---|---|
| Go | All Go-based projects (multiple versions, see per-project go.mod) |
| Rust | webassembly-series, web3-series |
| TypeScript | playwright-series |
| Solidity | web3-series |
| AssemblyScript | web3-series (subgraphs) |

## Go Module Paths (per project)
| Project | Module path | Go version |
|---|---|---|
| nats-event-driven-demo | github.com/jawaracloud/nats-event-driven-demo | 1.22.2 |
| waiting-room-demo | github.com/jawaracloud/waiting-room-demo | 1.23.0 |
| golang-pubsub | pubsub-demo | 1.24.2 |
| k8s-operator-pubsub | github.com/jawaracloud/pubsub-operator | 1.25.0 |
| ebpf-series | github.com/jawaracloud/ebpf-series | 1.26 |
