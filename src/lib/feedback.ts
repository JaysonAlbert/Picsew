import { z } from "zod";

export const feedbackPlatformSchema = z.enum(["web", "ios"]);
export const feedbackCategorySchema = z.enum([
  "bug_report",
  "feature_request",
  "processing_failure",
]);
export const feedbackStageSchema = z.enum([
  "upload",
  "processing",
  "preview",
  "export",
]);
export const feedbackSeveritySchema = z.enum(["blocker", "major", "minor"]);
export const feedbackFrequencySchema = z.enum(["once", "sometimes", "often"]);

const optionalString = z.string().trim().max(4000).optional();

const feedbackBaseSchema = z.object({
  platform: feedbackPlatformSchema,
  appVersion: z.string().trim().min(1).max(64),
  locale: z.string().trim().min(2).max(16),
  email: z.union([z.string().email(), z.literal("")]).optional(),
  message: z.string().trim().min(10).max(4000),
});

export const bugReportFeedbackSchema = feedbackBaseSchema.extend({
  category: z.literal("bug_report"),
  stage: feedbackStageSchema.optional(),
  severity: feedbackSeveritySchema.optional(),
  deviceModel: z.string().trim().max(120).optional(),
  osVersion: z.string().trim().max(64).optional(),
  browserOrAppVersion: z.string().trim().max(64).optional(),
  videoDurationSeconds: z.number().nonnegative().max(36000).optional(),
  videoWidth: z.number().int().positive().max(20000).optional(),
  videoHeight: z.number().int().positive().max(20000).optional(),
  logExcerpt: z.string().trim().max(12000).optional(),
  screenshotUrl: z.string().url().optional(),
  sampleVideoConsent: z.boolean().optional(),
});

export const featureRequestFeedbackSchema = feedbackBaseSchema.extend({
  category: z.literal("feature_request"),
  useCase: z.string().trim().min(5).max(1000),
  requestedFeature: z.string().trim().min(5).max(1000),
  frequency: feedbackFrequencySchema.optional(),
  willingToTestBeta: z.boolean().optional(),
});

export const processingFailureFeedbackSchema = feedbackBaseSchema.extend({
  category: z.literal("processing_failure"),
  stage: feedbackStageSchema,
  errorCode: z.string().trim().max(120).optional(),
  errorMessage: z.string().trim().min(1).max(1000),
  pipelineStep: z.string().trim().max(120).optional(),
  memoryMode: z.enum(["default", "ios_safe"]).optional(),
  videoDurationSeconds: z.number().nonnegative().max(36000).optional(),
  videoWidth: z.number().int().positive().max(20000).optional(),
  videoHeight: z.number().int().positive().max(20000).optional(),
  deviceModel: z.string().trim().max(120).optional(),
  osVersion: z.string().trim().max(64).optional(),
  browserOrAppVersion: z.string().trim().max(64).optional(),
  logExcerpt: z.string().trim().max(12000).optional(),
  sampleVideoConsent: z.boolean().optional(),
});

export const feedbackSubmissionSchema = z.discriminatedUnion("category", [
  bugReportFeedbackSchema,
  featureRequestFeedbackSchema,
  processingFailureFeedbackSchema,
]);

export const feedbackStorageRecordSchema = z
  .object({
    id: z.string().uuid(),
    createdAt: z.string().datetime(),
    status: z.enum(["new", "triaged", "closed"]),
    triageNotes: optionalString,
    source: z.enum(["web_form", "ios_form", "manual_import"]),
  })
  .and(feedbackSubmissionSchema);

export type FeedbackSubmission = z.infer<typeof feedbackSubmissionSchema>;
export type FeedbackStorageRecord = z.infer<typeof feedbackStorageRecordSchema>;
export type FeedbackStage = z.infer<typeof feedbackStageSchema>;
export type FeedbackSeverity = z.infer<typeof feedbackSeveritySchema>;
