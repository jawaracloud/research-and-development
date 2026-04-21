# 89 — The WebAssembly Component Model

> **Type:** Explanation

## What is the Component Model?

The **WebAssembly Component Model** is a specification (2024, still evolving) that addresses one of Wasm's core limitations: **language interoperability at the module boundary**.

Today, sharing a Wasm module between languages requires manually writing serialization/deserialization glue code. The Component Model defines a **standard type system and ABI** that lets Wasm modules from any language interoperate without hand-written glue.

## The problem it solves

```
Without Component Model:
 Rust Wasm  ──── exports `add(i32, i32) i32` ────► JavaScript
 Rust Wasm  ──── exports raw pointers for strings ─► JavaScript (manual decode)
 Rust Wasm  ╠══ can't easily call Python Wasm ════► Python Wasm

With Component Model:
 Rust Wasm  ───── exports `add(s32, s32) s32` ─────► Python Wasm  ✅
           ───── string is a "string" type ──────────► Any language ✅
           ════ defined interface (WIT file) ═══════► Portable ✅
```

## WIT: WebAssembly Interface Types

WIT (Wasm Interface Types) is an IDL for defining component interfaces:

```wit
// calculator.wit
package my:calculator@1.0.0;

world calculator {
    export add: func(a: s32, b: s32) -> s32;
    export multiply: func(a: f64, b: f64) -> f64;
    export format-result: func(val: f64, precision: u8) -> string;
}
```

WIT supports rich types:
```wit
record user {
    id: u64,
    name: string,
    email: string,
    created-at: u64,
}

variant status {
    pending,
    active,
    banned(string),  // with payload
}

interface users {
    get-user: func(id: u64) -> option<user>;
    list-users: func(filter: option<status>) -> list<user>;
    update-email: func(id: u64, email: string) -> result<_, string>;
}
```

## Implementing a WIT interface in Rust

```toml
[dependencies]
wit-bindgen = "0.24"
```

```rust
// Generated from the WIT file
wit_bindgen::generate!({
    world: "calculator",
    path: "calculator.wit",
});

struct CalculatorImpl;

impl Calculator for CalculatorImpl {
    fn add(a: i32, b: i32) -> i32 {
        a + b
    }

    fn multiply(a: f64, b: f64) -> f64 {
        a * b
    }

    fn format_result(val: f64, precision: u8) -> String {
        format!("{:.prec$}", val, prec = precision as usize)
    }
}

export!(CalculatorImpl);
```

The `wit-bindgen` macro generates all the ABI glue automatically.

## Using a component from Rust

```wit
// my-app.wit
world my-app {
    import my:calculator/calculator;  // Import the calculator component
    export run: func() -> string;
}
```

```rust
wit_bindgen::generate!({ world: "my-app", path: "my-app.wit" });

struct MyApp;

impl MyApp for MyApp {
    fn run() -> String {
        let result = my::calculator::calculator::add(3, 4);
        format!("3 + 4 = {}", result)
    }
}
```

The component model handles all memory management and type conversions.

## WASI and Components

**WASI (WebAssembly System Interface)** defines standard I/O using the Component Model. WASI Preview 2 (2024) is the stable interface for:
- Filesystem access
- Network sockets
- Random number generation
- Clocks and timestamps

```wit
// WASI preview 2 uses WIT
world wasi-command {
    import wasi:cli/stdin;
    import wasi:cli/stdout;
    import wasi:filesystem/preopens;
    export wasi:cli/run;
}
```

## When will this matter for Leptos developers?

The Component Model is currently most relevant for:
- **Plugin systems** — load user-provided Wasm components safely.
- **Edge computing** — Cloudflare Workers, Fastly Compute.
- **Cross-language microservices** — Rust backend calling Python ML component.

For browser Leptos apps (2024), `wasm-bindgen` remains the primary tool. As the Component Model matures, it may replace `wasm-bindgen` entirely.

## Tools in the ecosystem

- `wit-bindgen` — generate language bindings from WIT files.
- `wasmtime` — runtime with Component Model support.
- `jco` — JavaScript Component Model toolchain.
- `cargo-component` — `cargo-like` CLI for building components.
