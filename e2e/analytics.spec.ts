import { test, expect, type Page } from "@playwright/test";

type Scenario =
  | "success"
  | "swallowed_failure"
  | "metadata_error"
  | "generate_error"
  | "empty_output"
  | "share_abort"
  | "share_error"
  | "download_error"
  | "metadata_pending";
async function prepare(page: Page, scenario: Scenario = "success") {
  // Exercise the real analytics module with a fictitious local-only test ID.
  // Never load a real SDK or send a collection request.
  await page.route("**/src/lib/analytics.ts*", async (route) => {
    const response = await route.fetch();
    const body = (await response.text()).replace(
      "import.meta.env.VITE_GA_TEST_MEASUREMENT_ID",
      '"G-LOCALTEST"',
    );
    await route.fulfill({ response, body });
  });
  await page.route("https://picsew.ibotcloud.top/**", (route) =>
    route.fulfill({
      contentType: "application/javascript",
      body: "/* local analytics stub: no network collection */",
    }),
  );
  await page.route("**/*.google-analytics.com/**", (route) => route.abort());
  await page.route("**/*.googletagmanager.com/**", (route) => route.abort());
  await page.addInitScript((mode) => {
    localStorage.setItem("picsew:onboarding-seen:v1", "1");
    Object.defineProperty(HTMLMediaElement.prototype, "src", {
      configurable: true,
      get: () => "",
      set: () => undefined,
    });
    HTMLMediaElement.prototype.load = function () {
      if (!this.classList.contains("hidden")) return;
      if (mode === "metadata_pending") return;
      if (mode === "metadata_error") {
        queueMicrotask(() => this.dispatchEvent(new Event("error")));
        return;
      }
      Object.defineProperties(this, {
        duration: { configurable: true, value: 25 },
        videoWidth: { configurable: true, value: 1080 },
        videoHeight: { configurable: true, value: 1920 },
      });
      queueMicrotask(() => {
        this.dispatchEvent(new Event("loadedmetadata"));
        this.dispatchEvent(new Event("loadedmetadata"));
      });
    };
    Object.defineProperty(navigator, "canShare", {
      value: () => true,
      configurable: true,
    });
    Object.defineProperty(navigator, "share", {
      value: async () => {
        if (mode === "share_abort")
          throw new DOMException(
            "alice@example.com secret file.mov",
            "AbortError",
          );
        if (mode === "share_error")
          throw new Error("alice@example.com secret file.mov");
      },
      configurable: true,
    });
    if (mode === "download_error")
      HTMLAnchorElement.prototype.click = () => {
        throw new Error("private file URL");
      };
  }, scenario);
  await page.route("**/src/lib/opencv.ts*", (route) =>
    route.fulfill({
      contentType: "application/javascript",
      body: "export async function getOpenCV() { return {}; }",
    }),
  );
  await page.route("**/src/lib/picsew.ts*", (route) =>
    route.fulfill({
      contentType: "application/javascript",
      body: `export async function processVideo(video, log, canvas) {
    ${scenario === "swallowed_failure" ? 'return "processing_failed";' : scenario === "generate_error" ? 'throw new Error("alice@example.com secret file.mov");' : scenario === "empty_output" ? 'canvas.width = 0; canvas.height = 0; return "empty_output";' : 'canvas.width = 10; canvas.height = 10; canvas.getContext("2d").fillRect(0,0,10,10); return "success";'}
  }`,
    }),
  );
  page.on("dialog", (dialog) => dialog.dismiss());
  await page.goto("/?token=private&email=alice@example.com#secret");
}
async function events(page: Page) {
  return page.evaluate(() =>
    (window.dataLayer as unknown[][])
      .filter((c) => c[0] === "event")
      .map((c) => ({
        name: c[1] as string,
        params: c[2] as Record<string, unknown>,
      })),
  );
}
async function select(page: Page) {
  await page.locator('input[type="file"]').setInputFiles({
    name: "alice@example.com-secret.mov",
    mimeType: "video/quicktime",
    buffer: Buffer.from("private recording pixels"),
  });
}
async function generate(page: Page) {
  await select(page);
  await expect
    .poll(
      async () =>
        (await events(page)).filter((e) => e.name === "upload_completed")
          .length,
    )
    .toBe(1);
  await page
    .getByRole("button", { name: "Create screenshot", exact: true })
    .click();
}

test("real analytics transport deduplicates StrictMode views/metadata and first task dispatch", async ({
  page,
}) => {
  await prepare(page);
  await generate(page);
  await expect(page.getByTestId("preview-stage-card")).toBeVisible();
  const download = page.waitForEvent("download");
  await page.getByRole("button", { name: "Save image", exact: true }).click();
  await download;
  const repeat = page.waitForEvent("download");
  await page.getByRole("button", { name: "Save image", exact: true }).click();
  await repeat;
  const result = await events(page);
  expect(
    result
      .map((e) => e.name)
      .filter((n) => n !== "page_view" && n !== "preview_shown"),
  ).toEqual([
    "upload_started",
    "upload_completed",
    "processing_started",
    "processing_completed",
    "export_started",
    "export_completed",
    "task_finished",
    "export_started",
    "export_completed",
  ]);
  expect(
    result.filter((e) => e.name === "page_view").map((e) => e.params.page_path),
  ).toEqual(["/upload", "/processing", "/preview"]);
  expect(JSON.stringify(result)).not.toMatch(
    /alice|secret|private|blob:|data:image|error_message|task_id/,
  );
  await expect(page.locator('script[src*="/ga/js"]')).toHaveCount(1);
});

test("metadata error is a bounded import error; no import success", async ({
  page,
}) => {
  await prepare(page, "metadata_error");
  await select(page);
  await expect
    .poll(
      async () =>
        (await events(page)).filter((e) => e.name === "task_error").length,
    )
    .toBe(1);
  expect(
    (await events(page))
      .filter((e) => e.name !== "page_view")
      .map((e) => e.name),
  ).toEqual(["upload_started", "task_error", "task_finished"]);
});

for (const scenario of [
  "generate_error",
  "empty_output",
  "swallowed_failure",
] as const) {
  test(`${scenario} uses the legacy failure event with safe error code`, async ({
    page,
  }) => {
    await prepare(page, scenario);
    await generate(page);
    await expect
      .poll(
        async () =>
          (await events(page)).filter((e) => e.name === "processing_failed")
            .length,
      )
      .toBe(1);
    const result = await events(page);
    expect(
      result.find((e) => e.name === "processing_failed")?.params.error_code,
    ).toBe(scenario === "empty_output" ? "empty_output" : "processing_failed");
    expect(result.some((e) => e.name === "processing_completed")).toBe(false);
    expect(JSON.stringify(result)).not.toMatch(/alice|secret|file.mov/);
  });
}

test("sharing resolves before dispatch is recorded", async ({ page }) => {
  await prepare(page);
  await generate(page);
  await page.getByRole("button", { name: "Share", exact: true }).click();
  await expect
    .poll(
      async () =>
        (await events(page)).filter((e) => e.name === "export_completed")
          .length,
    )
    .toBe(1);
  expect(
    (await events(page)).find((e) => e.name === "export_completed")?.params
      .export_method,
  ).toBe("share");
});

for (const scenario of [
  "share_abort",
  "share_error",
  "download_error",
] as const) {
  test(`${scenario} remains distinguishable from dispatch and allows retry`, async ({
    page,
  }) => {
    await prepare(page, scenario);
    await generate(page);
    await page
      .getByRole("button", {
        name: scenario === "download_error" ? "Save image" : "Share",
        exact: true,
      })
      .click();
    await expect
      .poll(
        async () =>
          (await events(page)).filter(
            (e) => e.name === "task_cancelled" || e.name === "task_error",
          ).length,
      )
      .toBe(1);
    expect(
      (await events(page)).some(
        (e) => e.name === "export_completed" || e.name === "task_finished",
      ),
    ).toBe(false);
    expect(JSON.stringify(await events(page))).not.toMatch(
      /alice|secret|private/,
    );
    await page
      .getByRole("button", { name: "New capture", exact: true })
      .click();
    expect(
      (await events(page)).find((e) => e.name === "task_finished")?.params
        .task_outcome,
    ).toBe("cancelled");
  });
}

test("clear is explicit cancellation; metadata that never returns stays unknown", async ({
  page,
}) => {
  await prepare(page, "metadata_pending");
  await select(page);
  expect(
    (await events(page))
      .filter((e) => e.name !== "page_view")
      .map((e) => e.name),
  ).toEqual(["upload_started"]);
  await page
    .getByRole("button", { name: "Clear selection", exact: true })
    .click();
  expect(
    (await events(page)).find((e) => e.name === "task_finished")?.params
      .task_outcome,
  ).toBe("cancelled");
});
