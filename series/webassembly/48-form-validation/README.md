# 48 — Project: Form Validation Library in Wasm

> **Type:** Tutorial + How-To

## What you will build

A reusable form validation library compiled to Wasm. Validation rules run in Rust (fast, type-safe), and results are returned to JavaScript.

This is a great pattern for sharing validation logic between frontend (Wasm) and backend (native Rust) — write once, validate everywhere.

## Cargo.toml

```toml
[package]
name = "form-validator"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib", "rlib"]  # rlib for use in native Rust too

[dependencies]
wasm-bindgen = "0.2"
serde = { version = "1", features = ["derive"] }
serde-wasm-bindgen = "0.6"
regex = "1"
```

## Validation rule types

```rust
use serde::{Deserialize, Serialize};
use wasm_bindgen::prelude::*;

#[derive(Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Rule {
    Required,
    MinLength { min: usize },
    MaxLength { max: usize },
    Email,
    Pattern { regex: String },
    Range { min: f64, max: f64 },
    Custom { message: String }, // placeholder for JS-provided validators
}

#[derive(Serialize, Deserialize)]
pub struct ValidationResult {
    pub field: String,
    pub valid: bool,
    pub errors: Vec<String>,
}
```

## Core validation logic

```rust
pub fn validate_field(field: &str, value: &str, rules: &[Rule]) -> ValidationResult {
    let mut errors = Vec::new();

    for rule in rules {
        match rule {
            Rule::Required => {
                if value.trim().is_empty() {
                    errors.push(format!("{} is required", field));
                }
            }
            Rule::MinLength { min } => {
                if value.len() < *min {
                    errors.push(format!("{} must be at least {} characters", field, min));
                }
            }
            Rule::MaxLength { max } => {
                if value.len() > *max {
                    errors.push(format!("{} must be at most {} characters", field, max));
                }
            }
            Rule::Email => {
                let valid = value.contains('@')
                    && value.contains('.')
                    && value.len() > 3;
                if !valid {
                    errors.push("Invalid email address".to_string());
                }
            }
            Rule::Pattern { regex } => {
                let re = regex::Regex::new(regex).unwrap();
                if !re.is_match(value) {
                    errors.push(format!("{} does not match required pattern", field));
                }
            }
            Rule::Range { min, max } => {
                if let Ok(n) = value.parse::<f64>() {
                    if n < *min || n > *max {
                        errors.push(format!("{} must be between {} and {}", field, min, max));
                    }
                } else {
                    errors.push(format!("{} must be a number", field));
                }
            }
            Rule::Custom { message } => {
                errors.push(message.clone());
            }
        }
    }

    ValidationResult {
        field: field.to_string(),
        valid: errors.is_empty(),
        errors,
    }
}
```

## Exposed Wasm API

```rust
#[wasm_bindgen]
pub fn validate(field: &str, value: &str, rules_js: JsValue) -> JsValue {
    let rules: Vec<Rule> = serde_wasm_bindgen::from_value(rules_js).unwrap();
    let result = validate_field(field, value, &rules);
    serde_wasm_bindgen::to_value(&result).unwrap()
}
```

## JavaScript integration

```javascript
import init, { validate } from './pkg/form_validator.js';
await init();

function validateField(fieldName, value, rules) {
    return validate(fieldName, value, rules);
}

// Usage
document.getElementById('email').addEventListener('input', function() {
    const result = validateField('Email', this.value, [
        { type: 'required' },
        { type: 'email' },
        { type: 'max_length', max: 100 },
    ]);

    const errorEl = document.getElementById('email-error');
    if (!result.valid) {
        errorEl.textContent = result.errors.join(', ');
        errorEl.style.display = 'block';
    } else {
        errorEl.style.display = 'none';
    }
});
```

## Sharing with backend

Because the crate also has `rlib` type, you can use it in a native Rust backend:

```rust
// In your Axum/Actix handler:
use form_validator::{validate_field, Rule};

fn validate_signup(email: &str, password: &str) -> Vec<String> {
    let mut errors = Vec::new();
    let e = validate_field("Email", email, &[Rule::Required, Rule::Email]);
    errors.extend(e.errors);
    let p = validate_field("Password", password, &[
        Rule::Required,
        Rule::MinLength { min: 8 },
    ]);
    errors.extend(p.errors);
    errors
}
```

Write your validation rules once, run them on both frontend (Wasm) and backend (native Rust).
