# Task Completion Checklist

After completing any coding task in this repository, verify the following (as appropriate to the sub-project):

## Go Projects
- [ ] `go fmt ./...` or `goimports -w .` — no formatting drift
- [ ] `go vet ./...` — no vet errors
- [ ] `go build ./...` — compiles successfully
- [ ] `go test ./...` — all tests pass
- [ ] `golangci-lint run ./...` — no lint warnings (if golangci-lint is configured)
- [ ] Docker Compose still starts cleanly (`docker compose up -d`)

## Rust / WebAssembly Series
- [ ] `cargo fmt --check` — no formatting drift
- [ ] `cargo clippy -- -D warnings` — no clippy warnings
- [ ] `cargo build` — compiles successfully
- [ ] `cargo test` — all tests pass
- [ ] `trunk build` — Wasm bundle builds without errors

## TypeScript / Playwright Series
- [ ] `npm install` — deps are current
- [ ] `npm test` — all Playwright tests pass
- [ ] `npm run verify` — environment check passes

## Web3 Series
- [ ] `forge build` — Solidity contracts compile
- [ ] `forge test` — contract tests pass
- [ ] `go build ./...` / `go test ./...` — Go tooling lessons compile/test

## eBPF Series
- [ ] `go generate ./...` — BPF C objects regenerated (if .c files changed)
- [ ] `go build ./...` — compiles
- [ ] `go test ./...` — tests pass

## General
- [ ] README(s) updated if a new lesson or feature was added
- [ ] Docker Compose services healthy
- [ ] No sensitive data (keys, passwords) committed
