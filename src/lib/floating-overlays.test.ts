import { describe, expect, it } from "vitest";
import {
  findFloatingOverlays,
  cleanTemplateColumn,
  intersect,
  subtract,
  type GrayFrame,
} from "./floating-overlays";

function recording(control: boolean, dark = false): GrayFrame[] {
  let seed = 31;
  return Array.from({ length: 8 }, () => {
    const data = Uint8Array.from({ length: 120 * 180 }, () => {
      seed = (seed * 1664525 + 1013904223) >>> 0;
      return 70 + (seed % 180);
    });
    if (control) {
      for (let y = 105; y < 125; y++) {
        for (let x = 50; x < 70; x++) data[y * 120 + x] = dark ? 25 : 240;
      }
      for (let y = 111; y < 120; y++) {
        for (let x = 58; x < 62; x++) data[y * 120 + x] = dark ? 240 : 25;
      }
    }
    return { data, cols: 120, rows: 180 };
  });
}
const window = { x: 0, y: 30, width: 120, height: 130 };

describe("stationary controls among moving content", () => {
  it.each([false, true])(
    "identifies a compact fixed control (dark=%s)",
    (dark) => {
      const boxes = findFloatingOverlays(recording(true, dark), window);
      expect(
        boxes.some(
          (box) =>
            box.x <= 50 &&
            box.y <= 105 &&
            box.x + box.width >= 70 &&
            box.y + box.height >= 125,
        ),
      ).toBe(true);
    },
  );
  it("covers a control crossing the scrolling-window boundary", () => {
    const boxes = findFloatingOverlays(recording(true), {
      ...window,
      height: 90,
    });
    expect(boxes.some((box) => box.y <= 105 && box.y + box.height >= 125)).toBe(
      true,
    );
  });
  it("leaves moving content alone", () => {
    expect(findFloatingOverlays(recording(false), window)).toEqual([]);
  });
  it("does not infer controls from paused frames or too few views", () => {
    const frames = recording(true);
    expect(
      findFloatingOverlays([frames[0]!, frames[0]!, frames[0]!], window),
    ).toEqual([]);
    expect(findFloatingOverlays(frames.slice(0, 2), window)).toEqual([]);
  });
  it("does not include fixed header or footer controls", () => {
    expect(
      findFloatingOverlays(recording(true), { ...window, height: 65 }),
    ).toEqual([]);
  });
});

describe("clean-source rectangles", () => {
  it("clips recovery to the visible source", () => {
    expect(
      intersect(
        { x: 2, y: 2, width: 8, height: 8 },
        { x: 5, y: 0, width: 8, height: 6 },
      ),
    ).toEqual({ x: 5, y: 2, width: 5, height: 4 });
    expect(
      intersect(
        { x: 0, y: 0, width: 3, height: 3 },
        { x: 3, y: 0, width: 3, height: 3 },
      ),
    ).toBeNull();
  });
  it("covers every clean pixel once and never copies occluded pixels", () => {
    const pieces = subtract(
      { x: 0, y: 0, width: 10, height: 10 },
      { x: 3, y: 4, width: 3, height: 2 },
    );
    for (let y = 0; y < 10; y++) {
      for (let x = 0; x < 10; x++) {
        const covering = pieces.filter(
          (piece) =>
            x >= piece.x &&
            x < piece.x + piece.width &&
            y >= piece.y &&
            y < piece.y + piece.height,
        );
        expect(covering.length).toBe(
          x >= 3 && x < 6 && y >= 4 && y < 6 ? 0 : 1,
        );
      }
    }
  });
  it("keeps unrecoverable coverage and rejects fully occluded sources", () => {
    const rect = { x: 0, y: 0, width: 10, height: 10 };
    expect(subtract(rect, { x: 20, y: 20, width: 2, height: 2 })).toEqual([
      rect,
    ]);
    expect(subtract(rect, rect)).toEqual([]);
  });
});

describe("offset matching around controls", () => {
  const template = { x: 0, y: 50, width: 100, height: 30 };
  it("uses the same clean source columns and excludes only overlapping controls", () => {
    expect(
      cleanTemplateColumn(template, [
        { x: 40, y: 60, width: 20, height: 15 },
        { x: 0, y: 10, width: 100, height: 15 },
      ]),
    ).toEqual({ x: 0, y: 50, width: 40, height: 30 });
  });
  it("declines recovery when controls leave no reliable template span", () => {
    expect(
      cleanTemplateColumn(template, [{ x: 20, y: 60, width: 60, height: 15 }]),
    ).toBeNull();
    expect(cleanTemplateColumn(template, [])).toEqual(template);
  });
});
