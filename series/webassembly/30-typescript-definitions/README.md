# 30 — Generating TypeScript Definitions from Rust

> **Type:** How-To + Reference

## Why TypeScript definitions?

When you publish a Wasm library for consumption by TypeScript projects (React, Next.js, etc.), you want full type safety. `wasm-pack` automatically generates `.d.ts` files from your `#[wasm_bindgen]` annotations.

## How it works

`wasm-pack build` produces `pkg/my_crate.d.ts` automatically. No extra configuration needed.

## Example: from Rust to TypeScript

**Rust:**
```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct Point {
    x: f64,
    y: f64,
}

#[wasm_bindgen]
impl Point {
    #[wasm_bindgen(constructor)]
    pub fn new(x: f64, y: f64) -> Point {
        Point { x, y }
    }

    #[wasm_bindgen(getter)]
    pub fn x(&self) -> f64 { self.x }

    #[wasm_bindgen(getter)]
    pub fn y(&self) -> f64 { self.y }

    pub fn distance_to(&self, other: &Point) -> f64 {
        ((self.x - other.x).powi(2) + (self.y - other.y).powi(2)).sqrt()
    }

    pub fn scale(&mut self, factor: f64) {
        self.x *= factor;
        self.y *= factor;
    }
}

#[wasm_bindgen]
pub fn origin() -> Point {
    Point::new(0.0, 0.0)
}
```

**Generated `pkg/my_crate.d.ts`:**
```typescript
export class Point {
    free(): void;
    constructor(x: number, y: number);
    distance_to(other: Point): number;
    scale(factor: number): void;
    readonly x: number;
    readonly y: number;
}

export function origin(): Point;

export type InitInput = RequestInfo | URL | Response | BufferSource | WebAssembly.Module;

export interface InitOutput {
    readonly memory: WebAssembly.Memory;
    // ... internal exports
}

export default function init(input?: InitInput): Promise<InitOutput>;
```

## Adding JSDoc comments to generated types

Add `///` doc comments to your Rust items — they appear in the generated `.d.ts`:

```rust
/// Represents a 2D point in Cartesian space.
#[wasm_bindgen]
pub struct Point { ... }

impl Point {
    /// Calculates the Euclidean distance to another point.
    pub fn distance_to(&self, other: &Point) -> f64 { ... }
}
```

Result in TypeScript:
```typescript
/** Represents a 2D point in Cartesian space. */
export class Point {
    /** Calculates the Euclidean distance to another point. */
    distance_to(other: Point): number;
}
```

## Type mapping reference

| Rust type | TypeScript type |
|-----------|----------------|
| `i8`, `i16`, `i32`, `u8`, `u16`, `u32` | `number` |
| `i64`, `u64` | `bigint` |
| `f32`, `f64` | `number` |
| `bool` | `boolean` |
| `String`, `&str` | `string` |
| `Option<T>` | `T \| undefined` |
| `Result<T, E>` | `T` (throws on Err) |
| `Vec<u8>` | `Uint8Array` |
| `JsValue` | `any` |
| Exported `struct Foo` | `Foo` (class) |

## Consuming in a React/TypeScript project

```typescript
import init, { Point, origin } from './wasm-pkg/my_crate';

async function main() {
    await init();
    const p = new Point(3.0, 4.0);
    const o = origin();
    console.log(p.distance_to(o)); // 5.0
    p.free();
    o.free();
}
```
