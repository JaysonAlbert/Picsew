export const ANALYTICS_EVENTS = {
  uploadStarted: "upload_started", // import_start
  uploadCompleted: "upload_completed", // import_success
  processingStarted: "processing_started", // generate_start
  processingCompleted: "processing_completed", // generate_success
  processingFailed: "processing_failed", // task_error, generate stage (legacy)
  previewShown: "preview_shown",
  exportStarted: "export_started", // export_request
  exportCompleted: "export_completed", // export_dispatch, never disk persistence
  taskError: "task_error", // import/export errors; generation keeps legacy name
  taskCancelled: "task_cancelled",
  taskFinished: "task_finished", // once per accepted-file task
  feedbackOpened: "feedback_opened",
  feedbackSubmitted: "feedback_submitted",
} as const;

export type AnalyticsEventName =
  (typeof ANALYTICS_EVENTS)[keyof typeof ANALYTICS_EVENTS];
export type AnalyticsPrimitive = string | number | boolean | null | undefined;
export type AnalyticsEventParams = Record<string, AnalyticsPrimitive>;
export type VideoSelectionSource =
  | "picker"
  | "drop"
  | "native_photos"
  | "native_files";
export type TaskStage = "import" | "generate" | "export";
export type TaskErrorCode =
  | "metadata_unreadable"
  | "processing_failed"
  | "empty_output"
  | "export_failed"
  | "resources_unavailable";
export type ExportMethod = "download" | "share";

const fileSizes = [10, 25, 50, 100, 250, 500];
const durations = [10, 30, 60, 120, 300];
const bucketLabels = (thresholds: number[]) => [
  ...thresholds.map((n) => `<=${n}`),
  `>${thresholds.at(-1)}`,
  "unknown",
];
const getBucket = (value: number | undefined, thresholds: number[]) => {
  if (value === undefined || !Number.isFinite(value) || value < 0)
    return "unknown";
  return thresholds.find((n) => value <= n) !== undefined
    ? `<=${thresholds.find((n) => value <= n)}`
    : `>${thresholds.at(-1)}`;
};

export const getVideoFileAnalytics = (
  file: File,
  source?: VideoSelectionSource,
): AnalyticsEventParams => {
  // Only finite categories leave this module; never return an arbitrary extension/MIME.
  const extension = file.name.split(".").at(-1)?.toLowerCase();
  const format = ["mp4", "mov", "webm", "m4v", "avi", "mkv"].includes(
    extension ?? "",
  )
    ? extension
    : "other";
  return {
    upload_source: source,
    video_extension: format,
    video_mime: [
      "video/mp4",
      "video/quicktime",
      "video/webm",
      "video/x-m4v",
      "video/x-msvideo",
      "video/x-matroska",
    ].includes(file.type)
      ? file.type
      : "other",
    video_size_mb_bucket: getBucket(file.size / 1024 / 1024, fileSizes),
  };
};

export const getVideoMetadataAnalytics = (
  duration?: number,
  width?: number,
  height?: number,
): AnalyticsEventParams => ({
  video_duration_bucket: getBucket(duration, durations),
  video_resolution_bucket:
    width &&
    height &&
    Number.isFinite(width) &&
    Number.isFinite(height) &&
    width > 0 &&
    height > 0
      ? getBucket(Math.min(width, height), [480, 720, 1080, 1440, 2160])
      : "unknown",
});

const enumParams: Record<string, readonly string[]> = {
  upload_source: ["picker", "drop", "native_photos", "native_files"],
  video_extension: ["mp4", "mov", "webm", "m4v", "avi", "mkv", "other"],
  video_mime: [
    "video/mp4",
    "video/quicktime",
    "video/webm",
    "video/x-m4v",
    "video/x-msvideo",
    "video/x-matroska",
    "other",
  ],
  video_size_mb_bucket: bucketLabels(fileSizes),
  video_duration_bucket: bucketLabels(durations),
  video_resolution_bucket: bucketLabels([480, 720, 1080, 1440, 2160]),
  error_code: [
    "metadata_unreadable",
    "processing_failed",
    "empty_output",
    "export_failed",
    "resources_unavailable",
  ],
  task_stage: ["import", "generate", "export"],
  export_method: ["download", "share"],
  task_outcome: ["dispatched", "error", "cancelled"],
  cancel_reason: ["clear", "replace", "reset", "share_cancelled"],
  feedback_stage: ["upload", "processing", "preview", "export"],
  feedback_category: ["bug_report", "feature_request", "processing_failure"],
  feedback_mode: ["remote", "local_queue"],
};

// Runtime boundary, including callers that bypass TypeScript. Unknown keys are dropped.
export const sanitizeAnalyticsParams = (
  params: AnalyticsEventParams,
): AnalyticsEventParams => {
  const safe: AnalyticsEventParams = {};
  for (const [key, value] of Object.entries(params)) {
    if (
      typeof value === "string" &&
      Object.hasOwn(enumParams, key) &&
      enumParams[key]!.includes(value)
    )
      safe[key] = value;
    if (
      ["processing_time_ms", "stage_time_ms"].includes(key) &&
      typeof value === "number" &&
      Number.isFinite(value) &&
      value >= 0
    ) {
      safe[key] = Math.min(Math.round(value), 3_600_000);
    }
  }
  return safe;
};
