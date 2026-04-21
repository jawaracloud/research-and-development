# Web3 Ecosystem Series (Go + Rust)

> A structured, 100-lesson journey through the **Web3 ecosystem** using **Go and Rust** — playing to the strengths of each language. Learn Ethereum/EVM DApps, Solana smart contracts, IPFS storage, DeFi patterns, and cross-chain concepts.

---

## Introduction

Why two languages? Because Web3 isn't monolithic. If you want to build on Ethereum, the industry standard smart contract paradigm is **Solidity** using **Foundry** (written in Rust), and the best high-performance backend tooling is **Go** (`go-ethereum`). If you want to build on Solana, the native language for smart contracts is **Rust**.

| Tool / Layer | Language | Purpose |
|--------------|----------|---------|
| EVM Smart Contracts | Solidity/Foundry (Rust) | On-chain logic for Ethereum, Polymer, Optimism |
| EVM Backends/Indexers | Go | Reading states, parsing ABI, responding to events |
| Solana Smart Contracts | Rust (Anchor) | On-chain logic for Solana |
| Storage (IPFS/Kubo) | Go | Decentralized storage |

## 🛠️ Environment Setup

### Option A — VS Code Dev Container (recommended)

1. Open the `web3-series/` folder in VS Code.
2. Click **"Reopen in Container"**.
3. Wait first build — installs Go 1.26, Rust 1.84, Foundry, Solana Tool Suite, Anchor, and IPFS CLI.

### Option B — Docker Compose (CLI)

```bash
# Build once
docker compose build

# Open shell with all tools
docker compose run --rm dev
```

### Verify your environment

Inside the container, run:
```bash
bash scripts/verify-env.sh
```

Expected output: `✅` for Go, Rust, Cargo, Node.js, Forge, Cast, Anvil, Solana CLI, Anchor CLI, and IPFS.

---

## Series Structure Overview

| Part | Lessons | Focus | Primary Tech |
|------|---------|-------|--------------|
| **1. Fundamentals** | 01–10 | Keys, transactions, EVM vs Solana, wallets | Theory / Go |
| **2. Solidity (EVM)** | 11–25 | Writing EVM contracts, Foundry, tokens, testing | Solidity + Foundry |
| **3. Go Backend** | 26–40 | go-ethereum, binding ABIs to Go, indexers, APIs | Go |
| **4. Solana (Rust)** | 41–55 | Anchor framework, PDAs, SPL tokens, deployment | Rust |
| **5. Storage & Data** | 56–65 | IPFS via Go, Arweave, The Graph subgraphs | Go + AssemblyScript |
| **6. DeFi Patterns** | 66–75 | AMMs, Oracles, Flash Loans, Liquidations | Go + Solidity |
| **7. NFT Deep Dive** | 76–82 | Metadata standards, Royalties, Marketplaces | Rust + Solidity |
| **8. Security** | 83–88 | Fuzzing, Static Analysis (Slither), OWASP Top 10 | Solidity / Foundry |
| **9. Infrastructure** | 89–95 | Running local nodes, CI/CD, Gas Strategies | Go |
| **10. Cross-Chain** | 96–100 | LayerZero, Account Abstraction, L2 Rollups | Theory + Go/Solidity |

---

## Table of Contents

> Full TOC will be indexed across the 100 component directories. Look at `01-what-is-web3/README.md` to begin!

## References

- [Ethereum Foundation Go-Ethereum Docs](https://geth.ethereum.org/docs/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Solana Cookbook](https://solanacookbook.com/)
- [Anchor Book](https://www.anchor-lang.com/docs/)
- [IPFS CLI (kubo) Docs](https://docs.ipfs.tech/)
