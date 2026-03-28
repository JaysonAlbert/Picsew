import {
  feedbackStorageRecordSchema,
  feedbackSubmissionSchema,
  type FeedbackStorageRecord,
  type FeedbackSubmission,
} from "./feedback";

const FEEDBACK_QUEUE_STORAGE_KEY = "picsew_feedback_queue";

export type FeedbackSubmitResult = {
  mode: "remote" | "local_queue";
  record: FeedbackStorageRecord;
};

const trimValue = (value: string, maxLength: number) =>
  value.slice(0, maxLength);

export const getFeedbackAppVersion = () =>
  import.meta.env.VITE_APP_VERSION || "web-dev";

const getFeedbackAuthHeaders = () => {
  const anonKey = import.meta.env.VITE_FEEDBACK_ANON_KEY;
  if (!anonKey) {
    return {} as Record<string, string>;
  }

  return {
    Authorization: `Bearer ${anonKey}`,
    apikey: anonKey,
  } as Record<string, string>;
};

export const getBrowserFeedbackContext = () => ({
  browserOrAppVersion:
    typeof navigator !== "undefined"
      ? trimValue(navigator.userAgent, 64)
      : undefined,
  osVersion:
    typeof navigator !== "undefined"
      ? trimValue(navigator.platform || "unknown", 64)
      : undefined,
});

const getFeedbackStorageSource = () => "web_form" as const;

const getStoredQueue = () => {
  if (typeof localStorage === "undefined") {
    return [] as FeedbackStorageRecord[];
  }

  const raw = localStorage.getItem(FEEDBACK_QUEUE_STORAGE_KEY);
  if (!raw) {
    return [] as FeedbackStorageRecord[];
  }

  try {
    const parsed = JSON.parse(raw) as unknown[];
    return parsed
      .map((item) => feedbackStorageRecordSchema.safeParse(item))
      .filter((result) => result.success)
      .map((result) => result.data);
  } catch {
    return [] as FeedbackStorageRecord[];
  }
};

const persistToLocalQueue = (record: FeedbackStorageRecord) => {
  if (typeof localStorage === "undefined") {
    return;
  }

  const existing = getStoredQueue();
  localStorage.setItem(
    FEEDBACK_QUEUE_STORAGE_KEY,
    JSON.stringify([record, ...existing].slice(0, 50)),
  );
};

export const getQueuedFeedbackRecords = () => getStoredQueue();

export const submitFeedback = async (
  submission: FeedbackSubmission,
): Promise<FeedbackSubmitResult> => {
  const parsedSubmission = feedbackSubmissionSchema.parse(submission);
  const record = feedbackStorageRecordSchema.parse({
    ...parsedSubmission,
    id: crypto.randomUUID(),
    createdAt: new Date().toISOString(),
    status: "new",
    source: getFeedbackStorageSource(),
  });

  const endpoint = import.meta.env.VITE_FEEDBACK_ENDPOINT;
  if (endpoint) {
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      ...getFeedbackAuthHeaders(),
    };

    const response = await fetch(endpoint, {
      method: "POST",
      headers,
      body: JSON.stringify(record),
    });

    if (!response.ok) {
      throw new Error(
        `Feedback submission failed with status ${response.status}`,
      );
    }

    return {
      mode: "remote",
      record,
    };
  }

  persistToLocalQueue(record);
  return {
    mode: "local_queue",
    record,
  };
};
