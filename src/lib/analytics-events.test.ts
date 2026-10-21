import { describe, expect, it } from "vitest";
import {
  getVideoFileAnalytics,
  getVideoMetadataAnalytics,
  sanitizeAnalyticsParams,
} from "./analytics-events";

describe("analytics privacy boundary", () => {
  it("categorizes known formats without transmitting names", () => {
    const params = getVideoFileAnalytics(
      new File(["secret screenshot text"], "alice@example.com.MOV", {
        type: "video/quicktime",
      }),
      "drop",
    );
    expect(params).toEqual({
      upload_source: "drop",
      video_extension: "mov",
      video_mime: "video/quicktime",
      video_size_mb_bucket: "<=10",
    });
  });
  it("bounds arbitrary extension, MIME, dimensions and invalid metadata", () => {
    expect(
      getVideoFileAnalytics(
        new File([], "secret.private", { type: "video/private-data" }),
      ),
    ).toMatchObject({ video_extension: "other", video_mime: "other" });
    expect(getVideoMetadataAnalytics(30, 1920, 1080)).toEqual({
      video_duration_bucket: "<=30",
      video_resolution_bucket: "<=1080",
    });
    expect(getVideoMetadataAnalytics(Infinity, -1, 720)).toEqual({
      video_duration_bucket: "unknown",
      video_resolution_bucket: "unknown",
    });
  });
  it("drops raw content, exception text, arbitrary keys and hostile enum values", () => {
    expect(
      sanitizeAnalyticsParams({
        error_message: "alice@example.com at blob:secret",
        file_name: "secret.mov",
        file_url: "blob:private",
        ocr: "private",
        task_id: "uuid",
        page_location: "https://host/?token=secret",
        video_extension: "private",
        video_width: 1234,
        feedback_category: "private",
        error_code: "processing_failed",
        task_stage: "generate",
      }),
    ).toEqual({ error_code: "processing_failed", task_stage: "generate" });
  });
  it("limits timing numbers and handles non-finite values", () => {
    expect(
      sanitizeAnalyticsParams({
        processing_time_ms: 8_000_000,
        stage_time_ms: 10.8,
      }),
    ).toEqual({ processing_time_ms: 3_600_000, stage_time_ms: 11 });
    expect(
      sanitizeAnalyticsParams({ processing_time_ms: NaN, stage_time_ms: -1 }),
    ).toEqual({});
  });
});
