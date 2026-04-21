# 04 — Selectors: CSS, Text, Role, data-testid

> **Type:** How-To + Reference

## Why selectors matter

A brittle selector breaks your test when a developer refactors HTML. A robust selector survives restructuring because it targets **what a user sees and interacts with**, not how the DOM is arranged.

## Selector priority (best → worst)

| Priority | Method | Reason |
|----------|--------|--------|
| ✅ Best | `getByRole()` | Mirrors how screen readers find elements |
| ✅ Best | `getByTestId()` | Stable, explicit, not tied to visual appearance |
| ✅ Good | `getByText()` | What the user reads |
| ✅ Good | `getByLabel()` | Form inputs described by their label |
| ✅ Good | `getByPlaceholder()` | Inputs with placeholder text |
| ⚠️ Caution | `locator('css=...')` | Can break on class/structure changes |
| ❌ Avoid | XPath | Verbose, fragile, hard to read |

## getByRole — the recommended selector

```typescript
// Buttons
page.getByRole('button', { name: 'Submit' })
page.getByRole('button', { name: /submit/i })  // case insensitive regex

// Links
page.getByRole('link', { name: 'Get started' })

// Headings
page.getByRole('heading', { name: 'Dashboard', level: 1 })

// Inputs (by their label)
page.getByRole('textbox', { name: 'Email' })
page.getByRole('combobox', { name: 'Country' })
page.getByRole('checkbox', { name: 'Remember me' })

// Lists
page.getByRole('listitem').nth(0)
```

ARIA roles reference: `button`, `link`, `textbox`, `checkbox`, `radio`, `combobox`, `listbox`, `option`, `dialog`, `alert`, `tab`, `tabpanel`, `heading`, `img`, `table`, `row`, `cell`.

## getByTestId — your second choice

```typescript
// HTML: <button data-testid="btn-submit">Submit</button>
page.getByTestId('btn-submit')

// Configured in playwright.config.ts:
// use: { testIdAttribute: 'data-testid' }
```

`data-testid` attributes are invisible to users and don't change with visual redesigns. Add them to every interactive element in your app.

## getByText — for readable content

```typescript
page.getByText('Welcome back')         // exact match
page.getByText('Welcome', { exact: false })  // partial match
page.getByText(/welcome/i)             // regex
```

## getByLabel — for form inputs

```typescript
// HTML: <label for="email">Email</label><input id="email" />
page.getByLabel('Email')
```

## CSS selectors — when you need them

```typescript
page.locator('[data-testid="btn-submit"]')     // attribute
page.locator('.btn.btn-primary')               // class combo
page.locator('button:nth-child(2)')            // positional
page.locator('form > button[type="submit"]')   // structural
```

## Chaining and filtering

```typescript
// Find a button inside a specific card
page.getByTestId('card-123').getByRole('button', { name: 'Edit' })

// Filter a list to visible items only
page.getByRole('listitem').filter({ hasText: 'active' })

// Nth match
page.getByRole('row').nth(2)           // 0-indexed
page.getByRole('row').last()
page.getByRole('row').first()
```

## Reference: selector cheatsheet (for the test app)

| Element | Recommended selector |
|---------|----------------------|
| Primary button | `page.getByTestId('btn-primary')` |
| Disabled button | `page.getByRole('button', { name: 'Disabled' })` |
| Username input | `page.getByTestId('input-username')` |
| Country select | `page.getByTestId('select-country')` |
| Submit button in form | `page.getByTestId('signup-submit')` |
| Tab "Settings" | `page.getByRole('tab', { name: 'Settings' })` |
| Modal title | `page.getByTestId('modal-title')` |
