# 02 — Installing Playwright & Writing Your First Test

> **Type:** Tutorial

## Prerequisites

- Node.js 18+ (22 LTS recommended)
- npm or pnpm

## Step 1: Create a new project

```bash
mkdir my-playwright-project && cd my-playwright-project
npm init playwright@latest
```

The wizard asks:
- TypeScript or JavaScript → **TypeScript**
- Test directory → **tests**
- GitHub Actions workflow → **Yes** (optional)
- Install browsers? → **Yes**

What's created:

```
my-playwright-project/
├── playwright.config.ts    # Configuration
├── tests/
│   └── example.spec.ts     # Sample test
└── package.json
```

## Step 2: Understand the sample test

```typescript
// tests/example.spec.ts
import { test, expect } from '@playwright/test';

test('has title', async ({ page }) => {
  await page.goto('https://playwright.dev/');
  await expect(page).toHaveTitle(/Playwright/);
});

test('get started link', async ({ page }) => {
  await page.goto('https://playwright.dev/');
  await page.getByRole('link', { name: 'Get started' }).click();
  await expect(page.getByRole('heading', { name: 'Installation' })).toBeVisible();
});
```

Key patterns:
- `test(name, async ({ page }) => { ... })` — every test is async.
- `page.goto(url)` — navigate to a URL.
- `page.getByRole()` — locate by ARIA role (preferred selector).
- `expect(locator).toBeVisible()` — assertion with auto-retry.

## Step 3: Write your first test from scratch

Create `tests/test-app.spec.ts`:

```typescript
import { test, expect } from '@playwright/test';

test.describe('Test App Homepage', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate before each test
    await page.goto('http://localhost:3000');
  });

  test('displays the page heading', async ({ page }) => {
    await expect(page.getByRole('heading', { level: 1 })).toContainText('Playwright Test Components');
  });

  test('shows all component navigation cards', async ({ page }) => {
    await expect(page.getByTestId('nav-buttons')).toBeVisible();
    await expect(page.getByTestId('nav-forms')).toBeVisible();
    await expect(page.getByTestId('nav-data-display')).toBeVisible();
  });

  test('navigates to Buttons page when clicked', async ({ page }) => {
    await page.getByTestId('nav-buttons').click();
    await expect(page).toHaveURL(/buttons/);
    await expect(page.getByText('Buttons & Links')).toBeVisible();
  });
});
```

## Step 4: Start the test app and run tests

```bash
# Terminal 1: start test app
npx serve test-app -p 3000

# Terminal 2: run tests
npx playwright test tests/test-app.spec.ts
```

## Step 5: View the HTML report

```bash
npx playwright show-report
```

Opens a browser with a full HTML report: test results, trace, screenshots on failure.

## Step 6: Run in headed mode (see the browser)

```bash
npx playwright test --headed
```

## What you've learned

- Create a Playwright project with `npm init playwright@latest`.
- A test is an `async` function receiving a `page` fixture.
- `page.goto()`, `page.getByRole()`, `expect().toBeVisible()` are the core building blocks.
- Tests output an HTML report you can browse locally.
