# 15 — Hello, Wasm! Your First Rust → Wasm Build

> **Type:** Tutorial

## What you will build

A Rust function that returns a greeting string, compiled to Wasm and called from a plain HTML page — no bundler needed.

## Step 1 — Create the project

```bash
cargo new --lib hello-wasm
cd hello-wasm
```

## Step 2 — Edit Cargo.toml

```toml
[package]
name = "hello-wasm"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
wasm-bindgen = "0.2"
```

## Step 3 — Write the Rust code

`src/lib.rs`:
```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn greet(name: &str) -> String {
    format!("Hello, {}! Welcome to WebAssembly.", name)
}
```

## Step 4 — Build with wasm-pack

```bash
wasm-pack build --target web
```

This creates a `pkg/` directory with:
- `hello_wasm_bg.wasm` — the compiled Wasm binary
- `hello_wasm.js` — JavaScript glue code
- `hello_wasm.d.ts` — TypeScript types

## Step 5 — Create the HTML page

`index.html` (in the project root):
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Hello Wasm</title>
</head>
<body>
  <h1 id="greeting">Loading...</h1>
  <input id="name-input" type="text" placeholder="Enter your name" />
  <button id="greet-btn">Greet</button>

  <script type="module">
    import init, { greet } from './pkg/hello_wasm.js';

    await init();

    document.getElementById('greet-btn').addEventListener('click', () => {
      const name = document.getElementById('name-input').value || 'World';
      document.getElementById('greeting').textContent = greet(name);
    });

    document.getElementById('greeting').textContent = greet('World');
  </script>
</body>
</html>
```

## Step 6 — Serve the page

You need a local server because `import` modules require HTTP (not `file://`):

```bash
# Python (quick option)
python3 -m http.server 8080

# Or install a lightweight server
npx serve .
```

Open http://localhost:8080 — you should see "Hello, World! Welcome to WebAssembly."

## What just happened?

1. `rustc` compiled `src/lib.rs` to `wasm32-unknown-unknown` bytecode.
2. `wasm-bindgen` generated JS glue to handle the string marshalling.
3. The browser downloaded, validated, and JIT-compiled the `.wasm` file.
4. The JS glue called `greet()`, which ran in Wasm and returned a string.

## Checkpoint

- [ ] `pkg/` directory exists after `wasm-pack build`
- [ ] Page loads and displays greeting
- [ ] Clicking the button greets by name
