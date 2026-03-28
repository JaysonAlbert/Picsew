export const ANALYTICS_EVENTS = {
  uploadStarted: "upload_started",
  uploadCompleted: "upload_completed",
  processingStarted: "processing_started",
  processingCompleted: "processing_completed",
  processingFailed: "processing_failed",
  previewShown: "preview_shown",
  exportStarted: "export_started",
  exportCompleted: "export_completed",
  feedbackOpened: "feedback_opened",
  feedbackSubmitted: "feedback_submitted",
} as const;

export type AnalyticsEventName =
  (typeof ANALYTICS_EVENTS)[keyof typeof ANALYTICS_EVENTS];

export type AnalyticsPrimitive = string | number | boolean | null | undefined;
export type AnalyticsEventParams = Record<string, AnalyticsPrimitive>;

export type VideoSelectionSource = "picker" | "drop";

const fileSizeBucketThresholdsMb = [10, 25, 50, 100, 250, 500];
const durationBucketThresholdsSec = [10, 30, 60, 120, 300];

const getBucketLabel = (value: number, thresholds: number[]) => {
  for (const threshold of thresholds) {
    if (value <= threshold) {
      return `<=${threshold}`;
    }
  }
  return `>${thresholds[thresholds.length - 1]}`;
};

const getFileExtension = (filename: string) => {
  const parts = filename.split(".");
  if (parts.length < 2) return "unknown";
  return parts[parts.length - 1]?.toLowerCase() || "unknown";
};

export const getVideoFileAnalytics = (
  file: File,
  source?: VideoSelectionSource,
): AnalyticsEventParams => ({
  upload_source: source,
  video_mime: file.type || "unknown",
  video_extension: getFileExtension(file.name),
  video_size_mb_bucket: getBucketLabel(
    Number((file.size / 1024 / 1024).toFixed(2)),
    fileSizeBucketThresholdsMb,
  ),
});

export const getVideoMetadataAnalytics = (
  durationSeconds?: number,
  width?: number,
  height?: number,
): AnalyticsEventParams => ({
  video_duration_bucket:
    typeof durationSeconds === "number" && Number.isFinite(durationSeconds)
      ? getBucketLabel(durationSeconds, durationBucketThresholdsSec)
      : undefined,
  video_width: width,
  video_height: height,
  video_resolution_bucket:
    width && height
      ? `${Math.min(width, height)}x${Math.max(width, height)}`
      : undefined,
});

export const sanitizeAnalyticsErrorMessage = (error: unknown) => {
  const message =
    error instanceof Error
      ? error.message
      : typeof error === "string"
        ? error
        : String(error);

  return message.slice(0, 200);
};
