# 07 — How Browsers Load and Run Wasm Modules

> **Type:** Explanation

## The loading pipeline

When a browser encounters a `.wasm` file, it goes through this pipeline:

```
Network  →  Decode  →  Validate  →  Compile  →  Instantiate  →  Run
```

1. **Fetch** — Browser downloads the `.wasm` file over HTTP.
2. **Decode** — The binary is parsed into an internal representation.
3. **Validate** — The runtime checks types, control flow, and memory accesses are all sound. A validation failure throws an error — no invalid Wasm ever runs.
4. **Compile** — The JIT compiler converts Wasm instructions to native machine code.
5. **Instantiate** — A `WebAssembly.Instance` is created, connecting imports (JS functions, memory).
6. **Run** — Exported Wasm functions can now be called from JavaScript.

## JavaScript APIs

```javascript
// Streaming compile + instantiate (most efficient)
const result = await WebAssembly.instantiateStreaming(
  fetch("module.wasm"),
  importObject  // { env: { log: console.log, ... } }
);
const { memory, myFunction } = result.instance.exports;

// Or, if you already have the bytes:
const bytes = await fetch("module.wasm").then(r => r.arrayBuffer());
const { instance } = await WebAssembly.instantiate(bytes, importObject);
```

## Key JavaScript types

| Type | Description |
|------|-------------|
| `WebAssembly.Module` | Compiled, portable module (can be stored in IndexedDB, shared with Workers) |
| `WebAssembly.Instance` | A live running instantiation of a Module |
| `WebAssembly.Memory` | Wrapper around the Wasm linear memory (`ArrayBuffer`) |
| `WebAssembly.Table` | Indirect call table (function pointers) |

## Import object

Wasm modules can import values from the host. You provide these via the import object:

```javascript
const importObject = {
  env: {
    // If Wasm imports (import "env" "log" ...)
    log: (ptr, len) => {
      const bytes = new Uint8Array(memory.buffer, ptr, len);
      console.log(new TextDecoder().decode(bytes));
    },
  },
};
```

## How `wasm-bindgen` and `wasm-pack` handle this

When you use `wasm-pack build`, it generates:
- `pkg/module_bg.wasm` — the compiled `.wasm` file.
- `pkg/module.js` — JavaScript glue code that handles the instantiation, import object setup, and binding TypeScript types.
- `pkg/module.d.ts` — TypeScript type declarations.

You just `import` the JS glue and never deal with the low-level API directly.

## Streaming compilation

Always use `WebAssembly.instantiateStreaming()` — it compiles while downloading and is far faster than downloading first and then compiling. The server must serve the `.wasm` file with `Content-Type: application/wasm`.
