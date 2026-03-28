import { describe, expect, it } from "vitest";
import {
  bugReportFeedbackSchema,
  featureRequestFeedbackSchema,
  feedbackStorageRecordSchema,
  processingFailureFeedbackSchema,
} from "./feedback";

describe("feedback schemas", () => {
  it("accepts a bug report payload", () => {
    const result = bugReportFeedbackSchema.safeParse({
      category: "bug_report",
      platform: "web",
      appVersion: "1.0.0",
      locale: "en",
      message: "The exported image is missing the footer section.",
      stage: "export",
      severity: "major",
    });

    expect(result.success).toBe(true);
  });

  it("accepts a feature request payload", () => {
    const result = featureRequestFeedbackSchema.safeParse({
      category: "feature_request",
      platform: "ios",
      appVersion: "1.0.0",
      locale: "zh-CN",
      message: "I often process long chat recordings and want templates.",
      useCase: "Turn long chat recordings into polished screenshots.",
      requestedFeature: "Preset export styles for chat screenshots.",
      frequency: "often",
      willingToTestBeta: true,
    });

    expect(result.success).toBe(true);
  });

  it("rejects processing failure payloads without an error message", () => {
    const result = processingFailureFeedbackSchema.safeParse({
      category: "processing_failure",
      platform: "web",
      appVersion: "1.0.0",
      locale: "en",
      message: "Processing crashed on a long recording.",
      stage: "processing",
    });

    expect(result.success).toBe(false);
  });

  it("accepts a persisted feedback record", () => {
    const result = feedbackStorageRecordSchema.safeParse({
      id: "ed84ccca-4fc3-4256-b24b-c4c452910ea4",
      createdAt: "2026-03-29T10:00:00.000Z",
      status: "new",
      source: "web_form",
      category: "processing_failure",
      platform: "web",
      appVersion: "1.0.0",
      locale: "en",
      message: "Processing failed on a long recording.",
      stage: "processing",
      errorMessage: "OpenCV out of memory",
    });

    expect(result.success).toBe(true);
  });
});
