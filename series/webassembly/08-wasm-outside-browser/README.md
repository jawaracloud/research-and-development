# 08 — Wasm Outside the Browser (WASI, Edge, Serverless)

> **Type:** Explanation

## Wasm is not only for browsers

The browser is the most common runtime, but Wasm's portability makes it valuable in many other environments. The key enabler for server-side Wasm is **WASI**.

## WASI — WebAssembly System Interface

Browsers give Wasm access to Web APIs. Outside the browser, Wasm modules have no system calls — they can't read files, open sockets, or print to stdout without an interface.

**WASI** is a standardized set of system-call-like interfaces for Wasm modules. It's inspired by POSIX, but designed for capability-based security.

```
WebAssembly module
        │  calls
        ▼
  WASI interface  (standardized syscalls: fd_read, fd_write, path_open, ...)
        │  implemented by
        ▼
  Wasm runtime  (Wasmtime, WasmEdge, wasm3, ...)
        │  calls
        ▼
  Host OS (Linux, macOS, Windows)
```

Key point: a WASI module cannot access the filesystem unless the **runtime** explicitly grants it that capability. This is stronger isolation than containers or VMs.

## Runtimes

| Runtime | Description | Use Case |
|---------|-------------|---------|
| **Wasmtime** | Mozilla/Bytecode Alliance. Fast, production-ready. | CLI, server apps |
| **WasmEdge** | Optimized for cloud and AI. Supports sockets, async. | Edge computing, AI |
| **wasm3** | Tiny interpreter. 64 KB. | Embedded / IoT |
| **wasmer** | AOT compilation, supports many languages. | Server, desktop |

## Edge and serverless use cases

| Platform | How |
|---------|-----|
| **Cloudflare Workers** | Runs Wasm natively. Rust → Wasm is a first-class workflow. |
| **Fastly Compute@Edge** | Compile Rust directly to Wasm for edge functions. |
| **Vercel Edge Functions** | JS runtime, but can import Wasm modules. |
| **Fermyon Spin** | Microservices framework that runs Wasm components. |

Wasm on the edge has huge advantages:
- **Cold start in microseconds** (vs. milliseconds for Node.js, seconds for containers).
- **True multi-tenancy** — thousands of Wasm instances share one process safely.
- **Write once, run anywhere** — same `.wasm` file on x86, ARM, RISC-V.

## Running a Rust WASI program

```bash
# Install the WASI target
rustup target add wasm32-wasi

# Build
cargo build --target wasm32-wasi --release

# Run with wasmtime
wasmtime ./target/wasm32-wasi/release/myapp.wasm
```

## Wasm as a universal plugin format

Some applications use Wasm as a **safe plugin system**. Instead of loading native `.so` / `.dll` files (which have full OS access), plugins ship as `.wasm` files, and the host grants only the capabilities the plugin needs. Examples: Envoy proxy filters, eBPF alternatives, game modding.
