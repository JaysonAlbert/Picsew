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
      const output = await result.evaluate(async (image, fileName) => {
        const canvas = document.createElement("canvas");
        canvas.width = canvas.height = 1;
        const context = canvas.getContext("2d")!;
        context.drawImage(image as HTMLImageElement, 0, 0, 1, 1);
        let arrowRows: number[] = [];
        if (fileName.endsWith("floating-arrow-2026-10-01.mp4")) {
          // The original button's fixed position is measured in the input clip.
          // Match its upper glyph too: a cropped duplicate is still a defect.
          const source = document.createElement("video");
          source.muted = true;
          source.src = `/${fileName}`;
          await new Promise<void>((resolve, reject) => {
            source.onloadeddata = () => resolve();
            source.onerror = () =>
              reject(new Error("Cannot decode arrow oracle"));
            source.load();
          });
          await new Promise<void>((resolve) => {
            source.onseeked = () => resolve();
            source.currentTime = 0.5;
          });
          const glyph = document.createElement("canvas");
          glyph.width = 50;
          glyph.height = 34;
          const glyphContext = glyph.getContext("2d")!;
          glyphContext.drawImage(source, 578, 2100, 50, 34, 0, 0, 50, 34);
          const template = glyphContext.getImageData(0, 0, 50, 34).data;
          const dark: number[] = [],
            light: number[] = [];
          for (let i = 0; i < 50 * 34; i++)
            (template[i * 4]! < 60 ? dark : light).push(i);
          if (dark.length < 200 || dark.length > 600)
            throw new Error("Original arrow oracle is missing");
          canvas.width = (image as HTMLImageElement).naturalWidth;
          canvas.height = (image as HTMLImageElement).naturalHeight;
          context.drawImage(image as HTMLImageElement, 0, 0);
          const strip = context.getImageData(578, 0, 50, canvas.height).data;
          const hits: number[] = [];
          for (let y = 0; y <= canvas.height - 34; y++) {
            const start = y * 50;
            const blackMatches = dark.filter(
              (i) => strip[(start + i) * 4]! < 60,
            ).length;
            const whiteErrors = light.filter(
              (i) => strip[(start + i) * 4]! < 60,
            ).length;
            if (
              blackMatches / dark.length > 0.92 &&
              whiteErrors / light.length < 0.055
            )
              hits.push(y);
          }
          arrowRows = hits.filter((y, i) => i === 0 || y > hits[i - 1]! + 2);
          source.removeAttribute("src");
          source.load();
        }
        return {
          arrowRows,
          width: (image as HTMLImageElement).naturalWidth,
          height: (image as HTMLImageElement).naturalHeight,
          src: (image as HTMLImageElement).src,
          hasPixels: context.getImageData(0, 0, 1, 1).data[3]! > 0,
        };
      }, fileName);
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
          {
            fileName,
            width: output.width,
            height: output.height,
            arrowRows: output.arrowRows,
            logs,
          },
          null,
          2,
        ),
      );
      // Only this source has a measured fixed-arrow oracle. Its final footer
      // control lacks a clean source; repeated body controls must be absent.
      expect(output.arrowRows).toHaveLength(
        fileName.endsWith("floating-arrow-2026-10-01.mp4") ? 1 : 0,
      );
      expect(output.arrowRows.every((y) => y > output.height - 600)).toBe(true);
    });
  }
});
