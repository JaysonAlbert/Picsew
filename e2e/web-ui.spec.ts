import { test, expect, type Page } from "@playwright/test";
import { readFile } from "node:fs/promises";

// Exercise the real UI and export lifecycle independently of codec availability.
// Real processing is covered separately by the existing [video] scenarios.
async function prepareJourney(page: Page) {
  await page.addInitScript(() => {
    localStorage.setItem("picsew:onboarding-seen:v1", "1");
  });
  await page.route("**/src/lib/opencv.ts*", (route) =>
    route.fulfill({
      contentType: "application/javascript",
      body: "export async function getOpenCV() { return {}; }",
    }),
  );
  await page.route("**/src/lib/picsew.ts*", (route) =>
    route.fulfill({
      contentType: "application/javascript",
      body: `export async function processVideo(video, log, canvas, progress) {
        progress(64);
        await new Promise(resolve => setTimeout(resolve, 1200));
        canvas.width = 720; canvas.height = 3600;
        const ctx = canvas.getContext('2d');
        ctx.fillStyle = '#fff'; ctx.fillRect(0, 0, 720, 3600);
        ctx.fillStyle = '#087a70'; ctx.fillRect(0, 0, 720, 160);
        ctx.font = 'bold 40px system-ui'; ctx.fillStyle = '#fff';
        ctx.fillText('A weekend in the city', 32, 96);
        for (let i = 0; i < 10; i++) {
          const y = 230 + i * 320;
          ctx.fillStyle = '#202124'; ctx.font = 'bold 30px system-ui';
          ctx.fillText(['Morning coffee', 'A walk by the river', 'Places to remember'][i % 3], 32, y);
          ctx.fillStyle = '#f2f2f7'; ctx.fillRect(32, y + 24, 656, 170);
          ctx.fillStyle = '#5c636b'; ctx.font = '24px system-ui';
          ctx.fillText('Take a moment. Keep the whole story.', 48, y + 90);
        }
        progress(100);
      }`,
    }),
  );
}

async function selectRecording(page: Page) {
  await page.locator('input[type="file"]').setInputFiles({
    name: "weekend-recording.mov",
    mimeType: "video/quicktime",
    buffer: Buffer.from(
      "UI fixture; processing is replaced at module boundary",
    ),
  });
}

for (const appearance of ["large text", "dark"] as const) {
  test(`all three routes remain readable with ${appearance}`, async ({
    page,
  }, testInfo) => {
    await prepareJourney(page);
    await page.setViewportSize(
      appearance === "large text"
        ? { width: 320, height: 568 }
        : { width: 375, height: 667 },
    );
    if (appearance === "dark") await page.emulateMedia({ colorScheme: "dark" });
    await page.goto("/");
    if (appearance === "large text")
      await page.evaluate(() => {
        document.documentElement.style.fontSize = "200%";
      });
    await selectRecording(page);
    const create = page.getByRole("button", {
      name: "Create screenshot",
      exact: true,
    });
    await expect(create).toBeEnabled();
    await create.scrollIntoViewIfNeeded();
    await expect(create).toBeInViewport();
    await create.click();
    await expect(page.getByRole("progressbar")).toHaveAttribute(
      "aria-valuenow",
      "64",
    );
    await page.screenshot({
      path: testInfo.outputPath("processing.png"),
      fullPage: true,
    });
    await expect(
      page.getByRole("heading", { name: "Your screenshot" }),
    ).toBeVisible();
    await expect(page.getByText("Result details", { exact: true })).toHaveCount(
      0,
    );
    const dimensions = await page.evaluate(() => ({
      width: innerWidth,
      content: document.documentElement.scrollWidth,
    }));
    expect(dimensions.content).toBeLessThanOrEqual(dimensions.width);
    const image = await page
      .getByRole("img", { name: "Generated long screenshot" })
      .boundingBox();
    expect(image?.width).toBeLessThanOrEqual(dimensions.width);
    await page.screenshot({
      path: testInfo.outputPath("preview.png"),
      fullPage: true,
    });
    const reset = page.getByRole("button", { name: "New capture" });
    await reset.scrollIntoViewIfNeeded();
    await expect(reset).toBeInViewport();
    await reset.click();
    await expect(create).toBeDisabled();
  });
}

test("selection, accessible progress, content-first viewer, save and new capture", async ({
  page,
}, testInfo) => {
  await prepareJourney(page);
  await page.goto("/");
  const create = page.getByRole("button", {
    name: "Create screenshot",
    exact: true,
  });
  await expect(create).toBeDisabled();
  await selectRecording(page);
  await expect(create).toBeEnabled();
  await page.getByRole("button", { name: "Clear selection" }).click();
  await expect(create).toBeDisabled();
  await selectRecording(page);
  await expect(
    page.getByText("weekend-recording.mov", { exact: true }),
  ).toBeVisible();
  await expect(create).toBeEnabled();
  await page.mouse.move(0, 0);

  await page.screenshot({
    path: testInfo.outputPath("upload.png"),
    fullPage: true,
  });
  await create.click();
  await expect(page.getByRole("progressbar")).toHaveAttribute(
    "aria-valuenow",
    "64",
  );
  await page.screenshot({
    path: testInfo.outputPath("processing.png"),
    fullPage: true,
  });
  await expect(
    page.getByRole("heading", { name: "Your screenshot" }),
  ).toBeVisible();
  await expect(page.getByText("Result details", { exact: true })).toHaveCount(
    0,
  );
  await page.screenshot({
    path: testInfo.outputPath("preview.png"),
    fullPage: true,
  });
  const download = page.waitForEvent("download");
  await page.getByRole("button", { name: "Save image", exact: true }).click();
  expect((await download).suggestedFilename()).toBe("long-screenshot.png");
  await page.getByRole("button", { name: "New capture" }).click();
  await expect(create).toBeDisabled();
  await expect(
    page.getByText("weekend-recording.mov", { exact: true }),
  ).toHaveCount(0);
});

test("small-screen onboarding remains dismissible at enlarged text", async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ width: 320, height: 568 });
  await page.goto("/");
  await page.evaluate(() => {
    document.documentElement.style.fontSize = "200%";
  });
  const dialog = page.getByRole("dialog");
  const continueButton = dialog.getByRole("button", {
    name: "Continue",
    exact: true,
  });
  await expect(continueButton).toBeVisible();
  await continueButton.scrollIntoViewIfNeeded();
  await expect(continueButton).toBeInViewport();
  await page.screenshot({
    path: testInfo.outputPath("onboarding-large.png"),
    fullPage: true,
  });
  await continueButton.click();
  await expect(dialog).toHaveCount(0);
  const width = await page.evaluate(() => ({
    content: document.documentElement.scrollWidth,
    viewport: innerWidth,
  }));
  expect(width.content).toBeLessThanOrEqual(width.viewport);
  await page.screenshot({
    path: testInfo.outputPath("upload-large.png"),
    fullPage: true,
  });
});

test("Chinese dark mode keeps the import action reachable", async ({
  page,
}, testInfo) => {
  await prepareJourney(page);
  await page.addInitScript(() => {
    localStorage.setItem("i18nextLng", "zh");
  });
  await page.emulateMedia({ colorScheme: "dark" });
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "创建长截图" })).toBeVisible();
  await expect(
    page.getByRole("button", { name: "创建长截图", exact: true }),
  ).toBeDisabled();
  await page.screenshot({
    path: testInfo.outputPath("dark-upload.png"),
    fullPage: true,
  });
  const controls = await page.getByRole("button").evaluateAll((buttons) =>
    buttons.map((button) => {
      const r = button.getBoundingClientRect();
      return { width: r.width, height: r.height };
    }),
  );
  for (const control of controls) {
    expect(control.width).toBeGreaterThanOrEqual(44);
    expect(control.height).toBeGreaterThanOrEqual(44);
  }
});

for (const viewport of [
  { width: 640, height: 900 },
  { width: 647, height: 871 },
  { width: 1280, height: 1000 },
  { width: 1440, height: 1400 },
]) {
  test(`desktop ${viewport.width}px keeps actions beside their content across all routes`, async ({
    page,
  }, testInfo) => {
    await prepareJourney(page);
    await page.setViewportSize(viewport);
    await page.goto("/");
    const create = page.getByRole("button", {
      name: "Create screenshot",
      exact: true,
    });
    const privacy = page.getByText("Everything is processed on your device.", {
      exact: true,
    });
    async function expectNearbyActions(previous: typeof privacy) {
      const before = await previous.boundingBox();
      const action = await page.locator(".app-primary-action").boundingBox();
      expect(before).not.toBeNull();
      expect(action).not.toBeNull();
      const gap = action!.y - (before!.y + before!.height);
      expect(gap).toBeGreaterThanOrEqual(0);
      expect(gap).toBeLessThanOrEqual(32);
    }
    await expect(create).toBeDisabled();
    const createBox = await create.boundingBox();
    expect(createBox).not.toBeNull();
    expect(createBox!.width).toBeGreaterThanOrEqual(160);
    expect(createBox!.width).toBeLessThanOrEqual(280);
    expect(createBox!.height).toBeGreaterThanOrEqual(44);
    await expectNearbyActions(privacy);
    await page.screenshot({ path: testInfo.outputPath("desktop-empty.png") });
    await selectRecording(page);
    await expect(create).toBeEnabled();
    await expectNearbyActions(privacy);
    await page.screenshot({ path: testInfo.outputPath("desktop-upload.png") });
    await create.click();
    await expect(page.getByRole("progressbar")).toHaveAttribute(
      "aria-valuenow",
      "64",
    );
    const processing = await page
      .getByTestId("processing-stage-card")
      .boundingBox();
    expect(processing).not.toBeNull();
    expect(processing!.height).toBeLessThanOrEqual(360);
    await page.screenshot({
      path: testInfo.outputPath("desktop-processing.png"),
    });
    await expect(
      page.getByRole("heading", { name: "Your screenshot" }),
    ).toBeVisible();
    const viewer = page.getByRole("region", {
      name: "Generated long screenshot",
    });
    await expectNearbyActions(viewer);
    await expect(
      page.getByRole("button", { name: "Save image", exact: true }),
    ).toBeInViewport();
    await expect(
      page.getByRole("button", { name: "New capture", exact: true }),
    ).toBeInViewport();
    await page.screenshot({ path: testInfo.outputPath("desktop-preview.png") });
    await expect(page.getByText("Result details", { exact: true })).toHaveCount(
      0,
    );
    const overflow = await page.evaluate(() => ({
      content: document.documentElement.scrollWidth,
      viewport: innerWidth,
    }));
    expect(overflow.content).toBeLessThanOrEqual(overflow.viewport);
    await page.getByRole("button", { name: "New capture" }).click();
    await expect(create).toBeDisabled();
    await expectNearbyActions(privacy);
  });
}

test("narrow mobile keeps the upload action at the bottom without covering content", async ({
  page,
}, testInfo) => {
  await prepareJourney(page);
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  const action = await page
    .getByRole("button", {
      name: "Create screenshot",
      exact: true,
    })
    .boundingBox();
  const caption = await page.locator(".product-privacy").boundingBox();
  expect(action).not.toBeNull();
  expect(caption).not.toBeNull();
  expect(action!.y).toBeGreaterThan(caption!.y + caption!.height);
  expect(action!.y + action!.height).toBeGreaterThanOrEqual(820);
  expect(action!.y + action!.height).toBeLessThanOrEqual(844);
  await page.screenshot({ path: testInfo.outputPath("mobile-empty.png") });
});

test("desktop short windows keep actions reachable at enlarged text", async ({
  page,
}, testInfo) => {
  await prepareJourney(page);
  await page.setViewportSize({ width: 1280, height: 600 });
  await page.goto("/");
  await page.evaluate(() => {
    document.documentElement.style.fontSize = "200%";
  });
  await selectRecording(page);
  const create = page.getByRole("button", {
    name: "Create screenshot",
    exact: true,
  });
  await expect(create).toBeEnabled();
  await create.scrollIntoViewIfNeeded();
  await expect(create).toBeInViewport();
  await page.screenshot({
    path: testInfo.outputPath("desktop-large-upload.png"),
    fullPage: true,
  });
  await create.click();
  await expect(page.getByRole("progressbar")).toHaveAttribute(
    "aria-valuenow",
    "64",
  );
  await expect(
    page.getByRole("heading", { name: "Your screenshot" }),
  ).toBeVisible();
  await expect(page.getByText("Result details", { exact: true })).toHaveCount(
    0,
  );
  const save = page.getByRole("button", { name: "Save image", exact: true });
  await save.scrollIntoViewIfNeeded();
  await expect(save).toBeInViewport();
  const dimensions = await page.evaluate(() => ({
    content: document.documentElement.scrollWidth,
    viewport: innerWidth,
  }));
  expect(dimensions.content).toBeLessThanOrEqual(dimensions.viewport);
  await page.screenshot({
    path: testInfo.outputPath("desktop-large-preview.png"),
    fullPage: true,
  });
  const reset = page.getByRole("button", { name: "New capture" });
  await reset.scrollIntoViewIfNeeded();
  await expect(reset).toBeInViewport();
  await reset.click();
  await expect(create).toBeDisabled();
});

for (const appearance of ["light", "dark"] as const) {
  test(`technology theme and dominant mobile preview in ${appearance}`, async ({
    page,
  }, testInfo) => {
    await prepareJourney(page);
    await page.setViewportSize({ width: 375, height: 667 });
    await page.emulateMedia({ colorScheme: appearance });
    await page.goto("/");
    await selectRecording(page);
    await page
      .getByRole("button", { name: "Create screenshot", exact: true })
      .click();
    const viewer = page.getByRole("region", {
      name: "Generated long screenshot",
    });
    await expect(viewer).toBeVisible();
    await expect(page.getByText("Result details", { exact: true })).toHaveCount(
      0,
    );
    const region = await viewer.boundingBox();
    expect(region!.height).toBeGreaterThanOrEqual(667 * 0.75);
    const image = page.getByRole("img", { name: "Generated long screenshot" });
    const fitted = await image.boundingBox();
    // Public interaction: zoom must actually change rendered width, not just a label.
    await viewer.focus();
    await page.keyboard.press("Enter");
    await expect
      .poll(async () => (await image.boundingBox())!.width)
      .toBeCloseTo(fitted!.width * 2, 0);
    await viewer.evaluate((element) => {
      element.scrollTop = 300;
      element.scrollLeft = 100;
    });
    expect(
      await viewer.evaluate((element) => element.scrollTop),
    ).toBeGreaterThan(0);
    await page.screenshot({ path: testInfo.outputPath("zoomed-preview.png") });
    await page.keyboard.press("Enter");
    await expect
      .poll(async () => (await image.boundingBox())!.width)
      .toBeCloseTo(fitted!.width, 0);
    const controls = page.getByRole("button");
    for (const button of await controls.all()) {
      const bounds = await button.boundingBox();
      expect(bounds).not.toBeNull();
      expect(bounds!.width).toBeGreaterThanOrEqual(44);
      expect(bounds!.height).toBeGreaterThanOrEqual(44);
    }
    const contrast = await page.evaluate(() => {
      const luminance = (color: string) => {
        const channels = color
          .match(/[\d.]+/g)!
          .slice(0, 3)
          .map(Number)
          .map((v) => {
            v /= 255;
            return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
          });
        return (
          channels[0]! * 0.2126 + channels[1]! * 0.7152 + channels[2]! * 0.0722
        );
      };
      const shell = getComputedStyle(document.querySelector(".product-shell")!);
      const action = getComputedStyle(
        document.querySelector(".app-primary-action")!,
      );
      const ratio = (a: string, b: string) => {
        const x = luminance(a),
          y = luminance(b);
        return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
      };
      return {
        text: ratio(shell.color, shell.backgroundColor),
        action: ratio(action.color, action.backgroundColor),
      };
    });
    expect(contrast.text).toBeGreaterThanOrEqual(4.5);
    expect(contrast.action).toBeGreaterThanOrEqual(4.5);
    await page.screenshot({
      path: testInfo.outputPath("technology-preview.png"),
    });
    // The original export is independent of viewer zoom or scroll.
    const download = page.waitForEvent("download");
    await page.getByRole("button", { name: "Save image", exact: true }).click();
    const exported = await download;
    expect(exported.suggestedFilename()).toBe("long-screenshot.png");
    const png = await readFile((await exported.path())!);
    expect(png.readUInt32BE(16)).toBe(720);
    expect(png.readUInt32BE(20)).toBe(3600);
    await page
      .getByRole("button", { name: "New capture", exact: true })
      .click();
    await expect(
      page.getByRole("button", { name: "Create screenshot", exact: true }),
    ).toBeDisabled();
  });
}
