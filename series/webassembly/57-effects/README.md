# 57 — Effects: Reacting to Signal Changes

> **Type:** Explanation + How-To

## What is an effect?

An **effect** is a function that runs in a reactive context — it runs *now*, and then re-runs automatically whenever any signal it reads changes.

Use effects for **side effects**: logging, saving to localStorage, syncing with external systems, or any work that should happen in response to state changes but isn't part of the view.

```rust
use leptos::*;

let (count, set_count) = create_signal(0);

// Runs now, and every time `count` changes
create_effect(move |_| {
    log::info!("Count changed to: {}", count.get());
});
```

## create_effect

```rust
create_effect(move |prev_value| {
    // Read any signals — they become tracked dependencies
    let n = count.get();
    let name = name.get();

    // Do side effects
    if n > 100 {
        log::warn!("Count exceeded 100");
    }

    // Optionally return a value (accessible as `prev_value` next run)
    n
});
```

The effect re-runs whenever `count` or `name` changes.

## The `|prev|` parameter

Like memos, effects receive the previous return value:

```rust
create_effect(move |prev| {
    let current = count.get();
    if let Some(prev_count) = prev {
        if current > prev_count {
            log::info!("Count went up: {} → {}", prev_count, current);
        }
    }
    current  // returned, passed as `prev` next run
});
```

## Common use cases

### Syncing to localStorage

```rust
let (settings, set_settings) = create_signal(Settings::default());

create_effect(move |_| {
    let json = serde_json::to_string(&settings.get()).unwrap();
    gloo::storage::LocalStorage::set("settings", json).unwrap();
});
```

`create_effect` fires on the first run (initial save) and on every settings change.

### Logging

```rust
create_effect(move |_| {
    log::debug!("Current user: {:?}", current_user.get());
});
```

### Syncing scroll position

```rust
let (selected_id, _) = create_signal(0u32);

create_effect(move |_| {
    let id = selected_id.get();
    if let Some(el) = document().get_element_by_id(&format!("item-{}", id)) {
        el.scroll_into_view();
    }
});
```

### Imperatively setting properties effects can't do declaratively

```rust
let (focus_field, _) = create_signal(false);

create_effect(move |_| {
    if focus_field.get() {
        if let Some(el) = document().get_element_by_id("search-input") {
            el.dyn_into::<web_sys::HtmlElement>().unwrap().focus().unwrap();
        }
    }
});
```

## Effects vs. derived signals

| | `create_effect` | `create_memo` / closure |
|:|:---------------|:----------------------|
| Purpose | Side effects | Derived values |
| Returns | `()` (or cached prev) | A reactive value |
| Re-runs when | Source signals change | Source signals change |
| Subscribable | ❌ | ✅ (other effects/views track it) |

Rule: **if you're computing a value for display, use a signal or memo. If you're doing work in response to a change (write to DB, focus, log), use an effect.**

## Cleanup in effects

```rust
create_effect(move |_| {
    let interval = gloo::timers::callback::Interval::new(1000, move || {
        set_count.update(|n| *n += 1);
    });

    // Return the handle — Leptos will drop it before the effect re-runs
    // (gloo::Interval's Drop impl clears the interval)
    interval
});
```

Leptos drops the previous effect's return value before running the next iteration — use this for cleanup (clear timers, unsubscribe, close connections).
