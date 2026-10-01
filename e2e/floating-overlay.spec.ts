import { expect, test } from "@playwright/test";
import { writeFileSync } from "node:fs";
import path from "node:path";

for (const kind of ["fixed", "white", "dark", "clean"]) {
  test(`${kind} control preserves the known document and moving arrows`, async ({
    page,
    browserName,
  }, testInfo) => {
    await page.addInitScript(() =>
      localStorage.setItem("picsew:onboarding-seen:v1", "1"),
    );
    await page.route("https://picsew.ibotcloud.top/**", (route) =>
      route.fulfill({ status: 204, body: "" }),
    );
    const logs: string[] = [];
    page.on("console", (message) => {
      if (message.type() === "log") logs.push(message.text());
    });
    await page.goto("/");
    await page
      .locator('input[type="file"]')
      .setInputFiles(
        path.resolve(
          `fixtures/floating-overlay/${kind}.${browserName === "webkit" ? "mp4" : "webm"}`,
        ),
      );
    const create = page.getByRole("button", {
      name: "Create screenshot",
      exact: true,
    });
    await expect(create).toBeEnabled();
    await create.click();
    await expect(
      page.getByRole("heading", { name: "Your screenshot" }),
    ).toBeVisible();
    const image = page.getByRole("img", { name: "Generated long screenshot" });
    await expect(image).toBeVisible();
    const result = await image.evaluate(
      async (image, { kind }) => {
        const output = document.createElement("canvas");
        output.width = (image as HTMLImageElement).naturalWidth;
        output.height = (image as HTMLImageElement).naturalHeight;
        output.getContext("2d")!.drawImage(image as HTMLImageElement, 0, 0);
        const pixels = output
          .getContext("2d")!
          .getImageData(0, 0, output.width, output.height).data;
        const documentImage = new Image();
        documentImage.src = "/fixtures/floating-overlay/document.png";
        await documentImage.decode();
        const original = document.createElement("canvas");
        original.width = documentImage.width;
        original.height = documentImage.height;
        original.getContext("2d")!.drawImage(documentImage, 0, 0);
        const expected = original
          .getContext("2d")!
          .getImageData(0, 0, original.width, original.height).data;
        const luminance = (data: Uint8ClampedArray, at: number) =>
          data[at]! * 0.299 + data[at + 1]! * 0.587 + data[at + 2]! * 0.114;
        const patchErrors = [470, 710, 950].map((top) => {
          let error = 0;
          for (let y = top; y < top + 85; y++) {
            for (let x = 205; x < 275; x++) {
              error += Math.abs(
                luminance(pixels, (y * output.width + x) * 4) -
                  luminance(expected, ((y - 80) * original.width + x) * 4),
              );
            }
          }
          return error / (85 * 70);
        });
        let documentError = 0,
          compared = 0;
        const pinkRows: number[] = [],
          greenRows: number[] = [];
        for (let y = 80; y < output.height - 80; y++) {
          let pink = 0,
            green = 0;
          for (let x = 0; x < output.width; x++) {
            const at = (y * output.width + x) * 4;
            if (x >= 205 && x < 275) {
              if (
                pixels[at]! > 220 &&
                pixels[at + 1]! < 65 &&
                pixels[at + 2]! > 140
              )
                pink++;
              if (
                pixels[at]! < 35 &&
                pixels[at + 1]! > 145 &&
                pixels[at + 2]! < 85
              )
                green++;
            }
            // The known last control has no clean source in the recording.
            if (
              kind !== "clean" &&
              x >= 200 &&
              x < 280 &&
              y >= 1150 &&
              y < 1240
            )
              continue;
            documentError += Math.abs(
              luminance(pixels, at) -
                luminance(expected, ((y - 80) * original.width + x) * 4),
            );
            compared++;
          }
          if (pink > 3) pinkRows.push(y);
          if (green > 2) greenRows.push(y);
        }
        const bands = (rows: number[]) =>
          rows.filter((y, i) => i === 0 || y > rows[i - 1]! + 2);
        return {
          width: output.width,
          height: output.height,
          pinkBands: bands(pinkRows),
          greenBands: bands(greenRows),
          patchErrors,
          documentError: documentError / compared,
          png: output.toDataURL(),
        };
      },
      { kind },
    );
    writeFileSync(
      testInfo.outputPath("stitched.png"),
      Buffer.from(result.png.split(",")[1]!, "base64"),
    );
    writeFileSync(
      testInfo.outputPath("diagnostics.json"),
      JSON.stringify({ ...result, logs, png: undefined }, null, 2),
    );
    console.log(
      JSON.stringify({
        kind,
        browserName,
        width: result.width,
        height: result.height,
        pinkBands: result.pinkBands,
        greenBands: result.greenBands,
        patchErrors: result.patchErrors,
        documentError: result.documentError,
      }),
    );
    expect(logs.filter((line) => line.includes("Error processing"))).toEqual(
      [],
    );
    expect(result.width).toBe(480);
    expect(result.height).toBe(1400);
    expect(result.pinkBands).toHaveLength(kind === "fixed" ? 1 : 0);
    expect(result.greenBands).toHaveLength(4);
    for (const [i, y] of result.greenBands.entries())
      expect(Math.abs(y - (232 + i * 280))).toBeLessThanOrEqual(2);
    for (const error of result.patchErrors) expect(error).toBeLessThan(7);
    expect(result.documentError).toBeLessThan(7);
  });
}
