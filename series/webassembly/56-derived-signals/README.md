# 56 — Derived Signals and Memos

> **Type:** Explanation + How-To

## The problem with raw derivations

If you derive values from signals using closures, every subscriber re-computes independently:

```rust
let (count, _) = create_signal(0);

// Both closures read count independently — no sharing
let is_even = move || count.get() % 2 == 0;
let double = move || count.get() * 2;
```

This works but if 50 DOM nodes each call `is_even()`, each call re-reads the signal and re-computes. **Memos** cache the computation and only re-run when dependencies change.

## create_memo

A **memo** is like a `create_signal` that computes its value from other signals, caches it, and only recalculates when its sources change:

```rust
use leptos::*;

let (count, set_count) = create_signal(0);

// Runs once when count changes, caches result
let is_even = create_memo(move |_| count.get() % 2 == 0);
let double = create_memo(move |_| count.get() * 2);

view! {
    <p>"Double: " {double}</p>
    <p>{move || if is_even.get() { "Even" } else { "Odd" }}</p>
}
```

If `count` changes from 1 to 3:
- `is_even` recomputes: `3 % 2 == 0` → `false` (same as before? → no DOM update)
- `double` recomputes: `3 * 2 = 6` → DOM updates

## Memos short-circuit when value is unchanged

Memos implement **equality checking**. If the new computed value equals the old one, downstream subscribers are NOT notified:

```rust
let (count, set_count) = create_signal(0);
let parity = create_memo(move |_| count.get() % 2);
// count: 0 → 2 → 4 → 6: parity stays 0 → dom does NOT update
// count: 0 → 1: parity changes from 0 to 1 → dom updates
```

This is a powerful optimization. Put expensive computations in memos.

## Derived closures vs memos — when to use each

| | `move || expr` | `create_memo(...)` |
|:|:--------------|:------------------|
| Caches result | ❌ re-runs per subscriber | ✅ computed once, shared |
| Short-circuits | ❌ | ✅ (if value unchanged) |
| Overhead | Low (for simple exprs) | Slightly more than a closure |
| Use when | Simple, cheap derivations | Expensive computations, many subscribers |

Rule of thumb: **use a closure for simple transformations, use `create_memo` when the computation is non-trivial or has many subscribers**.

## Composing memos

Memos can depend on other memos:

```rust
let (items, _) = create_signal(vec![1, 2, 3, 4, 5]);
let filter_text = create_rw_signal(String::new());

let filtered = create_memo(move |_| {
    let text = filter_text.get();
    items.get()
        .into_iter()
        .filter(|n| n.to_string().contains(&text))
        .collect::<Vec<_>>()
});

let total = create_memo(move |_| filtered.get().iter().sum::<i32>());
```

The reactive graph:
```
items → filtered → total
filter_text ↗
```

When `filter_text` changes: `filtered` recomputes → if result changes, `total` recomputes → if total changes, DOM updates.

## The `|_prev|` parameter

The closure passed to `create_memo` receives the previous value:

```rust
let rolling_max = create_memo(move |prev: Option<&i32>| {
    let current = source.get();
    match prev {
        None => current,
        Some(&prev_max) => prev_max.max(current),
    }
});
```

This lets you build accumulators that carry previous state.
