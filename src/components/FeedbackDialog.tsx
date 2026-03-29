import type { ReactNode } from "react";
import { MessageSquareMore } from "lucide-react";
import { useTranslation } from "react-i18next";
import { trackEvent } from "../lib/analytics";
import { ANALYTICS_EVENTS } from "../lib/analytics-events";
import { Button } from "./ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "./ui/dialog";
import { FeedbackForm, getDefaultFeedbackStage } from "./FeedbackForm";

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
  compact?: boolean;
  triggerClassName?: string;
  icon?: ReactNode;
}

export function FeedbackDialog({
  currentStep,
  videoMetadata,
  lastProcessingError,
  processingLogs,
  compact = false,
  triggerClassName = "",
  icon,
}: FeedbackDialogProps) {
  const { t } = useTranslation();

  return (
    <Dialog
      onOpenChange={(nextOpen) => {
        if (nextOpen) {
          trackEvent(ANALYTICS_EVENTS.feedbackOpened, {
            feedback_stage: getDefaultFeedbackStage(currentStep),
          });
        }
      }}
    >
      <DialogTrigger asChild>
        <Button
          variant="outline"
          size={compact ? "icon" : "sm"}
          className={`${compact ? "h-10 w-10 rounded-xl" : ""} ${triggerClassName}`.trim()}
          title={t("feedback.trigger")}
        >
          {icon ?? <MessageSquareMore className="w-4 h-4" />}
          {compact ? (
            <span className="sr-only">{t("feedback.trigger")}</span>
          ) : (
            t("feedback.trigger")
          )}
        </Button>
      </DialogTrigger>
      <DialogContent className="max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{t("feedback.title")}</DialogTitle>
          <DialogDescription>{t("feedback.description")}</DialogDescription>
        </DialogHeader>

        <FeedbackForm
          currentStep={currentStep}
          videoMetadata={videoMetadata}
          lastProcessingError={lastProcessingError}
          processingLogs={processingLogs}
        />
      </DialogContent>
    </Dialog>
  );
}
