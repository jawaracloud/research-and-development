# 83 — Testing Leptos: Unit, Integration, and E2E

> **Type:** How-To + Tutorial

## Three levels of testing

| Level | What you test | How |
|-------|--------------|-----|
| Unit | Pure Rust functions | `cargo test` |
| Integration | Components in a headless browser | `wasm-bindgen-test` |
| End-to-end | Full user flows | Playwright / Selenium |

## Unit tests (server-only code)

Server functions and business logic compile to native Rust — test them with `cargo test`:

```rust
// src/validation.rs
pub fn validate_email(email: &str) -> bool {
    email.contains('@') && email.contains('.') && email.len() > 3
}

pub fn validate_password(password: &str) -> Vec<String> {
    let mut errors = vec![];
    if password.len() < 8 { errors.push("Password too short".into()); }
    if !password.chars().any(|c| c.is_numeric()) { errors.push("Must contain a digit".into()); }
    errors
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_email() {
        assert!(validate_email("user@example.com"));
    }

    #[test]
    fn test_invalid_email() {
        assert!(!validate_email("notanemail"));
        assert!(!validate_email("@no-local.com"));
    }

    #[test]
    fn test_password_validation() {
        let errors = validate_password("short");
        assert!(errors.iter().any(|e| e.contains("too short")));
        
        let errors = validate_password("longpassword");
        assert!(errors.iter().any(|e| e.contains("digit")));
        
        let errors = validate_password("Valid1Password");
        assert!(errors.is_empty());
    }
}
```

Run with: `cargo test --features ssr`

## Integration tests with wasm-bindgen-test

These run in a headless browser (Node.js or Chromium):

```toml
[dev-dependencies]
wasm-bindgen-test = "0.3"
```

```rust
// tests/dom_tests.rs
use wasm_bindgen_test::*;
wasm_bindgen_test_configure!(run_in_browser);

use wasm_bindgen::JsCast;
use web_sys::HtmlInputElement;

#[wasm_bindgen_test]
fn test_dom_manipulation() {
    let doc = web_sys::window().unwrap().document().unwrap();
    let input = doc.create_element("input").unwrap()
        .dyn_into::<HtmlInputElement>().unwrap();
    
    input.set_value("test value");
    assert_eq!(input.value(), "test value");
}

#[wasm_bindgen_test]
async fn test_async_function() {
    let result = my_async_wasm_function().await;
    assert!(result.is_ok());
}
```

Run with: `wasm-pack test --headless --firefox` or `--chrome`

## Testing Leptos components

```rust
use wasm_bindgen_test::*;
use leptos::*;

#[wasm_bindgen_test]
fn test_counter_component() {
    mount_to_body(|| view! {
        <Counter initial_value=5 />
    });
    
    let doc = web_sys::window().unwrap().document().unwrap();
    
    // Check initial render
    let display = doc.get_element_by_id("count-display").unwrap();
    assert_eq!(display.text_content().unwrap(), "5");
    
    // Click increment button
    doc.get_element_by_id("increment-btn").unwrap()
        .dyn_into::<web_sys::HtmlElement>().unwrap()
        .click();
    
    // Check updated value
    assert_eq!(display.text_content().unwrap(), "6");
}
```

## End-to-end with Playwright

```bash
npm install -D @playwright/test
npx playwright install
```

`tests/e2e/todo.spec.ts`:
```typescript
import { test, expect } from '@playwright/test';

test('can add and complete a todo', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByRole('heading', { name: 'My Todos' })).toBeVisible();
    
    // Add a todo
    const input = page.getByPlaceholder('Add a todo...');
    await input.fill('Write tests');
    await input.press('Enter');
    
    // Check it appears
    await expect(page.getByText('Write tests')).toBeVisible();
    
    // Complete it
    await page.getByLabel('Write tests').check();
    await expect(page.getByText('Write tests')).toHaveClass(/completed/);
});

test('can filter todos', async ({ page }) => {
    await page.goto('/');
    await page.getByText('Active').click();
    // Only uncompleted items should show
});
```

`playwright.config.ts`:
```typescript
import { defineConfig } from '@playwright/test';
export default defineConfig({
    testDir: './tests/e2e',
    webServer: {
        command: 'cargo leptos serve',
        port: 3000,
        timeout: 60000,
    },
});
```

Run: `npx playwright test`

## cargo-leptos built-in test command

```bash
cargo leptos test  # runs both unit tests and wasm-bindgen tests
```
