# Suggested Commands

## General (run from each project's subdirectory unless stated otherwise)

### Go projects (nats-event-driven-demo, waiting-room-demo, k8s-operator-pubsub, ebpf-series, golang-pubsub)
```bash
# Build
go build ./...

# Test
go test ./...

# Format (run from the project root)
gofmt -w .
# or
goimports -w .

# Lint (requires golangci-lint)
golangci-lint run ./...

# Vet
go vet ./...

# Run a specific binary (check cmd/ or main.go)
go run ./cmd/<name>/...
# or
go run main.go
```

### Playwright series
```bash
cd playwright-series

# Install dependencies
npm install

# Run all tests
npm test                      # playwright test

# Run headed (visible browser)
npm run test:headed

# Debug
npm run test:debug

# Interactive UI mode
npm run test:ui

# Show HTML report
npm run report

# Serve test app
npm run serve

# Verify environment
npm run verify
```

### WebAssembly series (Rust + Wasm + Leptos)
```bash
cd webassembly-series

# Uses Nix flake for reproducible environment (flake.nix + .envrc)
nix develop
# or: direnv allow (if using direnv)

# Per-lesson build (Trunk dev server typically used)
trunk serve         # hot-reloading dev server

# Production build
trunk build --release

# Wasm-pack for raw wasm lessons
wasm-pack build --target web
```

### Web3 series (Go + Rust + Foundry + Solidity)
```bash
cd web3-series
# Uses Docker Compose for infrastructure
docker compose up -d

# Foundry (Solidity lessons)
forge build
forge test
forge script

# Go (Ethereum interaction lessons, e.g. go-ethereum)
go build ./...
go test ./...
```

### eBPF series
```bash
cd ebpf-series
# Requires Linux kernel with BPF support; uses devcontainer
docker compose up -d

# Per-lesson (each has its own Go-based program)
go generate ./...          # runs bpf2go to compile BPF C → Go
go build ./...
go run main.go             # (or per-lesson entrypoint)

# Root go.mod targets Go 1.26
```

### Docker Compose (most projects)
```bash
docker compose up -d        # start services
docker compose down         # stop services
docker compose logs -f      # follow logs
```

### Kubernetes / k8s-operator-pubsub
```bash
cd k8s-operator-pubsub
go build ./...
go test ./...

# Apply CRDs and deploy
kubectl apply -f config/
```
