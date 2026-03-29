import { describe, expect, it } from "vitest";
import { getBase64Payload, isLikelyUserCancellation } from "./native-media";

describe("native-media helpers", () => {
  it("strips data url prefixes from base64 payloads", () => {
    expect(getBase64Payload("data:image/png;base64,QUJD")).toBe("QUJD");
  });

  it("returns the original string when no data url prefix exists", () => {
    expect(getBase64Payload("QUJD")).toBe("QUJD");
  });

  it("detects common cancellation errors", () => {
    expect(isLikelyUserCancellation(new Error("User cancelled picker"))).toBe(
      true,
    );
    expect(isLikelyUserCancellation("Picker dismissed")).toBe(true);
    expect(isLikelyUserCancellation(new Error("Permission denied"))).toBe(
      false,
    );
  });
});
