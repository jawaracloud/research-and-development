# 84 — Internationalization (i18n) with Leptos

> **Type:** How-To

## Approaches to i18n

| Approach | Crate | Trade-offs |
|----------|-------|-----------|
| Compile-time translations | `leptos-fluent` | Type-safe, fast, larger binary |
| Runtime translations | `fluent-bundle` (raw) | Flexible, can load translations lazily |
| Simple key-value lookup | Custom | Easy to start, limited features |

## Simple i18n with a context store

Start simple: a `HashMap<String, String>` in context:

```rust
use std::collections::HashMap;
use leptos::*;

type Translations = HashMap<String, String>;

fn load_translations(locale: &str) -> Translations {
    match locale {
        "id" => HashMap::from([
            ("hello".to_string(), "Halo".to_string()),
            ("welcome".to_string(), "Selamat datang".to_string()),
            ("add_todo".to_string(), "Tambah tugas".to_string()),
        ]),
        _ => HashMap::from([
            ("hello".to_string(), "Hello".to_string()),
            ("welcome".to_string(), "Welcome".to_string()),
            ("add_todo".to_string(), "Add todo".to_string()),
        ]),
    }
}

#[derive(Clone, Copy)]
struct I18n {
    pub locale: RwSignal<String>,
}

impl I18n {
    fn t(&self, key: &str) -> String {
        // In real usage, cache translations in a Memo
        let locale = self.locale.get();
        let translations = load_translations(&locale);
        translations.get(key).cloned().unwrap_or(key.to_string())
    }
}

#[component]
fn App() -> impl IntoView {
    let i18n = I18n { locale: create_rw_signal("en".to_string()) };
    provide_context(i18n);

    view! {
        <LanguageSwitcher />
        <HomePage />
    }
}

#[component]
fn LanguageSwitcher() -> impl IntoView {
    let i18n = use_context::<I18n>().expect("i18n context");
    view! {
        <button on:click=move |_| i18n.locale.set("en".into())>"EN"</button>
        <button on:click=move |_| i18n.locale.set("id".into())>"ID"</button>
    }
}

#[component]
fn HomePage() -> impl IntoView {
    let i18n = use_context::<I18n>().expect("i18n context");
    view! {
        <h1>{move || i18n.t("hello")}</h1>
        <p>{move || i18n.t("welcome")}</p>
    }
}
```

## Using leptos-fluent

For production apps, `leptos-fluent` provides compile-time checked keys:

```toml
[dependencies]
leptos-fluent = "0.1"
fluent-templates = "0.9"
```

`locales/en-US/main.ftl`:
```
hello = Hello, { $name }!
todos-count = { $count } { $count ->
    [one] todo
    *[other] todos
}
```

`locales/id-ID/main.ftl`:
```
hello = Halo, { $name }!
todos-count = { $count } tugas
```

```rust
use leptos_fluent::{leptos_fluent, tr, move_tr};

leptos_fluent! {
    translations: [TRANSLATIONS],
    locales: "./locales",
    default_language: "en-US",
}

// In components:
view! {
    <p>{move_tr!("hello", { "name" => "Alice" })}</p>
    <p>{move_tr!("todos-count", { "count" => 5 })}</p>
}
```

## Persisting locale preference

```rust
create_effect(move |_| {
    let locale = i18n.locale.get();
    gloo::storage::LocalStorage::set("locale", &locale).ok();
});

// On app init, restore:
fn get_stored_locale() -> String {
    gloo::storage::LocalStorage::get("locale")
        .unwrap_or_else(|_| "en".to_string())
}
```

## Detecting browser locale

```rust
fn browser_locale() -> String {
    web_sys::window()
        .and_then(|w| w.navigator().language())
        .map(|l| l.split('-').next().unwrap_or("en").to_string())
        .unwrap_or_else(|| "en".to_string())
}
```

## RTL language support

```rust
create_effect(move |_| {
    let locale = i18n.locale.get();
    let dir = if ["ar", "he", "fa", "ur"].contains(&locale.as_str()) {
        "rtl"
    } else {
        "ltr"
    };
    
    document().document_element().unwrap()
        .set_attribute("dir", dir).unwrap();
});
```
