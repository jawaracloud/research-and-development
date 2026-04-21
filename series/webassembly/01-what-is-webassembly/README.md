# 01 — What Is WebAssembly and Why Does It Matter?

> **Type:** Explanation

## What is WebAssembly?

WebAssembly (abbreviated **Wasm**) is a binary instruction format for a stack-based virtual machine. It is designed as a portable compilation target for programming languages like C, C++, Rust, and Go, enabling deployment on the web for client and server applications.

The key word is *target*. You don't usually write Wasm by hand — you write code in a high-level language and a compiler turns it into Wasm.

## Why was it created?

JavaScript is the only language that runs natively in the browser. Over time, people needed more performance — for games, video editing, 3D graphics, compilers, and image processing. Various attempts were made (NaCl, asm.js), but they were either non-portable or too limited.

WebAssembly was designed from the ground up by a collaboration of all major browser vendors (Google, Mozilla, Apple, Microsoft) as a proper, safe, fast, and portable binary format.

## Four design goals

1. **Fast** — Near-native execution speed. Wasm is a compact binary format that browsers can decode and compile to machine code quickly.
2. **Safe** — Wasm runs inside a memory-safe sandbox. It cannot access memory outside its own linear memory region.
3. **Open & debuggable** — There is a human-readable text representation (`.wat`) and browsers expose it in DevTools.
4. **Part of the web platform** — Wasm integrates with JavaScript and the browser's existing APIs rather than replacing them.

## Where Wasm runs

- **Browser** — Chrome, Firefox, Safari, Edge all support Wasm natively.
- **Server / Edge** — Via runtimes like Wasmtime, WasmEdge, WASI on Cloudflare Workers, Fastly Compute@Edge.
- **Embedded / IoT** — Wasm is increasingly used as a universal plugin format.

## Why Rust?

Rust is arguably the *best* language for Wasm today:
- It has **no garbage collector**, so there is no GC pause and the runtime overhead is minimal.
- It produces **tiny binaries** compared to Go or JVM languages.
- It has a **first-class Wasm toolchain** (`wasm-pack`, `wasm-bindgen`, `trunk`).
- The Rust community has heavily invested in Wasm since 2018.

## Mental model

Think of Wasm as a **universal bytecode** — like JVM bytecode, but for the browser (and beyond). Your Rust code compiles to this bytecode, the browser downloads and JIT-compiles it to native machine code, and it runs.

```
Rust source (.rs)
      │
      ▼  rustc + wasm32-unknown-unknown target
WebAssembly binary (.wasm)
      │
      ▼  browser JS engine (V8, SpiderMonkey, JSC)
Native machine code (executed at near-native speed)
```
