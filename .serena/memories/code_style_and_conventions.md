# Code Style & Conventions

## Go Projects
- **Formatting**: Standard `gofmt` / `goimports`. All Go code must pass `go vet`.
- **Naming**: idiomatic Go — CamelCase for exported, camelCase for unexported.
- **Error handling**: Explicit error returns; no panic in library code. `fmt.Errorf("...: %w", err)` wrapping.
- **Module structure**: Most projects follow the standard Go layout:
  - `cmd/` — main packages / entry points
  - `internal/` — private implementation code
  - `pkg/` — reusable packages
  - `api/` — API types (for K8s operator)
  - `controllers/` — K8s controller logic
  - `config/` — K8s manifests / CRDs
- **Logging**: `go.uber.org/zap` used in k8s-operator-pubsub; project-dependent elsewhere.
- **Config**: YAML via `go.yaml.in/yaml/v2|v3` or env vars.
- **Observability**: Prometheus metrics via `github.com/prometheus/client_golang`.

## Rust / WebAssembly
- **Formatting**: `cargo fmt`
- **Linting**: `cargo clippy`
- **Toolchain**: stable Rust + `wasm32-unknown-unknown` target; `wasm-bindgen`, `wasm-pack`, `web-sys`, `js-sys`.
- **Framework**: Leptos for frontend SPA; Axum for SSR/server-side.
- **Build tool**: Trunk (`trunk serve`, `trunk build`).

## TypeScript / Playwright
- **Formatting/linting**: No explicit ESLint config visible; TypeScript strict mode expected.
- **Test style**: Page Object Model (POM) pattern is covered in lesson 91.
- **Framework**: `@playwright/test` v1.50+, `@axe-core/playwright` for accessibility.
- **Node version**: >=22 required.

## Solidity / Web3
- **Toolchain**: Foundry (`forge`, `cast`, `anvil`).
- **Testing**: `forge test` with fuzz testing (`forge test --fuzz-runs`).
- **Security tooling**: Slither, Echidna (formal verification).

## Documentation
- **Standard**: Diátaxis framework (tutorials, how-to guides, explanations, references).
- **README**: Every sub-project has a `README.md` with case study and quantifiable results.
- **Per-lesson**: Each numbered lesson directory contains its own focused README.

## DevContainers
`webassembly-series`, `playwright-series`, `ebpf-series`, and `web3-series` each have a `.devcontainer/` with pre-installed toolchains for reproducible dev environments.
