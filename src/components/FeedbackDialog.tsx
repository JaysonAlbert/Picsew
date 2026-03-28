import { useMemo, useState, type FormEvent } from "react";
import { MessageSquareMore, Loader2 } from "lucide-react";
import { useTranslation } from "react-i18next";
import { trackEvent } from "../lib/analytics";
import { ANALYTICS_EVENTS } from "../lib/analytics-events";
import {
  getBrowserFeedbackContext,
  getFeedbackAppVersion,
  submitFeedback,
} from "../lib/feedback-client";
import type { FeedbackSeverity, FeedbackStage } from "../lib/feedback";
import { Button } from "./ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "./ui/dialog";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "./ui/select";
import { Textarea } from "./ui/textarea";

type FeedbackCategory = "bug_report" | "feature_request" | "processing_failure";

type VideoMetadata = {
  durationSeconds?: number;
  width?: number;
  height?: number;
};

interface FeedbackDialogProps {
  currentStep: "upload" | "processing" | "preview";
  videoMetadata: VideoMetadata;
  lastProcessingError: string | null;
  processingLogs: string[];
}

const DEFAULT_CATEGORY: FeedbackCategory = "bug_report";
const DEFAULT_SEVERITY: FeedbackSeverity = "major";

const getDefaultStage = (
  step: FeedbackDialogProps["currentStep"],
): FeedbackStage => {
  switch (step) {
    case "processing":
      return "processing";
    case "preview":
      return "preview";
    default:
      return "upload";
  }
};

export function FeedbackDialog({
  currentStep,
  videoMetadata,
  lastProcessingError,
  processingLogs,
}: FeedbackDialogProps) {
  const { t, i18n } = useTranslation();
  const [open, setOpen] = useState(false);
  const [category, setCategory] = useState<FeedbackCategory>(DEFAULT_CATEGORY);
  const [stage, setStage] = useState<FeedbackStage>(
    getDefaultStage(currentStep),
  );
  const [severity, setSeverity] = useState<FeedbackSeverity>(DEFAULT_SEVERITY);
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [useCase, setUseCase] = useState("");
  const [requestedFeature, setRequestedFeature] = useState("");
  const [errorMessage, setErrorMessage] = useState(lastProcessingError || "");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitMessage, setSubmitMessage] = useState<string | null>(null);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const logExcerpt = useMemo(
    () => processingLogs.join("\n").slice(0, 12000),
    [processingLogs],
  );

  const resetForm = (preserveMessages = false) => {
    setCategory(DEFAULT_CATEGORY);
    setStage(getDefaultStage(currentStep));
    setSeverity(DEFAULT_SEVERITY);
    setEmail("");
    setMessage("");
    setUseCase("");
    setRequestedFeature("");
    setErrorMessage(lastProcessingError || "");
    if (!preserveMessages) {
      setSubmitMessage(null);
      setSubmitError(null);
    }
  };

  const handleOpenChange = (nextOpen: boolean) => {
    setOpen(nextOpen);
    if (nextOpen) {
      setStage(getDefaultStage(currentStep));
      setErrorMessage(lastProcessingError || "");
      setSubmitMessage(null);
      setSubmitError(null);
      trackEvent(ANALYTICS_EVENTS.feedbackOpened, {
        feedback_category: category,
        feedback_stage: getDefaultStage(currentStep),
      });
    }
  };

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setIsSubmitting(true);
    setSubmitError(null);
    setSubmitMessage(null);

    try {
      const commonPayload = {
        platform: "web" as const,
        appVersion: getFeedbackAppVersion(),
        locale: i18n.resolvedLanguage || i18n.language || "en",
        email,
        message,
        ...getBrowserFeedbackContext(),
      };

      const payload =
        category === "feature_request"
          ? {
              ...commonPayload,
              category,
              useCase,
              requestedFeature,
              willingToTestBeta: true,
            }
          : category === "processing_failure"
            ? {
                ...commonPayload,
                category,
                stage,
                errorMessage,
                memoryMode: /iPad|iPhone|iPod/.test(navigator.userAgent)
                  ? ("ios_safe" as const)
                  : ("default" as const),
                videoDurationSeconds: videoMetadata.durationSeconds,
                videoWidth: videoMetadata.width,
                videoHeight: videoMetadata.height,
                logExcerpt,
              }
            : {
                ...commonPayload,
                category,
                stage,
                severity,
                videoDurationSeconds: videoMetadata.durationSeconds,
                videoWidth: videoMetadata.width,
                videoHeight: videoMetadata.height,
                logExcerpt,
              };

      const result = await submitFeedback(payload);
      trackEvent(ANALYTICS_EVENTS.feedbackSubmitted, {
        feedback_category: category,
        feedback_mode: result.mode,
      });
      resetForm(true);
      setSubmitMessage(
        result.mode === "remote"
          ? t("feedback.success.remote")
          : t("feedback.success.localQueue"),
      );
    } catch (error) {
      setSubmitError(
        error instanceof Error ? error.message : t("feedback.error.generic"),
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogTrigger asChild>
        <Button variant="outline" size="sm">
          <MessageSquareMore className="w-4 h-4" />
          {t("feedback.trigger")}
        </Button>
      </DialogTrigger>
      <DialogContent className="max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{t("feedback.title")}</DialogTitle>
          <DialogDescription>{t("feedback.description")}</DialogDescription>
        </DialogHeader>

        <form className="space-y-4" onSubmit={handleSubmit}>
          <div className="space-y-2">
            <Label htmlFor="feedback-category">
              {t("feedback.category.label")}
            </Label>
            <Select
              value={category}
              onValueChange={(value) => setCategory(value as FeedbackCategory)}
            >
              <SelectTrigger id="feedback-category">
                <SelectValue placeholder={t("feedback.category.placeholder")} />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="bug_report">
                  {t("feedback.category.options.bugReport")}
                </SelectItem>
                <SelectItem value="feature_request">
                  {t("feedback.category.options.featureRequest")}
                </SelectItem>
                <SelectItem value="processing_failure">
                  {t("feedback.category.options.processingFailure")}
                </SelectItem>
              </SelectContent>
            </Select>
          </div>

          {(category === "bug_report" || category === "processing_failure") && (
            <div className="space-y-2">
              <Label htmlFor="feedback-stage">
                {t("feedback.stage.label")}
              </Label>
              <Select
                value={stage}
                onValueChange={(value) => setStage(value as FeedbackStage)}
              >
                <SelectTrigger id="feedback-stage">
                  <SelectValue placeholder={t("feedback.stage.placeholder")} />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="upload">
                    {t("feedback.stage.upload")}
                  </SelectItem>
                  <SelectItem value="processing">
                    {t("feedback.stage.processing")}
                  </SelectItem>
                  <SelectItem value="preview">
                    {t("feedback.stage.preview")}
                  </SelectItem>
                  <SelectItem value="export">
                    {t("feedback.stage.export")}
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>
          )}

          {category === "bug_report" && (
            <div className="space-y-2">
              <Label htmlFor="feedback-severity">
                {t("feedback.severity.label")}
              </Label>
              <Select
                value={severity}
                onValueChange={(value) =>
                  setSeverity(value as FeedbackSeverity)
                }
              >
                <SelectTrigger id="feedback-severity">
                  <SelectValue
                    placeholder={t("feedback.severity.placeholder")}
                  />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="blocker">
                    {t("feedback.severity.blocker")}
                  </SelectItem>
                  <SelectItem value="major">
                    {t("feedback.severity.major")}
                  </SelectItem>
                  <SelectItem value="minor">
                    {t("feedback.severity.minor")}
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>
          )}

          {category === "feature_request" && (
            <>
              <div className="space-y-2">
                <Label htmlFor="feedback-use-case">
                  {t("feedback.useCase.label")}
                </Label>
                <Textarea
                  id="feedback-use-case"
                  value={useCase}
                  onChange={(event) => setUseCase(event.target.value)}
                  placeholder={t("feedback.useCase.placeholder")}
                  required
                  rows={3}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="feedback-requested-feature">
                  {t("feedback.requestedFeature.label")}
                </Label>
                <Textarea
                  id="feedback-requested-feature"
                  value={requestedFeature}
                  onChange={(event) => setRequestedFeature(event.target.value)}
                  placeholder={t("feedback.requestedFeature.placeholder")}
                  required
                  rows={3}
                />
              </div>
            </>
          )}

          {category === "processing_failure" && (
            <div className="space-y-2">
              <Label htmlFor="feedback-error-message">
                {t("feedback.errorMessage.label")}
              </Label>
              <Textarea
                id="feedback-error-message"
                value={errorMessage}
                onChange={(event) => setErrorMessage(event.target.value)}
                placeholder={t("feedback.errorMessage.placeholder")}
                required
                rows={3}
              />
            </div>
          )}

          <div className="space-y-2">
            <Label htmlFor="feedback-message">
              {t("feedback.message.label")}
            </Label>
            <Textarea
              id="feedback-message"
              value={message}
              onChange={(event) => setMessage(event.target.value)}
              placeholder={t("feedback.message.placeholder")}
              required
              rows={4}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="feedback-email">{t("feedback.email.label")}</Label>
            <Input
              id="feedback-email"
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder={t("feedback.email.placeholder")}
            />
          </div>

          <div className="rounded-xl border bg-gray-50 p-3 text-xs text-gray-600">
            <p>{t("feedback.contextTitle")}</p>
            <p>
              {t("feedback.contextMeta", {
                duration:
                  typeof videoMetadata.durationSeconds === "number"
                    ? videoMetadata.durationSeconds.toFixed(1)
                    : "-",
                width: videoMetadata.width ?? "-",
                height: videoMetadata.height ?? "-",
                logs: processingLogs.length,
              })}
            </p>
          </div>

          {submitMessage && (
            <div className="rounded-xl border border-green-200 bg-green-50 px-3 py-2 text-sm text-green-800">
              {submitMessage}
            </div>
          )}

          {submitError && (
            <div className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
              {submitError}
            </div>
          )}

          <div className="flex gap-3 pt-2">
            <Button type="submit" className="flex-1" disabled={isSubmitting}>
              {isSubmitting ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  {t("feedback.submitting")}
                </>
              ) : (
                t("feedback.submit")
              )}
            </Button>
            <Button
              type="button"
              variant="outline"
              onClick={() => {
                setOpen(false);
                resetForm();
              }}
            >
              {t("feedback.cancel")}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
