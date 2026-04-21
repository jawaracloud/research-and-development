# 100 — What's Next: Your Learning Path Forward

> **Type:** Reference

Congratulations — you've completed 100 lessons on WebAssembly with Rust and Leptos. 🎉

## What you've built and learned

| Part | Topic | Key skills |
|------|-------|-----------|
| 1–10 | Wasm concepts | Binary/text format, linear memory, execution model |
| 11–20 | Toolchain | wasm-pack, wasm-bindgen, trunk, debugging |
| 21–30 | JS interop | web-sys, js-sys, Serde, Promises, closures |
| 31–40 | Browser APIs | DOM, Canvas, Fetch, WebSockets, Web Workers |
| 41–50 | No-framework apps | VDOM, state machines, routing, projects |
| 51–60 | Leptos fundamentals | Signals, effects, props, events, rendering |
| 61–70 | Intermediate Leptos | Lists, forms, styling, routing, context, async |
| 71–80 | Full-stack SSR | Axum, server functions, hydration, DB, auth, Docker |
| 81–90 | Advanced | SIMD, threads, PWA, i18n, a11y, Component Model |
| 91–100 | Capstone | Real apps: chat, editor, dashboard, image processing |

## Next steps by interest

### 🎯 I want to go deeper into Leptos

- Follow the [Leptos book](https://book.leptos.dev) — the official reference, updated with each release.
- Study the [Leptos examples repository](https://github.com/leptos-rs/leptos/tree/main/examples).
- Contribute to Leptos — good first issues are tagged in the GitHub repo.
- Join the [Leptos Discord](https://discord.gg/YdRAhS7eQB).

### 🔬 I want to go deeper into Wasm performance

- Study [WebAssembly proposals](https://github.com/WebAssembly/proposals) — GC, memory64, exception handling.
- Learn about `wasm-opt` and the `binaryen` toolchain for advanced optimization.
- Read [Lin Clark's series](https://hacks.mozilla.org/category/code-cartoons/) on Wasm internals.
- Implement a parsing algorithm in Wasm and measure it against JavaScript.

### 🌍 I want to build production applications

- Choose a project from the capstone lessons and build a fully working version.
- Add real authentication (JWT or OAuth2 with the `oauth2` crate).
- Set up a production PostgreSQL database with connection pooling (PgBouncer).
- Implement full CI/CD with automated E2E tests (lesson 96).
- Add error monitoring (Sentry) and metrics (Prometheus + Grafana).

### 🧩 I want to learn about the Component Model

- Read the [Component Model specification](https://github.com/WebAssembly/component-model).
- Try [Fermyon Spin](https://developer.fermyon.com/spin) — serverless Wasm with Component Model.
- Use `cargo-component` to build a Component Model-based library.
- Explore [WASI Preview 2](https://github.com/WebAssembly/WASI) interfaces.

### 🤖 I want to use Rust+Wasm for ML/AI

- Study [burn](https://github.com/tracel-ai/burn) — a Rust ML framework with Wasm backend.
- Use [tract](https://github.com/sonos/tract) for running ONNX models in Wasm.
- Bring your own ONNX model from PyTorch or TensorFlow.
- Benchmark inference speed Wasm vs native.

## Recommended projects to build next

1. **Blog engine** — Leptos SSR + Markdown + tag-based search.
2. **Personal finance tracker** — WASM CRDT + IndexedDB for offline-first.
3. **Data visualization tool** — Canvas charts + WebSockets real-time data.
4. **Browser extension** — content script using Wasm for fast text parsing.
5. **CLI tool in Rust** that also compiles to Wasm for browser use.

## Community resources

| Resource | URL |
|----------|-----|
| Leptos book | https://book.leptos.dev |
| Leptos GitHub | https://github.com/leptos-rs/leptos |
| Rust Wasm book | https://rustwasm.github.io/docs/book |
| WebAssembly.org | https://webassembly.org |
| This Week in Rust | https://this-week-in-rust.org |
| Wasm Weekly | https://wasmweekly.news |
| Bytecode Alliance | https://bytecodealliance.org |

## A final note

WebAssembly is a young and rapidly evolving technology. The landscape you've learned in this series is a snapshot of 2024. New proposals, tools, and frameworks emerge constantly.

The most important skill you've developed isn't any specific API — it's the ability to reason about:
- The Wasm execution model and memory model.
- The JS-Wasm boundary and its costs.
- Rust's ownership system and how it translates to safe, performant Wasm.
- Leptos's reactive graph and how fine-grained reactivity differs from VDOM.

These fundamentals will serve you as the ecosystem evolves.

**Go build something real. That's where the deepest learning happens.**
