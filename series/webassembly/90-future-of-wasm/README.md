# 90 — The Future of WebAssembly

> **Type:** Explanation

## Where WebAssembly is going

WebAssembly is not static. The W3C WebAssembly Working Group actively develops new proposals. Understanding the roadmap helps you anticipate what will become possible — and what you should design your systems to accommodate.

## Proposals in progress (2024)

### 1. Garbage Collection (GC) — Shipped ✅
Allows GC languages (Kotlin, Dart, Java) to run in Wasm without bundling their own GC. This is already in browsers. Does not affect Rust (which doesn't use GC).

### 2. Tail Call Optimization — Shipped ✅
Efficient recursion for functional languages. Allows stack-safe infinite loops via mutual tail calls.

### 3. Threads — Shipped ✅ (via SharedArrayBuffer)
Already covered in lesson 87.

### 4. SIMD — Shipped ✅
Already covered in lesson 88.

### 5. Relaxed SIMD — Shipped ✅
Extended SIMD operations that may have non-deterministic results (acceptable for ML inference, image processing).

### 6. Memory64 — In Progress 🔨
64-bit linear memory — allows Wasm modules to address more than 4GB of memory. Critical for scientific computing and large datasets.

### 7. Multi-memory — In Progress 🔨
Multiple linear memory instances in a single module. Enables better isolation between components sharing a module.

### 8. Exception Handling — Shipping 🚢
Native Wasm exceptions — allows C++ `try/catch` and similar to compile efficiently. Enables LLVM exception unwind without JS trampolining.

### 9. Type Reflection — In Progress 🔨
Allows runtime introspection of Wasm function types — needed for dynamic linking and debuggers.

### 10. Component Model — In Progress 🔨
Already covered in lesson 89. The biggest structural change to Wasm's interoperability model.

## WASI Preview 2 (2024)

The stable version of WASI (WebAssembly System Interface) using WIT interfaces:
- Sockets, filesystem, clocks, random, environment.
- Runs in Wasmtime, Fastly Compute, Cloudflare Workers, Fermyon Spin.
- Rust support: `cargo-component` + `wit-bindgen`.

This enables true "compile once, run anywhere" for Rust — server, browser, edge, embedded.

## Wasm in non-browser environments

| Platform | Runtime | Use case |
|----------|---------|---------|
| Edge (Cloudflare, Fastly) | Custom V8/Wasmtime | Zero-cold-start serverless |
| Docker (OCI) | Wasmtime / containerd-shim | Wasm containers |
| Kubernetes | Krustlet | Wasm workloads at scale |
| Embedded | wasmtime-embedded | Microcontrollers with <1MB RAM |
| Blockchain | EVM-Wasm, near-sdk | Smart contracts |
| Plugin systems | extism, wasmtime | Extensible apps |

## The browser in 5 years

Predicted Wasm browser capabilities by 2028:
- Native GC integration → JVM-quality performance for GC languages.
- Component Model in browsers → Import Wasm components like npm packages, cross-language.
- Wasm debugging in all DevTools at source level (Rust source, not Wasm text).
- Partial evaluation — browser pre-compiles Wasm to native at download time.

## What this means for Rust+Wasm developers

Rust+Wasm will remain the highest-performance path for browser computation. As other languages adopt Wasm (via GC proposal), the unique advantage of Rust shifts from "raw performance" to:
- **Predictable performance** — no GC pauses, ever.
- **Memory safety without GC** — WASI systems without a runtime.
- **Component Model** — share Rust components with Python, JavaScript, Go, etc.

## Staying current

- [WebAssembly proposals tracker](https://github.com/WebAssembly/proposals)
- [Leptos GitHub](https://github.com/leptos-rs/leptos)
- [This Week in Rust](https://this-week-in-rust.org) — weekly Wasm updates
- [Bytecode Alliance blog](https://bytecodealliance.org/articles) — WASI and Component Model news
