# 17 — Dynamic Text: Counters, Timers, Live Updates

> **Type:** How-To

## What you're testing

Counter increments: click 5 times verify count=5. toHaveText with regex for live values.

## Setup

```bash
npm run serve   # starts test app on http://localhost:3000
```

## Test cases

### ✅ Positive tests

| # | Scenario | Expected result |
|---|----------|-----------------|
| 1 | Normal happy-path interaction | Component responds correctly |
| 2 | Edge value / boundary input | Accepted and handled gracefully |
| 3 | Keyboard-only interaction | Works without mouse |

### ❌ Negative tests

| # | Scenario | Expected result |
|---|----------|-----------------|
| 1 | Required field left empty | Validation error shown |
| 2 | Invalid / out-of-range input | Error message appears |
| 3 | Interaction while disabled | No action, no crash |

## Implementation

```typescript
import { test, expect } from '@playwright/test';

test.describe('17 — Dynamic Text: Counters, Timers, Live Updates', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000/pages/buttons.html');
  });

  // ✅ Positive
  test('happy path interaction works', async ({ page }) => {
    const el = page.getByTestId('/* your selector */');
    await expect(el).toBeVisible();
    await el.click();
    await expect(page.getByTestId('/* result */')).toBeVisible();
  });

  // ❌ Negative
  test('disabled state prevents interaction', async ({ page }) => {
    const el = page.getByRole('button', { name: '/* name */', disabled: true });
    await expect(el).toBeDisabled();
  });
});
```

## Key assertions

| Assertion | What it verifies |
|-----------|------------------|
| `toBeVisible()` | Element is in the DOM and not hidden |
| `toBeEnabled()` | Element is interactable |
| `toHaveText()` | Text content matches |
| `toBeDisabled()` | Element cannot be interacted with |
