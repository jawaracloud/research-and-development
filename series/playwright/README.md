# Web Automation Testing with Playwright — Complete Series

> A structured, 100-lesson journey through UI component testing with **Playwright + TypeScript**. Each lesson focuses on one UI component or pattern, covering both positive and negative test cases.

---

## Introduction

UI automation testing is not just about clicking buttons — it's about understanding how components behave across every state, edge case, and failure mode. This series teaches you to think like a QA engineer by working through real components one at a time.

**Why Playwright?**
- Supports Chromium, Firefox, and WebKit in a single tool.
- Auto-wait: no more `sleep()` calls — Playwright waits for elements to be ready.
- Trace Viewer: replay failed tests as a film strip.
- Native TypeScript support, async/await API, and a powerful Locator model.

Each lesson lives in its own directory with a `README.md` following the **Diátaxis** framework (how-to, tutorial, explanation, or reference — whichever fits best). Each README includes:
- The component under test and how to locate it.
- Positive test cases (expected happy-path behavior).
- Negative test cases (error states, edge cases, boundary values).
- Full TypeScript test code.

**Test app**: All tests run against a bundled static HTML app in `test-app/` — no external dependencies. Start it with `npm run serve`.

---

## 🛠️ Environment Setup

Pick **one** path:

### Option A — VS Code Dev Container (recommended)

Requires: [VS Code](https://code.visualstudio.com) + [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) + Docker Desktop.

1. Clone the repo and open the `playwright-series/` folder in VS Code.
2. Click **"Reopen in Container"** when prompted.
3. Wait ~3 min for the first build (all browsers are pre-installed).
4. The terminal is ready — run `npm test`.

Works identically on **GitHub Codespaces** — click *Code → Open with Codespaces*.

### Option B — Docker Compose (CLI)

```bash
# Build the image once (~3 min, includes all browsers)
docker compose build

# Drop into a shell with all tools
docker compose run --rm dev

# Inside the container:
npm install
npm test
```

### Option C — Local (Playwright installed manually)

```bash
# Install Node.js 22+ first, then:
npm install
npx playwright install --with-deps
npm test
```

### Verify your environment

```bash
npm run verify
# or
bash scripts/verify-env.sh
```

### Run the test app

```bash
npm run serve   # Starts http://localhost:3000
```

---

## Quick Start

```bash
npm run serve &              # start test app in background
npm test                     # run all tests
npx playwright test --ui     # Playwright UI mode (recommended for learning)
npx playwright show-report   # open HTML report after tests
```

---

## Test App Structure

```
test-app/
├── index.html           # Component navigation hub
├── pages/
│   ├── buttons.html     # Lessons 11–20: buttons, links, keyboard
│   ├── forms.html       # Lessons 21–30: inputs, selects, checkboxes, validation
│   ├── advanced-inputs.html  # Lessons 31–40
│   ├── navigation.html  # Lessons 41–50: tabs, modals, accordion, toast
│   ├── data-display.html # Lessons 51–60: tables, empty states
│   ├── interactive.html # Lessons 61–70: drag-drop, carousel
│   ├── auth.html        # Lessons 81–90: login, register, CRUD
│   └── api-mock.html    # Lessons 78–79: network interception
└── assets/
    └── style.css
```

---

## Table of Contents

### Part 1 — Playwright Fundamentals

| # | Topic | Type |
|---|-------|------|
| [01](./01-what-is-playwright/README.md) | What Is Playwright? | Explanation |
| [02](./02-install-first-test/README.md) | Installing Playwright + First Test | Tutorial |
| [03](./03-config-and-structure/README.md) | Test Config and Project Structure | How-To + Reference |
| [04](./04-selectors/README.md) | Selectors: CSS, Text, Role, data-testid | How-To + Reference |
| [05](./05-locator-api/README.md) | Locator API Deep Dive | How-To + Reference |
| [06](./06-assertions/README.md) | Assertions (expect) — Positive & Negative | How-To + Reference |
| [07](./07-test-lifecycle/README.md) | Test Lifecycle: beforeAll, beforeEach, afterEach | How-To |
| [08](./08-screenshots-video/README.md) | Screenshots and Video Recording | How-To |
| [09](./09-debugging/README.md) | Debugging: Trace Viewer, Inspector, --headed | How-To + Tutorial |
| [10](./10-parallel-isolation/README.md) | Parallel Execution and Test Isolation | Explanation + How-To |

### Part 2 — Buttons, Links & Text

| # | Topic | Type |
|---|-------|------|
| [11](./11-basic-buttons/README.md) | Basic Buttons: Click, States, Variants | How-To |
| [12](./12-button-states/README.md) | Button States: Disabled, Loading, Toggle | How-To |
| [13](./13-icon-buttons/README.md) | Icon Buttons and Accessibility Labels | How-To |
| [14](./14-links/README.md) | Links: Internal, External, Download | How-To |
| [15](./15-link-behavior/README.md) | Link Behavior: target=_blank, rel=noopener | How-To |
| [16](./16-text-headings/README.md) | Static Text and Headings Verification | How-To |
| [17](./17-dynamic-text/README.md) | Dynamic Text: Counters, Timers, Live Updates | How-To |
| [18](./18-badges-tags/README.md) | Badges, Tags, and Status Indicators | How-To |
| [19](./19-clipboard/README.md) | Clipboard Copy Buttons | How-To |
| [20](./20-keyboard-shortcuts/README.md) | Keyboard Shortcuts and Hotkeys | How-To |

### Part 3 — Form Components

| # | Topic | Type |
|---|-------|------|
| [21](./21-text-inputs/README.md) | Text Inputs: Type, Clear, Placeholder | How-To |
| [22](./22-input-validation/README.md) | Input Validation: Required, Pattern, Min/Max | How-To |
| [23](./23-password-fields/README.md) | Password Fields: Show/Hide Toggle, Strength Meter | How-To |
| [24](./24-textarea/README.md) | Textarea: Multiline, Character Count | How-To |
| [25](./25-select-dropdown/README.md) | Select Dropdowns (native `<select>`) | How-To |
| [26](./26-custom-dropdown/README.md) | Custom Dropdowns (Searchable, Multi-select) | How-To |
| [27](./27-checkboxes/README.md) | Checkboxes: Single, Group, Indeterminate | How-To |
| [28](./28-radio-buttons/README.md) | Radio Buttons and Radio Groups | How-To |
| [29](./29-form-submission/README.md) | Form Submission: Submit, Reset | How-To |
| [30](./30-form-validation/README.md) | Form Validation Feedback: Inline Errors, Toast | How-To |

### Part 4 — Advanced Input Components

| # | Topic | Type |
|---|-------|------|
| [31](./31-date-picker/README.md) | Date Pickers (Native and Custom) | How-To |
| [32](./32-time-picker/README.md) | Time Pickers and DateTime Inputs | How-To |
| [33](./33-range-slider/README.md) | Range Sliders: Single and Dual-thumb | How-To |
| [34](./34-color-picker/README.md) | Color Pickers | How-To |
| [35](./35-file-upload/README.md) | File Upload: Single, Multiple, Drag-and-Drop | How-To |
| [36](./36-autocomplete/README.md) | Autocomplete / Typeahead Inputs | How-To |
| [37](./37-tag-input/README.md) | Tag Inputs and Token Fields | How-To |
| [38](./38-rich-text/README.md) | Rich Text Editors (contenteditable, WYSIWYG) | How-To |
| [39](./39-otp-input/README.md) | OTP / PIN Input Fields | How-To |
| [40](./40-rating/README.md) | Rating Stars and Emoji Pickers | How-To |

### Part 5 — Navigation & Layout Components

| # | Topic | Type |
|---|-------|------|
| [41](./41-navbar/README.md) | Navigation Bar and Hamburger Menu | How-To |
| [42](./42-sidebar/README.md) | Sidebar and Drawer Components | How-To |
| [43](./43-tabs/README.md) | Tabs and Tab Panels | How-To |
| [44](./44-breadcrumbs/README.md) | Breadcrumbs | How-To |
| [45](./45-pagination/README.md) | Pagination: Page Numbers, Infinite Scroll | How-To |
| [46](./46-modals/README.md) | Modals and Dialogs | How-To |
| [47](./47-confirm-dialogs/README.md) | Confirmation Dialogs (browser alert/confirm) | How-To |
| [48](./48-toast/README.md) | Toast Notifications and Snackbars | How-To |
| [49](./49-accordion/README.md) | Accordion and Collapsible Panels | How-To |
| [50](./50-stepper/README.md) | Stepper / Wizard Multi-Step Forms | How-To + Tutorial |

### Part 6 — Data Display Components

| # | Topic | Type |
|---|-------|------|
| [51](./51-table-basics/README.md) | Tables: Headers, Rows, Cells | How-To |
| [52](./52-table-sorting/README.md) | Table Sorting and Column Ordering | How-To |
| [53](./53-table-filtering/README.md) | Table Filtering and Search | How-To |
| [54](./54-table-pagination/README.md) | Table Pagination | How-To |
| [55](./55-table-selection/README.md) | Table Row Selection and Bulk Actions | How-To |
| [56](./56-cards-lists/README.md) | Data Lists and Card Grids | How-To |
| [57](./57-tree-view/README.md) | Tree View and Nested Lists | How-To |
| [58](./58-timeline/README.md) | Timeline and Activity Feed | How-To |
| [59](./59-charts/README.md) | Charts and Graphs (Canvas-based) | How-To |
| [60](./60-empty-states/README.md) | Empty States, Skeleton Loaders, Spinners | How-To |

### Part 7 — Interactive & Dynamic Components

| # | Topic | Type |
|---|-------|------|
| [61](./61-drag-drop-sort/README.md) | Drag and Drop: Sortable Lists | How-To |
| [62](./62-drag-drop-kanban/README.md) | Drag and Drop: Kanban Board | How-To |
| [63](./63-carousel/README.md) | Image Carousel / Slider | How-To |
| [64](./64-lightbox/README.md) | Image Gallery with Lightbox | How-To |
| [65](./65-tooltips/README.md) | Tooltips and Popovers | How-To |
| [66](./66-context-menu/README.md) | Context Menus (Right-click) | How-To |
| [67](./67-scroll/README.md) | Scroll Behavior: Scroll-to-top, Sticky Headers | How-To |
| [68](./68-infinite-scroll/README.md) | Infinite Scroll / Lazy Load Content | How-To |
| [69](./69-progress-countdown/README.md) | Countdown Timers and Progress Bars | How-To |
| [70](./70-animations/README.md) | Animations, Transitions, CSS Motion | How-To |

### Part 8 — Advanced Testing Patterns

| # | Topic | Type |
|---|-------|------|
| [71](./71-iframes/README.md) | Testing Inside iframes | How-To |
| [72](./72-shadow-dom/README.md) | Shadow DOM Components | How-To |
| [73](./73-web-components/README.md) | Web Components (Custom Elements) | How-To |
| [74](./74-multi-tab/README.md) | Multi-tab and Multi-window Tests | How-To |
| [75](./75-permissions/README.md) | Geolocation, Permissions, and Browser APIs | How-To |
| [76](./76-accessibility/README.md) | Accessibility Testing with axe-core | How-To + Tutorial |
| [77](./77-responsive/README.md) | Responsive Testing: Viewports and Devices | How-To |
| [78](./78-network-mock/README.md) | Network Interception: Mock API Responses | How-To + Tutorial |
| [79](./79-network-errors/README.md) | Network Interception: Simulate Errors and Delays | How-To |
| [80](./80-storage-cookies/README.md) | LocalStorage, SessionStorage, Cookies | How-To |

### Part 9 — Real-World Scenarios

| # | Topic | Type |
|---|-------|------|
| [81](./81-login-flow/README.md) | Login Flow: Happy Path + Negative Cases | Tutorial |
| [82](./82-register-flow/README.md) | Registration Flow with Validation | Tutorial |
| [83](./83-search-filter/README.md) | Search and Filter: End-to-End | Tutorial |
| [84](./84-shopping-cart/README.md) | Shopping Cart: Add, Update, Remove | Tutorial |
| [85](./85-checkout/README.md) | Checkout Form: Multi-step | Tutorial |
| [86](./86-crud/README.md) | CRUD Operations: Create, Read, Update, Delete | Tutorial |
| [87](./87-role-based/README.md) | Role-Based Access: Admin vs User | Tutorial |
| [88](./88-file-download/README.md) | File Download Verification | How-To |
| [89](./89-email-verification/README.md) | Email Notification Verification (Mailhog) | How-To |
| [90](./90-cross-browser/README.md) | Cross-Browser Testing: Chrome, Firefox, WebKit | How-To |

### Part 10 — CI/CD, Reporting & AI Agents

| # | Topic | Type |
|---|-------|------|
| [91](./91-page-object-model/README.md) | Page Object Model (POM) Design Pattern | Explanation + How-To |
| [92](./92-fixtures/README.md) | Fixtures, Custom Matchers, and Test Utils | How-To + Reference |
| [93](./93-test-data/README.md) | Test Data Management: Factories and Seeding | How-To |
| [94](./94-visual-regression/README.md) | Visual Regression Testing (screenshot diff) | How-To + Tutorial |
| [95](./95-reporting/README.md) | HTML Reports and Allure Integration | How-To |
| [96](./96-ci-cd/README.md) | CI/CD: GitHub Actions for Playwright | How-To + Tutorial |
| [97](./97-playwright-mcp/README.md) | AI Agent: Playwright MCP Server Setup | Tutorial |
| [98](./98-claude-code/README.md) | AI Agent: Claude Code + Playwright | Tutorial |
| [99](./99-self-healing/README.md) | AI Agent: Self-Healing Selectors and Auto-fix | How-To + Explanation |
| [100](./100-whats-next/README.md) | What's Next: Your Automation Path Forward | Reference |

---

## References

- [Playwright Documentation](https://playwright.dev/docs/intro)
- [Playwright GitHub](https://github.com/microsoft/playwright)
- [axe-core (accessibility)](https://github.com/dequelabs/axe-core)
- [Allure Framework](https://allurereport.org/docs/playwright/)
- [Playwright MCP](https://github.com/microsoft/playwright-mcp)
- [Diátaxis Framework](https://diataxis.fr/)
