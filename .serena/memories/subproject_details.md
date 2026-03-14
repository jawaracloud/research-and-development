# Sub-project Deep Dive

## 1. waiting-room-demo
- **Purpose**: Cloudflare-style virtual waiting room to queue traffic spikes.
- **Tech**: Go 1.23, chi router, NATS JetStream, Redis/DragonFlyDB, Prometheus, JWT.
- **Layout**: `cmd/`, `internal/`, `pkg/`, `scripts/`, `docs/`, `observability/`, `deploy/`.
- **Module**: `github.com/jawaracloud/waiting-room-demo`

## 2. k8s-operator-pubsub
- **Purpose**: Kubernetes custom operator that auto-scales pub/sub consumers.
- **Tech**: Go 1.25, `controller-runtime`, `k8s.io/client-go`, Prometheus, Zap logging.
- **Layout**: `cmd/`, `api/` (CRD types), `controllers/`, `pkg/`, `config/` (manifests), `deployments/`.
- **Module**: `github.com/jawaracloud/pubsub-operator`

## 3. nats-event-driven-demo
- **Purpose**: Demonstrates event-driven microservices with NATS JetStream.
- **Tech**: Go 1.22.2, NATS JetStream.
- **Layout**: `producer/`, `consumer/`, `shared/`.
- **Module**: `github.com/jawaracloud/nats-event-driven-demo`

## 4. golang-pubsub
- **Purpose**: Real-time TUI dashboard visualizing Redis Pub/Sub in terminal.
- **Tech**: Go 1.24.2, Bubble Tea, Lipgloss, Redis (`go-redis/v9`).
- **Layout**: `pub.go`, `sub.go`, `dashboard/`.
- **Module**: `pubsub-demo`

## 5. ebpf-series (100 lessons)
- **Purpose**: Comprehensive series on eBPF in container/Kubernetes environments.
- **Tech**: Go 1.26, `cilium/ebpf`, Docker, Kubernetes, bpf2go.
- **Key topics**: program types, maps, kprobes, tracepoints, XDP, TC, cgroups, LSM, namespaces, container security.
- **Module**: `github.com/jawaracloud/ebpf-series`
- **DevContainer**: `.devcontainer/` with all eBPF tools pre-installed.

## 6. webassembly-series (100 lessons)
- **Purpose**: Comprehensive series on WebAssembly using Rust and Leptos.
- **Tech**: Rust, `wasm-bindgen`, `web-sys`, `js-sys`, Leptos (SPA + SSR), Axum, Trunk, wasm-pack, Nix flake.
- **Key topics**: WAT format, linear memory, DOM manipulation, reactivity, routing, SSR/hydration, auth, Axum integration.
- **DevContainer**: `.devcontainer/` available.

## 7. web3-series (100 lessons)
- **Purpose**: Comprehensive series on the Web3 ecosystem — Ethereum + Solana.
- **Tech**: Go (`go-ethereum`), Rust (Anchor), Solidity (Foundry), IPFS, The Graph (AssemblyScript), Chainlink.
- **Key topics**: smart contracts, NFTs, DeFi, wallets, indexing, security auditing, L2s, cross-chain.
- **DevContainer**: `.devcontainer/` available.
- **Infrastructure**: `docker-compose.yml` (e.g. local Geth, IPFS nodes).

## 8. playwright-series (100 lessons)
- **Purpose**: UI component automation testing series using Playwright.
- **Tech**: TypeScript, `@playwright/test` v1.50+, `@axe-core/playwright`, Allure reporter, Node.js >=22.
- **Key topics**: locators, assertions, form controls, tables, drag-drop, auth flows, visual regression, CI/CD, MCP.
- **DevContainer**: `.devcontainer/` available.
- **Test app**: `playwright-series/test-app/` — the target HTML app for the lessons.

## 9. chaos-engineering-series
- **Purpose**: Chaos engineering experiments using LitmusChaos and Kubernetes.
- **Sub-directory**: `chaos-engineering-litmus/`
- **Tech**: LitmusChaos, Kubernetes.
