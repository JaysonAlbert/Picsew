import { test, expect, type Page } from "@playwright/test";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";

const repoRoot = path.join(path.dirname(fileURLToPath(import.meta.url)), "..");
const demoVideoPath = path.join(repoRoot, "demo.mp4");
const testVideoPath = path.join(repoRoot, "test-video.mp4");
const runVideoE2E = process.env.PICSEW_VIDEO_E2E === "1";
const videoE2ESkipReason =
  "Set PICSEW_VIDEO_E2E=1 and run with a codec-capable Chrome browser.";
const demoVideoExpectations = [
  {
    fileName: "demo.mp4",
    videoPath: path.join(repoRoot, "demo.mp4"),
    stats: { lowResFrames: 42, candidateKeyframes: 4, finalKeyframes: 4 },
  },
  {
    fileName: "demo1.mp4",
    videoPath: path.join(repoRoot, "demo1.mp4"),
    stats: { lowResFrames: 97, candidateKeyframes: 12, finalKeyframes: 12 },
  },
  {
    fileName: "demo2.mp4",
    videoPath: path.join(repoRoot, "demo2.mp4"),
    stats: { lowResFrames: 117, candidateKeyframes: 10, finalKeyframes: 10 },
  },
  {
    fileName: "demo3.mp4",
    videoPath: path.join(repoRoot, "demo3.mp4"),
    stats: { lowResFrames: 64, candidateKeyframes: 8, finalKeyframes: 7 },
  },
  {
    fileName: "demo4.mp4",
    videoPath: path.join(repoRoot, "demo4.mp4"),
    stats: { lowResFrames: 163, candidateKeyframes: 31, finalKeyframes: 31 },
  },
] as const;

type ProcessingStats = {
  lowResFrames: number;
  candidateKeyframes: number;
  finalKeyframes: number;
};

async function mockAnalytics(page: Page) {
  await page.route("https://picsew.ibotcloud.top/**", async (route) => {
    const url = route.request().url();

    if (url.includes("/ga/js")) {
      await route.fulfill({
        status: 200,
        contentType: "application/javascript",
        body: "",
      });
      return;
    }

    await route.fulfill({
      status: 204,
      contentType: "text/plain",
      body: "",
    });
  });
}

async function waitForProcessingVideoMetadata(page: Page) {
  await page.waitForFunction(() => {
    const processingVideo = document.querySelector("video.hidden");

    return (
      processingVideo instanceof HTMLVideoElement &&
      processingVideo.readyState >= HTMLMediaElement.HAVE_METADATA &&
      processingVideo.videoWidth > 0 &&
      processingVideo.videoHeight > 0
    );
  });
}

function extractProcessingStats(consoleLogs: string[]): ProcessingStats {
  const lowResLog = consoleLogs.find((log) =>
    log.includes("Successfully extracted"),
  );
  const candidateLog = consoleLogs.find((log) =>
    log.includes("candidate keyframes"),
  );
  const finalLog = consoleLogs.find((log) =>
    log.includes("final keyframes after filtering"),
  );

  const lowResFrames = lowResLog?.match(
    /Successfully extracted (\d+) low-res frames\./,
  );
  const candidateKeyframes = candidateLog?.match(
    /Selected (\d+) candidate keyframes\./,
  );
  const finalKeyframes = finalLog?.match(
    /Selected (\d+) final keyframes after filtering\./,
  );

  expect(
    lowResFrames?.[1],
    `Missing low-res frame log in: ${consoleLogs.join("\n")}`,
  ).toBeTruthy();
  expect(
    candidateKeyframes?.[1],
    `Missing candidate keyframe log in: ${consoleLogs.join("\n")}`,
  ).toBeTruthy();
  expect(
    finalKeyframes?.[1],
    `Missing final keyframe log in: ${consoleLogs.join("\n")}`,
  ).toBeTruthy();

  const lowResFrameCount = lowResFrames?.[1];
  const candidateKeyframeCount = candidateKeyframes?.[1];
  const finalKeyframeCount = finalKeyframes?.[1];

  if (!lowResFrameCount || !candidateKeyframeCount || !finalKeyframeCount) {
    throw new Error(
      "Failed to extract processing statistics from console logs",
    );
  }

  return {
    lowResFrames: parseInt(lowResFrameCount, 10),
    candidateKeyframes: parseInt(candidateKeyframeCount, 10),
    finalKeyframes: parseInt(finalKeyframeCount, 10),
  };
}

/**
 * Helper function to run video processing test with console error detection
 */
async function runVideoProcessingTest(
  page: Page,
  videoPath: string,
  videoName: string,
  waitFor: "complete" | "stats" = "complete",
): Promise<{ consoleLogs: string[]; stats: ProcessingStats }> {
  // Capture console logs and errors
  const consoleLogs: string[] = [];
  const consoleErrors: string[] = [];
  const pageErrors: string[] = [];

  page.on("console", (msg) => {
    const text = msg.text();
    consoleLogs.push(text);
    // Capture error-level logs
    if (msg.type() === "error") {
      consoleErrors.push(text);
    }
  });

  // Capture page errors (uncaught exceptions)
  page.on("pageerror", (error: Error) => {
    pageErrors.push(error.message);
  });

  await mockAnalytics(page);
  await page.goto("/");

  // Use setInputFiles for video upload
  await page
    .locator('input[type="file"][accept*="video"]')
    .setInputFiles(videoPath);

  await expect(page.getByText(videoName, { exact: true })).toBeVisible();
  await waitForProcessingVideoMetadata(page);

  const startBtn = page.getByRole("button", { name: /Start Processing/i });
  await expect(startBtn).toBeEnabled({ timeout: 180_000 });

  await startBtn.click();

  if (waitFor === "complete") {
    await expect(page.getByText("Processing Complete")).toBeVisible({
      timeout: 900_000,
    });
    await expect(
      page.getByRole("button", { name: /Download Image/i }),
    ).toBeVisible();
  } else {
    await expect
      .poll(
        () =>
          consoleLogs.some((log) =>
            log.includes("final keyframes after filtering"),
          ),
        {
          timeout: 900_000,
          message:
            "Timed out waiting for final keyframe statistics to appear in logs",
        },
      )
      .toBe(true);
  }

  // Verify no console errors occurred (excluding known environment-specific issues)
  const criticalErrors = consoleErrors.filter(
    (err) =>
      !err.includes("Failed to load video metadata") &&
      !err.includes("Video metadata load timeout") &&
      !err.includes("Video load error"),
  );
  expect(
    criticalErrors,
    `Critical console errors detected: ${criticalErrors.join(", ")}`,
  ).toHaveLength(0);

  // Check for real page errors (not just warnings converted to errors)
  const criticalPageErrors = pageErrors.filter(
    (err) => !err.includes("Failed to load video metadata"),
  );
  expect(
    criticalPageErrors,
    `Page errors detected: ${criticalPageErrors.join(", ")}`,
  ).toHaveLength(0);

  return {
    consoleLogs,
    stats: extractProcessingStats(consoleLogs),
  };
}

test.describe("Picsew", () => {
  test("home page shows upload flow", async ({ page }) => {
    await page.goto("/");
    await expect(
      page.getByRole("heading", { name: "Long Screenshot Generator" }),
    ).toBeVisible();
    await expect(page.getByText("Upload Screen Recording")).toBeVisible();
    await expect(page.getByText("Select Video")).toBeVisible();
  });

  test("[video] demo.mp4: upload through processing to preview", async ({
    page,
  }) => {
    test.skip(!runVideoE2E, videoE2ESkipReason);
    // Optional local asset (*.mp4 may be gitignored); CI runs smoke test only.
    test.skip(!existsSync(demoVideoPath), "demo.mp4 not found at project root");

    await runVideoProcessingTest(page, demoVideoPath, "demo.mp4");
  });

  test("[video] test-video.mp4: upload through processing to preview", async ({
    page,
  }) => {
    test.skip(!runVideoE2E, videoE2ESkipReason);
    // Optional local asset
    test.skip(
      !existsSync(testVideoPath),
      "test-video.mp4 not found at project root",
    );

    await runVideoProcessingTest(page, testVideoPath, "test-video.mp4");
  });

  for (const { fileName, videoPath, stats } of demoVideoExpectations) {
    test(`[video] ${fileName}: processing stats stay stable`, async ({
      page,
    }) => {
      test.skip(!runVideoE2E, videoE2ESkipReason);
      test.skip(
        !existsSync(videoPath),
        `${fileName} not found at project root`,
      );

      const result = await runVideoProcessingTest(
        page,
        videoPath,
        fileName,
        "stats",
      );

      expect(result.stats).toEqual(stats);
    });
  }
});
