# Essential Commands

## Go
```bash
go build ./...
go test ./...
go vet ./...
gofmt -w .
go generate ./... # For eBPF
```

## Rust / Wasm
```bash
cargo fmt
cargo clippy
trunk serve # WebAssembly series dev server
```

## Web3 (Foundry)
```bash
forge build
forge test
```

## Playwright
```bash
npm install
npx playwright test
```

## Infrastructure
```bash
docker compose up -d
docker compose logs -f
kubectl apply -f config/ # K8s operators
```