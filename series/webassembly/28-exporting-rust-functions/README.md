# 28 — Exporting Rust Functions for JavaScript Consumption

> **Type:** How-To + Reference

## What gets exported

When you mark a Rust item with `#[wasm_bindgen]`, it becomes accessible from JavaScript. This works for:
- Free functions
- Structs and their methods
- Enums (simple integer enums)
- Static methods

## Free functions

```rust
use wasm_bindgen::prelude::*;

/// A function that appears as a named export in the generated JS
#[wasm_bindgen]
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[wasm_bindgen]
pub fn fibonacci(n: u32) -> u64 {
    if n <= 1 { return n as u64; }
    let (mut a, mut b) = (0u64, 1u64);
    for _ in 2..=n { let c = a + b; a = b; b = c; }
    b
}
```

JavaScript:
```javascript
import init, { add, fibonacci } from './pkg/my_crate.js';
await init();
console.log(add(3, 4));       // 7
console.log(fibonacci(10));   // 55
```

## Exporting structs (become JS classes)

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct Matrix {
    rows: usize,
    cols: usize,
    data: Vec<f64>,
}

#[wasm_bindgen]
impl Matrix {
    #[wasm_bindgen(constructor)]
    pub fn new(rows: usize, cols: usize) -> Matrix {
        Matrix {
            rows, cols,
            data: vec![0.0; rows * cols],
        }
    }

    pub fn set(&mut self, row: usize, col: usize, val: f64) {
        self.data[row * self.cols + col] = val;
    }

    pub fn get(&self, row: usize, col: usize) -> f64 {
        self.data[row * self.cols + col]
    }

    #[wasm_bindgen(getter)]
    pub fn rows(&self) -> usize { self.rows }

    #[wasm_bindgen(getter)]
    pub fn cols(&self) -> usize { self.cols }
}
```

JavaScript:
```javascript
const m = new Matrix(3, 3);
m.set(0, 0, 1.0);
console.log(m.get(0, 0)); // 1.0
console.log(m.rows);      // 3 (getter, no parentheses)
m.free();  // IMPORTANT: manual memory management
```

## Naming and visibility

| Rule | Detail |
|------|--------|
| `pub fn` + `#[wasm_bindgen]` | Exported to JS |
| `fn` without `pub` | NOT exported |
| `pub fn` without `#[wasm_bindgen]` | Internal Rust (not exported to JS) |
| `#[wasm_bindgen(js_name = "myFn")]` | Export with a different JS name |

## Exporting a start function

A function marked `#[wasm_bindgen(start)]` runs automatically when the Wasm module is initialized:

```rust
#[wasm_bindgen(start)]
pub fn start() {
    console_error_panic_hook::set_once();
    log::info!("Wasm module initialized");
}
```

## TypeScript definitions

`wasm-pack` generates `.d.ts` files automatically. For the Matrix example:

```typescript
export class Matrix {
    constructor(rows: number, cols: number);
    set(row: number, col: number, val: number): void;
    get(row: number, col: number): number;
    readonly rows: number;
    readonly cols: number;
    free(): void;
}
export function add(a: number, b: number): number;
export function fibonacci(n: number): bigint;
```

## Common export gotchas

- Structs with generic parameters cannot be exported.
- Fields containing types that are not `wasm_bindgen`-compatible (like `HashMap`) must be kept private.
- You cannot return references from exported functions — only owned values.
- All exported types must implement `Into<JsValue>` or be a known `wasm-bindgen` type.
