# 10 — Real-World Use Cases for WebAssembly

> **Type:** Explanation

## Where is Wasm being used today?

Wasm is no longer experimental. It ships in millions of production systems. Here is a tour of the real-world use cases that demonstrate why it matters.

## 1. Compute-intensive browser applications

**Image/video editing in the browser:**
- Adobe Photoshop Web — compiled C++ core to Wasm.
- Figma — rendering engine in Wasm for 60fps canvas performance.
- FFmpeg compiled to Wasm for client-side video processing.

**Audio:**
- Web audio plugins (VSTs) compiled from C++ to Wasm.
- Real-time pitch correction, noise cancellation.

**3D and games:**
- Unity and Unreal Engine both export to Wasm via Emscripten.
- 3D molecule viewers, medical imaging tools.

## 2. Porting existing native code

Companies have ported millions of lines of C/C++ code to the browser without rewriting:
- **AutoCAD** — 35 years of C++ code, now runs in the browser.
- **Google Earth** — the desktop C++ client runs in Chrome via Wasm.
- **SQLite** — official `sqlite3.wasm` build for in-browser SQL.

## 3. Cryptography

Cryptographic operations need deterministic, constant-time performance:
- Password hashing (Argon2, bcrypt) — computationally heavy, done in Wasm.
- End-to-end encryption (Signal protocol) in browser-based chat apps.
- Crypto wallet signing (MetaMask, Ledger Web) uses Wasm for key operations.

## 4. Edge computing and serverless

(See also lesson 08)
- Cloudflare Workers processes HTTP requests at the edge with Rust → Wasm.
- Fastly Compute@Edge runs Wasm for sub-millisecond cold starts.
- AI inference at the edge: small ML models compiled to Wasm for real-time classification.

## 5. Plugin systems

- **Envoy proxy** — allows custom filters written as Wasm modules. Plugin authors cannot escape the sandbox.
- **Zellij** (terminal multiplexer) — plugins are Wasm modules.
- **Extism** — universal Wasm plugin framework supporting 13 languages.

## 6. Databases and data processing

- **SingleStore** — user-defined functions in Wasm inside the database.
- **ClickHouse** — Wasm UDFs.
- DuckDB compiles to Wasm for in-browser analytics.

## 7. AI/ML

- Run quantized LLMs in the browser via `llama.wasm`.
- TensorFlow.js and ONNX can offload ops to Wasm (with SIMD) for CPU inference.
- MediaPipe ML solutions compile to Wasm.

## The pattern across all use cases

> "We had performance-critical code that needed to run somewhere we couldn't install native binaries — so we compiled to Wasm."

This captures why Wasm matters: it is the universal solution for **safe, portable, near-native performance**.
