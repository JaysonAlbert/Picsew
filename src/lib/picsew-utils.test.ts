import { describe, expect, it } from "vitest";
import {
  getErrorMessage,
  getFullResDecodeScale,
  scaleRect,
} from "./picsew-utils";

describe("getFullResDecodeScale", () => {
  it("returns 1 when max edge is at most 1", () => {
    expect(getFullResDecodeScale(0, 0, false)).toBe(1);
    expect(getFullResDecodeScale(1, 1, false)).toBe(1);
  });

  it("returns 1 when within non-iOS cap (8192)", () => {
    expect(getFullResDecodeScale(4000, 3000, false)).toBe(1);
    expect(getFullResDecodeScale(8192, 100, false)).toBe(1);
  });

  it("scales down on non-iOS when max edge exceeds 8192", () => {
    expect(getFullResDecodeScale(16384, 100, false)).toBeCloseTo(0.5, 5);
  });

  it("uses 1536 cap on iOS", () => {
    expect(getFullResDecodeScale(3000, 2000, true)).toBeCloseTo(1536 / 3000, 5);
  });

  it("returns 1 on iOS when within 1536 cap", () => {
    expect(getFullResDecodeScale(1536, 100, true)).toBe(1);
  });
});

describe("scaleRect", () => {
  it("multiplies and rounds components", () => {
    expect(scaleRect({ x: 10, y: 20, width: 100, height: 50 }, 0.5)).toEqual({
      x: 5,
      y: 10,
      width: 50,
      height: 25,
    });
  });
});

describe("getErrorMessage", () => {
  it("uses OpenCV exception when error is a number and cv works", () => {
    const cv = {
      exceptionFromPtr: () => ({ msg: "bad mat" }),
    };
    expect(getErrorMessage(42, cv)).toBe("OpenCV Exception: bad mat");
  });

  it("falls back when exceptionFromPtr throws", () => {
    const cv = {
      exceptionFromPtr: () => {
        throw new Error("fail");
      },
    };
    expect(getErrorMessage(7, cv)).toBe("OpenCV Exception Pointer: 7");
  });

  it("uses Error.message", () => {
    expect(getErrorMessage(new Error("oops"))).toBe("oops");
  });

  it("uses .message on non-Error objects", () => {
    expect(getErrorMessage({ message: "x" })).toBe("x");
  });

  it("uses .msg when present", () => {
    expect(getErrorMessage({ msg: "y" })).toBe("y");
  });

  it("stringifies unknown values", () => {
    expect(getErrorMessage(null)).toBe("null");
    expect(getErrorMessage(undefined)).toBe("undefined");
  });
});
