# WebAssembly with Rust — Complete Learning Series

> A structured, 100-lesson journey from zero WebAssembly knowledge to production-ready applications in Rust. Framework of choice: **Leptos**.

---

## Introduction

**WebAssembly (Wasm)** is a binary instruction format that runs in the browser at near-native speed. **Rust** is one of the best languages for targeting Wasm — it compiles directly to it, has no garbage collector, produces tiny binaries, and has a mature toolchain (`wasm-pack`, `wasm-bindgen`, `trunk`).

This series is split into two major arcs:

1. **Without a framework** (lessons 01–50) — You learn how Wasm works under the hood, how Rust compiles to it, how to manipulate the DOM manually through `web-sys`/`js-sys`, and how to build small applications from scratch. This builds the mental model you *need* before adopting a framework.
2. **With Leptos** (lessons 51–100) — You learn Leptos, a full-stack Rust framework for building reactive web applications that compile to Wasm. Leptos was chosen because it offers fine-grained reactivity (no virtual DOM), server-side rendering, and an API surface familiar to anyone who has used React or SolidJS.

Each lesson lives in its own sub-directory with a `README.md` written using the [Diátaxis](https://diataxis.fr/) framework (tutorials, how-to guides, explanations, or references — whichever fits the lesson best).

---

## 🛠️ Environment Setup

All tools you need for every lesson are pre-configured. Pick **one** path:

### Option A — VS Code Dev Container (recommended)

Requires: [VS Code](https://code.visualstudio.com) + [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) + Docker Desktop.

1. Clone the repo and open the `webassembly-series/` folder in VS Code.
2. Click **"Reopen in Container"** in the notification (bottom-right).
3. Wait ~3-5 minutes for the first build — subsequent opens are instant.
4. A terminal inside VS Code has everything ready.

Works identically on **GitHub Codespaces** — just click *Code → Open with Codespaces* on GitHub.

### Option B — Nix (reproducible, no Docker needed)

Requires: [Nix](https://nixos.org/download) with flakes enabled.

```bash
# One-time: enter the dev shell
nix develop

# Optional: auto-activate whenever you cd into this directory
echo "use flake" > .envrc && direnv allow
```

### Option C — Docker Compose (CLI, no VS Code)

Requires: Docker + Docker Compose.

```bash
# Build the image once (~5 min)
docker compose build

# Drop into a shell with all tools ready
docker compose run --rm dev

# Run a lesson's dev server (example: trunk on port 8080)
docker compose run --rm -p 8080:8080 dev trunk serve --address 0.0.0.0
```

### Verify your environment

Run this inside any of the three environments to confirm all tools are present:

```bash
bash scripts/verify-env.sh
```

Expected output: a table of tools with ✅ next to each one.

---

### What's installed

| Tool | Version | Used in |
|------|---------|---------|
| Rust (stable) | 1.85 | All lessons |
| `wasm32-unknown-unknown` target | — | All lessons |
| `wasm-pack` | 0.13 | Lessons 12, 28–30 |
| `wasm-bindgen-cli` | 0.2.100 | Lessons 13–30 |
| `trunk` | 0.21 | Lessons 15–50 |
| `cargo-leptos` | 0.2 | Lessons 51–100 |
| `cargo-generate` | 0.21 | Project scaffolding |
| `wasm-opt` (binaryen) | — | Lesson 16, 82 |
| `wabt` (wat2wasm) | — | Lessons 3–4 |
| `sqlx-cli` | 0.8 | Lessons 75–80 |
| `cargo-watch` | 8.5 | All dev workflows |
| `twiggy` | 0.7 | Lesson 82 |
| Node.js 22 LTS | — | Lessons 83, 96 |
| Playwright (Chromium) | latest | Lesson 83 |
| VS Code extensions | — | rust-analyzer, CodeLLDB, TOML, Live Preview, etc. |

---

## Table of Contents

### Part 1 — What Is WebAssembly? (Concepts)

| # | Directory | Title |
|---|-----------|-------|
| 01 | [`01-what-is-webassembly`](./01-what-is-webassembly) | What Is WebAssembly and Why Does It Matter? |
| 02 | [`02-wasm-vs-javascript`](./02-wasm-vs-javascript) | Wasm vs JavaScript — Complementary, Not Competing |
| 03 | [`03-wasm-binary-format`](./03-wasm-binary-format) | Understanding the Wasm Binary Format (.wasm) |
| 04 | [`04-wasm-text-format`](./04-wasm-text-format) | Reading WAT — The WebAssembly Text Format |
| 05 | [`05-wasm-execution-model`](./05-wasm-execution-model) | The Wasm Stack Machine Execution Model |
| 06 | [`06-linear-memory`](./06-linear-memory) | Linear Memory — How Wasm Manages Data |
| 07 | [`07-wasm-in-the-browser`](./07-wasm-in-the-browser) | How Browsers Load and Run Wasm Modules |
| 08 | [`08-wasm-outside-browser`](./08-wasm-outside-browser) | Wasm Outside the Browser (WASI, Edge, Serverless) |
| 09 | [`09-wasm-security-model`](./09-wasm-security-model) | The Wasm Security Sandbox |
| 10 | [`10-wasm-use-cases`](./10-wasm-use-cases) | Real-World Use Cases for WebAssembly |

### Part 2 — Setting Up Rust for WebAssembly

| # | Directory | Title |
|---|-----------|-------|
| 11 | [`11-install-rust-toolchain`](./11-install-rust-toolchain) | Installing Rust and the `wasm32-unknown-unknown` Target |
| 12 | [`12-wasm-pack`](./12-wasm-pack) | wasm-pack — Build, Test, Publish Rust-Generated Wasm |
| 13 | [`13-wasm-bindgen-intro`](./13-wasm-bindgen-intro) | wasm-bindgen — Bridging Rust and JavaScript |
| 14 | [`14-cargo-toml-for-wasm`](./14-cargo-toml-for-wasm) | Configuring Cargo.toml for Wasm Projects |
| 15 | [`15-hello-wasm`](./15-hello-wasm) | Hello, Wasm! — Your First Rust → Wasm Build |
| 16 | [`16-wasm-opt-and-size`](./16-wasm-opt-and-size) | Optimizing Wasm Binary Size with `wasm-opt` |
| 17 | [`17-trunk-dev-server`](./17-trunk-dev-server) | Trunk — A Dev Server and Bundler for Rust Wasm |
| 18 | [`18-debugging-wasm`](./18-debugging-wasm) | Debugging Wasm in the Browser DevTools |
| 19 | [`19-console-logging`](./19-console-logging) | Logging from Rust to the Browser Console |
| 20 | [`20-error-handling-in-wasm`](./20-error-handling-in-wasm) | Handling Errors Across the Rust–JS Boundary |

### Part 3 — JavaScript Interop Deep Dive

| # | Directory | Title |
|---|-----------|-------|
| 21 | [`21-js-sys-crate`](./21-js-sys-crate) | The `js-sys` Crate — Calling JavaScript Built-ins from Rust |
| 22 | [`22-web-sys-crate`](./22-web-sys-crate) | The `web-sys` Crate — Browser APIs in Rust |
| 23 | [`23-passing-strings`](./23-passing-strings) | Passing Strings Between Rust and JavaScript |
| 24 | [`24-passing-structs`](./24-passing-structs) | Passing Complex Data Structures (Serde + JsValue) |
| 25 | [`25-closures-and-callbacks`](./25-closures-and-callbacks) | Closures and Callbacks Across the Wasm Boundary |
| 26 | [`26-promises-and-futures`](./26-promises-and-futures) | Promises in JS ↔ Futures in Rust (`wasm-bindgen-futures`) |
| 27 | [`27-importing-js-functions`](./27-importing-js-functions) | Importing Custom JavaScript Functions into Rust |
| 28 | [`28-exporting-rust-functions`](./28-exporting-rust-functions) | Exporting Rust Functions for JavaScript Consumption |
| 29 | [`29-memory-management`](./29-memory-management) | Memory Management — Ownership Across the Boundary |
| 30 | [`30-typescript-definitions`](./30-typescript-definitions) | Generating TypeScript Definitions from Rust |

### Part 4 — DOM & Browser APIs Without a Framework

| # | Directory | Title |
|---|-----------|-------|
| 31 | [`31-query-and-modify-dom`](./31-query-and-modify-dom) | Querying and Modifying the DOM from Rust |
| 32 | [`32-creating-elements`](./32-creating-elements) | Creating and Appending HTML Elements Dynamically |
| 33 | [`33-event-listeners`](./33-event-listeners) | Adding Event Listeners (Click, Input, Submit) |
| 34 | [`34-canvas-2d`](./34-canvas-2d) | Drawing on the HTML5 Canvas (2D Context) |
| 35 | [`35-canvas-animation`](./35-canvas-animation) | Animating with `requestAnimationFrame` |
| 36 | [`36-fetch-api`](./36-fetch-api) | Making HTTP Requests with the Fetch API |
| 37 | [`37-local-storage`](./37-local-storage) | Reading and Writing to Local Storage |
| 38 | [`38-web-workers`](./38-web-workers) | Running Wasm Inside Web Workers |
| 39 | [`39-file-reader-api`](./39-file-reader-api) | Reading Files from the User's Filesystem |
| 40 | [`40-websockets`](./40-websockets) | Real-Time Communication with WebSockets |

### Part 5 — Building Apps Without a Framework

| # | Directory | Title |
|---|-----------|-------|
| 41 | [`41-component-pattern`](./41-component-pattern) | Implementing a Component Pattern Manually |
| 42 | [`42-virtual-dom-concept`](./42-virtual-dom-concept) | Building a Minimal Virtual DOM in Rust |
| 43 | [`43-state-management`](./43-state-management) | State Management Without a Framework |
| 44 | [`44-client-side-routing`](./44-client-side-routing) | Client-Side Routing with the History API |
| 45 | [`45-todo-app-no-framework`](./45-todo-app-no-framework) | Project: Todo App (No Framework) |
| 46 | [`46-counter-app-no-framework`](./46-counter-app-no-framework) | Project: Counter App with State & Rendering |
| 47 | [`47-markdown-previewer`](./47-markdown-previewer) | Project: Markdown Previewer (Rust Parsing + DOM) |
| 48 | [`48-form-validation`](./48-form-validation) | Project: Form Validation Library in Wasm |
| 49 | [`49-css-in-rust`](./49-css-in-rust) | Styling Strategies — CSS-in-Rust Approaches |
| 50 | [`50-no-framework-retrospective`](./50-no-framework-retrospective) | Retrospective: What a Framework Solves for You |

### Part 6 — Leptos Fundamentals

| # | Directory | Title |
|---|-----------|-------|
| 51 | [`51-why-leptos`](./51-why-leptos) | Why Leptos? — Fine-Grained Reactivity in Rust |
| 52 | [`52-leptos-project-setup`](./52-leptos-project-setup) | Setting Up a Leptos Project with `cargo-leptos` |
| 53 | [`53-your-first-leptos-component`](./53-your-first-leptos-component) | Your First Leptos Component |
| 54 | [`54-rsx-macro`](./54-rsx-macro) | The `view!` Macro — Writing HTML in Rust |
| 55 | [`55-signals-and-reactivity`](./55-signals-and-reactivity) | Signals — The Core of Leptos Reactivity |
| 56 | [`56-derived-signals`](./56-derived-signals) | Derived Signals and Memos |
| 57 | [`57-effects`](./57-effects) | Effects — Reacting to Signal Changes |
| 58 | [`58-component-props`](./58-component-props) | Component Props and the `#[component]` Macro |
| 59 | [`59-event-handling-leptos`](./59-event-handling-leptos) | Event Handling in Leptos |
| 60 | [`60-conditional-rendering`](./60-conditional-rendering) | Conditional Rendering (`Show`, `match`) |

### Part 7 — Leptos Intermediate Patterns

| # | Directory | Title |
|---|-----------|-------|
| 61 | [`61-list-rendering`](./61-list-rendering) | Rendering Lists with `<For>` |
| 62 | [`62-forms-and-inputs`](./62-forms-and-inputs) | Controlled & Uncontrolled Forms in Leptos |
| 63 | [`63-styling-leptos`](./63-styling-leptos) | Styling Leptos Components (CSS, Tailwind, Stylers) |
| 64 | [`64-leptos-router`](./64-leptos-router) | Client-Side Routing with `leptos_router` |
| 65 | [`65-nested-routes`](./65-nested-routes) | Nested Routes and Layouts |
| 66 | [`66-context-api`](./66-context-api) | Global State with the Context API |
| 67 | [`67-resources-and-async`](./67-resources-and-async) | Fetching Data with Resources (`create_resource`) |
| 68 | [`68-suspense`](./68-suspense) | `<Suspense>` and Loading States |
| 69 | [`69-error-boundaries`](./69-error-boundaries) | Error Boundaries and Recovery |
| 70 | [`70-actions-and-forms`](./70-actions-and-forms) | Server Actions and Progressive Forms |

### Part 8 — Leptos Full-Stack & SSR

| # | Directory | Title |
|---|-----------|-------|
| 71 | [`71-ssr-overview`](./71-ssr-overview) | Server-Side Rendering in Leptos — Overview |
| 72 | [`72-actix-integration`](./72-actix-integration) | Integrating Leptos with Actix-Web |
| 73 | [`73-axum-integration`](./73-axum-integration) | Integrating Leptos with Axum |
| 74 | [`74-server-functions`](./74-server-functions) | `#[server]` Functions — RPC Without REST |
| 75 | [`75-hydration`](./75-hydration) | Hydration — From Server HTML to Interactive Client |
| 76 | [`76-database-access`](./76-database-access) | Accessing a Database from Server Functions |
| 77 | [`77-authentication`](./77-authentication) | Authentication Flow (Login, Signup, Sessions) |
| 78 | [`78-middleware-and-guards`](./78-middleware-and-guards) | Middleware, Extractors, and Route Guards |
| 79 | [`79-environment-config`](./79-environment-config) | Environment Configuration and Secrets |
| 80 | [`80-streaming-ssr`](./80-streaming-ssr) | Streaming SSR and Out-of-Order Rendering |

### Part 9 — Advanced Topics & Optimization

| # | Directory | Title |
|---|-----------|-------|
| 81 | [`81-code-splitting`](./81-code-splitting) | Code Splitting and Lazy Loading in Leptos |
| 82 | [`82-wasm-performance`](./82-wasm-performance) | Wasm Performance Profiling and Benchmarking |
| 83 | [`83-testing-wasm`](./83-testing-wasm) | Testing Wasm with `wasm-bindgen-test` |
| 84 | [`84-testing-leptos`](./84-testing-leptos) | Testing Leptos Components |
| 85 | [`85-i18n`](./85-i18n) | Internationalization (i18n) in Leptos |
| 86 | [`86-accessibility`](./86-accessibility) | Accessibility (a11y) Best Practices |
| 87 | [`87-pwa-support`](./87-pwa-support) | Progressive Web App (Service Worker, Manifest) |
| 88 | [`88-wasm-threads`](./88-wasm-threads) | Wasm Threads and `SharedArrayBuffer` |
| 89 | [`89-simd`](./89-simd) | SIMD in WebAssembly — Parallel Data Processing |
| 90 | [`90-wasm-component-model`](./90-wasm-component-model) | The Wasm Component Model and WIT |

### Part 10 — Projects & Production

| # | Directory | Title |
|---|-----------|-------|
| 91 | [`91-project-todo-leptos`](./91-project-todo-leptos) | Project: Full-Stack Todo App (Leptos + Axum + SQLite) |
| 92 | [`92-project-realtime-chat`](./92-project-realtime-chat) | Project: Real-Time Chat (WebSockets + Leptos) |
| 93 | [`93-project-markdown-editor`](./93-project-markdown-editor) | Project: Collaborative Markdown Editor |
| 94 | [`94-project-dashboard`](./94-project-dashboard) | Project: Admin Dashboard with Charts |
| 95 | [`95-project-image-processor`](./95-project-image-processor) | Project: Client-Side Image Processor (Wasm Performance) |
| 96 | [`96-ci-cd`](./96-ci-cd) | CI/CD for Rust Wasm Projects (GitHub Actions) |
| 97 | [`97-deploying-to-vercel`](./97-deploying-to-vercel) | Deploying Leptos Apps to Vercel / Cloudflare |
| 98 | [`98-deploying-to-docker`](./98-deploying-to-docker) | Containerizing a Leptos Full-Stack App |
| 99 | [`99-monitoring-production`](./99-monitoring-production) | Monitoring and Observability in Production |
| 100 | [`100-whats-next`](./100-whats-next) | What's Next — Wasm GC, WASI Preview 2, and Beyond |

---

## References

### Official Documentation

| Resource | URL |
|----------|-----|
| WebAssembly Specification | https://webassembly.github.io/spec/ |
| WebAssembly MDN Docs | https://developer.mozilla.org/en-US/docs/WebAssembly |
| Rust Programming Language Book | https://doc.rust-lang.org/book/ |
| Rust and WebAssembly Book | https://rustwasm.github.io/docs/book/ |
| wasm-bindgen Guide | https://rustwasm.github.io/docs/wasm-bindgen/ |
| wasm-pack Documentation | https://rustwasm.github.io/docs/wasm-pack/ |
| web-sys API Reference | https://rustwasm.github.io/wasm-bindgen/api/web_sys/ |
| js-sys API Reference | https://rustwasm.github.io/wasm-bindgen/api/js_sys/ |
| Leptos Book | https://book.leptos.dev/ |
| Leptos API Reference | https://docs.rs/leptos/latest/leptos/ |
| leptos_router Docs | https://docs.rs/leptos_router/latest/leptos_router/ |
| cargo-leptos | https://github.com/leptos-rs/cargo-leptos |
| Trunk Documentation | https://trunkrs.dev/ |

### Specifications & Standards

| Resource | URL |
|----------|-----|
| WebAssembly Core Spec | https://www.w3.org/TR/wasm-core-2/ |
| WASI (WebAssembly System Interface) | https://wasi.dev/ |
| Wasm Component Model | https://component-model.bytecodealliance.org/ |
| WIT (Wasm Interface Type) | https://github.com/WebAssembly/component-model/blob/main/design/mvp/WIT.md |

### Tooling

| Tool | Description | URL |
|------|-------------|-----|
| `rustup` | Rust toolchain installer | https://rustup.rs/ |
| `wasm-pack` | Build, test, publish Rust Wasm | https://rustwasm.github.io/wasm-pack/ |
| `wasm-bindgen` | Rust ↔ JS interop | https://github.com/rustwasm/wasm-bindgen |
| `wasm-opt` | Wasm binary optimizer (Binaryen) | https://github.com/WebAssembly/binaryen |
| `trunk` | Wasm web app bundler | https://trunkrs.dev/ |
| `cargo-leptos` | Leptos project CLI | https://github.com/leptos-rs/cargo-leptos |
| `wasm-bindgen-test` | Test runner for Wasm | https://rustwasm.github.io/docs/wasm-bindgen/wasm-bindgen-test/ |
| `twiggy` | Wasm binary size profiler | https://rustwasm.github.io/twiggy/ |
| `wasm2wat` / `wat2wasm` | Wasm ↔ WAT converter (WABT) | https://github.com/WebAssembly/wabt |
| `wasmtime` | Standalone Wasm runtime | https://wasmtime.dev/ |

### Crates (Rust Packages)

| Crate | Purpose | URL |
|-------|---------|-----|
| `wasm-bindgen` | Rust–JS interoperability | https://crates.io/crates/wasm-bindgen |
| `wasm-bindgen-futures` | Bridge JS Promises to Rust Futures | https://crates.io/crates/wasm-bindgen-futures |
| `web-sys` | Bindings to Web APIs | https://crates.io/crates/web-sys |
| `js-sys` | Bindings to JS built-in objects | https://crates.io/crates/js-sys |
| `leptos` | Reactive full-stack framework | https://crates.io/crates/leptos |
| `leptos_router` | Routing for Leptos | https://crates.io/crates/leptos_router |
| `leptos_meta` | `<head>` management for Leptos | https://crates.io/crates/leptos_meta |
| `leptos_axum` | Axum integration for Leptos SSR | https://crates.io/crates/leptos_axum |
| `leptos_actix` | Actix-Web integration for Leptos SSR | https://crates.io/crates/leptos_actix |
| `serde` | Serialization / deserialization | https://crates.io/crates/serde |
| `serde-wasm-bindgen` | Serde ↔ JsValue bridge | https://crates.io/crates/serde-wasm-bindgen |
| `gloo` | Convenience wrappers for Web APIs | https://crates.io/crates/gloo |
| `console_error_panic_hook` | Better panic messages in console | https://crates.io/crates/console_error_panic_hook |
| `console_log` | `log` crate backend for browser console | https://crates.io/crates/console_log |
| `reqwest` | HTTP client (works in Wasm) | https://crates.io/crates/reqwest |
| `sqlx` | Async SQL toolkit (server-side) | https://crates.io/crates/sqlx |
| `tokio` | Async runtime (server-side) | https://crates.io/crates/tokio |

### Books & Long-Form Resources

| Resource | Author/Publisher | URL |
|----------|-----------------|-----|
| *Rust and WebAssembly* | The Rust Wasm Working Group | https://rustwasm.github.io/docs/book/ |
| *Programming WebAssembly with Rust* | Kevin Hoffman (Pragmatic) | https://pragprog.com/titles/khrust/programming-webassembly-with-rust/ |
| *The Art of WebAssembly* | Rick Battagline (No Starch) | https://nostarch.com/art-webassembly |
| *WebAssembly: The Definitive Guide* | Brian Sletten (O'Reilly) | https://www.oreilly.com/library/view/webassembly-the-definitive/9781492089834/ |

### Community & Learning

| Resource | URL |
|----------|-----|
| Leptos Discord | https://discord.gg/leptos |
| Rust Wasm Working Group | https://rustwasm.github.io/ |
| This Week in Rust | https://this-week-in-rust.org/ |
| Awesome Leptos (curated list) | https://github.com/leptos-rs/awesome-leptos |
| WebAssembly Summit (talks) | https://webassembly-summit.org/ |
| Rust Users Forum | https://users.rust-lang.org/ |
| r/rust | https://reddit.com/r/rust |

---

<sub>Series maintained by JawaraCloud R&D. Framework version target: Leptos 0.7+.</sub>
