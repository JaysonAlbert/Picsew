import { defineConfig, devices } from "@playwright/test";

const enableVideoE2E = process.env.PICSEW_VIDEO_E2E === "1";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: process.env.CI ? "line" : "list",
  timeout: 900_000,
  use: {
    baseURL: "http://127.0.0.1:3001",
    locale: "en-US",
    trace: "on-first-retry",
  },
  projects: [
    {
      name: enableVideoE2E ? "chrome-video" : "chromium",
      use: enableVideoE2E
        ? { ...devices["Desktop Chrome"], channel: "chrome" }
        : { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: {
    command: "npm run dev -- --port 3001 --strictPort",
    url: "http://127.0.0.1:3001",
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
