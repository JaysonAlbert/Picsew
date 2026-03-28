import { beforeEach, describe, expect, it, vi } from "vitest";
import { getQueuedFeedbackRecords, submitFeedback } from "./feedback-client";

type LocalStorageMock = {
  clear: () => void;
  getItem: (key: string) => string | null;
  removeItem: (key: string) => void;
  setItem: (key: string, value: string) => void;
};

const createLocalStorageMock = (): LocalStorageMock => {
  const store = new Map<string, string>();

  return {
    clear: () => store.clear(),
    getItem: (key: string) => store.get(key) ?? null,
    removeItem: (key: string) => store.delete(key),
    setItem: (key: string, value: string) => {
      store.set(key, value);
    },
  };
};

describe("feedback-client", () => {
  beforeEach(() => {
    vi.unstubAllEnvs();
    vi.stubEnv("VITE_FEEDBACK_ENDPOINT", "");
    Object.defineProperty(globalThis, "localStorage", {
      value: createLocalStorageMock(),
      configurable: true,
      writable: true,
    });
  });

  it("stores feedback locally when no endpoint is configured", async () => {
    const result = await submitFeedback({
      category: "bug_report",
      platform: "web",
      appVersion: "1.0.0",
      locale: "en",
      message: "Export failed after processing finished.",
    });

    expect(result.mode).toBe("local_queue");
    expect(getQueuedFeedbackRecords()).toHaveLength(1);
  });
});
