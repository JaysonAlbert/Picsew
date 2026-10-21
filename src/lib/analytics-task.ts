import { trackEvent } from "./analytics";
import {
  ANALYTICS_EVENTS as E,
  type AnalyticsEventParams,
  type ExportMethod,
  type TaskErrorCode,
  type TaskStage,
} from "./analytics-events";

// One accepted file, held in memory only. No cross-session ID or persistence.
export class AnalyticsTask {
  private stage: TaskStage = "import";
  private importedOnce = false;
  private generating = false;
  private generatedOnce = false;
  private finished = false;
  private stageStartedAt: number;
  private importStartedAt: number;
  private metadata: AnalyticsEventParams = {};

  constructor(
    private file: AnalyticsEventParams,
    private emit = trackEvent,
    private now = () => performance.now(),
  ) {
    this.stageStartedAt = now();
    this.importStartedAt = this.stageStartedAt;
    this.emit(E.uploadStarted, file);
  }
  private params(extra: AnalyticsEventParams = {}) {
    return { ...this.file, ...this.metadata, ...extra };
  }
  private finish(outcome: "dispatched" | "error" | "cancelled") {
    if (this.finished) return;
    this.finished = true;
    this.emit(
      E.taskFinished,
      this.params({ task_stage: this.stage, task_outcome: outcome }),
    );
  }
  imported(metadata: AnalyticsEventParams) {
    if (this.finished || this.importedOnce || this.generatedOnce) return;
    this.importedOnce = true;
    this.metadata = metadata;
    this.emit(
      E.uploadCompleted,
      this.params({ stage_time_ms: this.now() - this.importStartedAt }),
    );
  }
  startGeneration() {
    if (this.finished || this.generating || this.generatedOnce) return;
    this.stage = "generate";
    this.generating = true;
    this.stageStartedAt = this.now();
    this.emit(E.processingStarted, this.params());
  }
  generated() {
    if (this.finished || !this.generating || this.generatedOnce) return;
    this.generatedOnce = true;
    this.generating = false;
    this.emit(
      E.processingCompleted,
      this.params({ processing_time_ms: this.now() - this.stageStartedAt }),
    );
    this.stage = "export";
  }
  error(stage: TaskStage, code: TaskErrorCode, method?: ExportMethod) {
    if (
      (this.finished && stage !== "export") ||
      (stage === "import" &&
        (this.importedOnce || this.generating || this.generatedOnce))
    )
      return;
    this.emit(
      stage === "generate" ? E.processingFailed : E.taskError,
      this.params({
        task_stage: stage,
        error_code: code,
        export_method: method,
        ...(stage === "generate"
          ? { processing_time_ms: this.now() - this.stageStartedAt }
          : {}),
      }),
    );
    if (stage !== "export") {
      this.stage = stage;
      this.finish("error");
    }
  }
  requestExport(method: ExportMethod) {
    if (!this.generatedOnce) return;
    // Repeated export actions are real actions; task_finished is still emitted once.
    this.emit(E.exportStarted, this.params({ export_method: method }));
  }
  dispatched(method: ExportMethod) {
    if (!this.generatedOnce) return;
    this.emit(E.exportCompleted, this.params({ export_method: method }));
    this.finish("dispatched");
  }
  cancel(reason: "clear" | "replace" | "reset" | "share_cancelled") {
    if (reason === "share_cancelled") {
      this.emit(
        E.taskCancelled,
        this.params({
          task_stage: "export",
          cancel_reason: reason,
          export_method: "share",
        }),
      );
      return; // Share cancellation can be retried; it does not finish the task.
    }
    if (this.finished) return;
    this.emit(
      E.taskCancelled,
      this.params({ task_stage: this.stage, cancel_reason: reason }),
    );
    this.finish("cancelled");
  }
}
