import { test, expect } from "@playwright/test";
import { existsSync, writeFileSync } from "node:fs";
import path from "node:path";

const runRecordings = process.env.PICSEW_VIDEO_E2E === "1";

test.describe("existing real recording outputs [video]", () => {
  // Local codec recordings are explicitly opt-in and include ignored user samples.
  // eslint-disable-next-line playwright/no-skipped-test
  test.skip(
    !runRecordings,
    "Opt in with PICSEW_VIDEO_E2E=1 and a codec-capable browser.",
  );
  for (const fileName of [
    "demo.mp4",
    "demo1.mp4",
    "demo2.mp4",
    "demo3.mp4",
    "demo4.mp4",
    "demo5.mp4",
    "test-video.mp4",
    "fixtures/recordings/floating-arrow-2026-10-01.mp4",
  ]) {
    test(`${fileName} completes with a nonempty stitched image`, async ({
      page,
    }, testInfo) => {
      const videoPath = path.resolve(fileName);
      expect(
        existsSync(videoPath),
        `Required local recording missing: ${fileName}`,
      ).toBe(true);
      await page.addInitScript(() => {
        localStorage.setItem("picsew:onboarding-seen:v1", "1");
      });
      await page.route("https://picsew.ibotcloud.top/**", (route) =>
        route.fulfill({ status: 204, body: "" }),
      );
      const logs: string[] = [];
      page.on("console", (message) => {
        if (message.type() === "log") logs.push(message.text());
      });
      await page.goto("/");
      await page.locator('input[type="file"]').setInputFiles(videoPath);
      await expect(
        page.getByRole("button", { name: "Create screenshot", exact: true }),
      ).toBeEnabled({ timeout: 180_000 });
      await page
        .getByRole("button", { name: "Create screenshot", exact: true })
        .click();
      await expect(
        page.getByRole("heading", { name: "Your screenshot" }),
      ).toBeVisible({ timeout: 300_000 });
      const result = page.getByRole("img", {
        name: "Generated long screenshot",
      });
      await expect(result).toBeVisible();
      const output = await result.evaluate((image) => {
        const canvas = document.createElement("canvas");
        canvas.width = canvas.height = 1;
        const context = canvas.getContext("2d")!;
        context.drawImage(image as HTMLImageElement, 0, 0, 1, 1);
        return {
          width: (image as HTMLImageElement).naturalWidth,
          height: (image as HTMLImageElement).naturalHeight,
          src: (image as HTMLImageElement).src,
          hasPixels: context.getImageData(0, 0, 1, 1).data[3]! > 0,
        };
      });
      expect(output.hasPixels).toBe(true);
      expect(output.width).toBeGreaterThan(100);
      expect(output.height).toBeGreaterThan(100);
      expect(
        logs.filter((line) =>
          /Error processing video|Frame extraction failed|Error: No/.test(line),
        ),
      ).toEqual([]);
      writeFileSync(
        testInfo.outputPath("stitched.png"),
        Buffer.from(output.src.split(",")[1]!, "base64"),
      );
      writeFileSync(
        testInfo.outputPath("diagnostics.json"),
        JSON.stringify(
          { fileName, width: output.width, height: output.height, logs },
          null,
          2,
        ),
      );
    });
  }
});
