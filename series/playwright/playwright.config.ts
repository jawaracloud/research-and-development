import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
    // Look for test files in each lesson directory
    testDir: '.',
    testMatch: '**/tests/**/*.spec.ts',

    // Run tests in parallel
    fullyParallel: true,

    // Fail the build on CI if you accidentally left test.only
    forbidOnly: !!process.env.CI,

    // Retry once on CI
    retries: process.env.CI ? 1 : 0,

    // Workers: use half the CPU cores in CI, all locally
    workers: process.env.CI ? 2 : undefined,

    // Reporter configuration
    reporter: [
        ['html', { outputFolder: 'playwright-report', open: 'never' }],
        ['list'],
        ...(process.env.CI ? [['github'] as ['github']] : []),
    ],

    use: {
        // Base URL of the test app served locally
        baseURL: process.env.BASE_URL || 'http://localhost:3000',

        // Collect trace on first retry
        trace: 'on-first-retry',

        // Screenshots on failure
        screenshot: 'only-on-failure',

        // Video on first retry
        video: 'on-first-retry',

        // Slow down actions for visual debugging (set to 0 in CI)
        actionTimeout: 10_000,
        navigationTimeout: 30_000,
    },

    projects: [
        {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
        },
        {
            name: 'firefox',
            use: { ...devices['Desktop Firefox'] },
        },
        {
            name: 'webkit',
            use: { ...devices['Desktop Safari'] },
        },
        {
            name: 'mobile-chrome',
            use: { ...devices['Pixel 5'] },
        },
    ],

    // Start the test app before running tests
    webServer: {
        command: 'npx serve test-app -p 3000 --no-clipboard',
        url: 'http://localhost:3000',
        reuseExistingServer: !process.env.CI,
        timeout: 15_000,
    },
});
