import { describe, expect, it, vi } from "vitest";
import { AnalyticsTask } from "./analytics-task";

const setup = () => {
  const emit = vi.fn();
  let time = 0;
  const task = new AnalyticsTask({ video_extension: "mp4" }, emit, () => time);
  return {
    task,
    emit,
    tick: (ms: number) => {
      time += ms;
    },
    names: () => emit.mock.calls.map((c) => c[0]),
  };
};

describe("one in-memory accepted-file task", () => {
  it("records real transitions once, with bounded metadata delegated to transport", () => {
    const { task, emit, tick, names } = setup();
    tick(12);
    task.imported({ video_duration_bucket: "<=30" });
    task.imported({});
    task.startGeneration();
    task.startGeneration();
    tick(50);
    task.generated();
    task.generated();
    task.requestExport("download");
    task.dispatched("download");
    task.cancel("reset");
    expect(names()).toEqual([
      "upload_started",
      "upload_completed",
      "processing_started",
      "processing_completed",
      "export_started",
      "export_completed",
      "task_finished",
    ]);
    expect(emit).toHaveBeenCalledWith(
      "processing_completed",
      expect.objectContaining({ processing_time_ms: 50 }),
    );
    expect(emit).toHaveBeenCalledWith(
      "task_finished",
      expect.objectContaining({ task_outcome: "dispatched" }),
    );
  });
  it("records metadata that arrives while generation waits, using import latency", () => {
    const { task, emit, tick } = setup();
    tick(10);
    task.startGeneration();
    tick(20);
    task.imported({ video_duration_bucket: "<=30" });
    expect(emit).toHaveBeenCalledWith(
      "upload_completed",
      expect.objectContaining({ stage_time_ms: 30 }),
    );
  });
  it("keeps repeated export actions but only one task outcome", () => {
    const { task, names } = setup();
    task.startGeneration();
    task.generated();
    task.requestExport("download");
    task.dispatched("download");
    task.requestExport("share");
    task.dispatched("share");
    expect(names().filter((n) => n === "export_completed")).toHaveLength(2);
    expect(names().filter((n) => n === "task_finished")).toHaveLength(1);
  });
  it("reports metadata failure without an import success or cancellation", () => {
    const { task, names, emit } = setup();
    task.error("import", "metadata_unreadable");
    task.error("import", "metadata_unreadable");
    task.imported({});
    task.cancel("reset");
    expect(names()).toEqual(["upload_started", "task_error", "task_finished"]);
    expect(emit).toHaveBeenCalledWith(
      "task_error",
      expect.objectContaining({ error_code: "metadata_unreadable" }),
    );
  });
  it("retains the legacy generate-error event without duplicating task_error", () => {
    const { task, names } = setup();
    task.startGeneration();
    task.error("generate", "processing_failed");
    task.cancel("reset");
    task.generated();
    expect(names()).toEqual([
      "upload_started",
      "processing_started",
      "processing_failed",
      "task_finished",
    ]);
  });
  it("permits retry after export errors and explicit share cancellation", () => {
    const { task, names } = setup();
    task.startGeneration();
    task.generated();
    task.requestExport("share");
    task.cancel("share_cancelled");
    expect(names()).not.toContain("export_completed");
    expect(names()).not.toContain("task_finished");
    task.requestExport("download");
    task.error("export", "export_failed", "download");
    task.requestExport("download");
    task.dispatched("download");
    expect(names().filter((n) => n === "task_finished")).toHaveLength(1);
  });
  it.each(["clear", "replace", "reset"] as const)(
    "records %s as cancellation, without inventing success",
    (reason) => {
      const { task, names, emit } = setup();
      task.cancel(reason);
      task.cancel(reason);
      task.imported({});
      expect(names()).toEqual([
        "upload_started",
        "task_cancelled",
        "task_finished",
      ]);
      expect(emit).toHaveBeenCalledWith(
        "task_finished",
        expect.objectContaining({ task_outcome: "cancelled" }),
      );
    },
  );
  it("does not synthesize an outcome for unknown unfinished work or a dispatch without generation", () => {
    const { task, names } = setup();
    task.dispatched("download");
    expect(names()).toEqual(["upload_started"]);
  });
});
