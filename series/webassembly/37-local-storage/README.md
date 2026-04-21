# 37 — Reading and Writing to Local Storage

> **Type:** How-To

## Setup

```toml
[dependencies.web-sys]
version = "0.3"
features = ["Window", "Storage"]
```

## Getting the storage object

```rust
use web_sys::Storage;

fn local_storage() -> Storage {
    web_sys::window()
        .unwrap()
        .local_storage()
        .unwrap()
        .unwrap()
}

fn session_storage() -> Storage {
    web_sys::window()
        .unwrap()
        .session_storage()
        .unwrap()
        .unwrap()
}
```

`localStorage` persists across browser sessions. `sessionStorage` is cleared when the tab is closed.

## Basic get / set / remove

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn save_name(name: &str) {
    local_storage().set_item("user_name", name).unwrap();
}

#[wasm_bindgen]
pub fn load_name() -> Option<String> {
    local_storage().get_item("user_name").unwrap()
}

#[wasm_bindgen]
pub fn delete_name() {
    local_storage().remove_item("user_name").unwrap();
}

#[wasm_bindgen]
pub fn clear_all() {
    local_storage().clear().unwrap();
}
```

## Storing serialized structs (JSON)

```rust
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct Settings {
    pub theme: String,
    pub font_size: u32,
    pub notifications: bool,
}

pub fn save_settings(settings: &Settings) {
    let json = serde_json::to_string(settings).unwrap();
    local_storage().set_item("settings", &json).unwrap();
}

pub fn load_settings() -> Settings {
    match local_storage().get_item("settings").unwrap() {
        Some(json) => serde_json::from_str(&json).unwrap_or_default(),
        None => Settings {
            theme: "dark".into(),
            font_size: 16,
            notifications: true,
        },
    }
}
```

## Iterating all entries

```rust
pub fn list_all_keys() -> Vec<String> {
    let storage = local_storage();
    let length = storage.length().unwrap();
    (0..length)
        .filter_map(|i| storage.key(i).unwrap())
        .collect()
}
```

## Listening to storage changes (cross-tab)

The `storage` event fires when *another tab* modifies localStorage:

```rust
use web_sys::StorageEvent;

let handler = Closure::wrap(Box::new(move |event: StorageEvent| {
    if let Some(key) = event.key() {
        web_sys::console::log_1(
            &format!("Storage changed: key={}", key).into()
        );
    }
}) as Box<dyn FnMut(StorageEvent)>);

web_sys::window().unwrap()
    .add_event_listener_with_callback("storage", handler.as_ref().unchecked_ref())
    .unwrap();

handler.forget();
```

## Storage limits

| Browser | Limit (approx) |
|---------|---------------|
| Chrome | 5–10 MB per origin |
| Firefox | 5–10 MB per origin |
| Safari | 5 MB per origin |

LocalStorage values are always strings. For binary data, encode as Base64 before storing, or use IndexedDB (larger capacity, async API).

## gloo wrapper (cleaner)

```toml
[dependencies]
gloo = "0.11"
```

```rust
use gloo::storage::{LocalStorage, Storage};

LocalStorage::set("key", &value).unwrap();
let val: MyType = LocalStorage::get("key").unwrap();
LocalStorage::delete("key");
```
