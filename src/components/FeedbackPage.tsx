import { useTranslation } from "react-i18next";
import { Card } from "./ui/card";
import { FeedbackForm } from "./FeedbackForm";

type VideoMetadata = {
  durationSeconds?: number;
  width?: number;
  height?: number;
};

interface FeedbackPageProps {
  currentStep: "upload" | "processing" | "preview";
  videoMetadata: VideoMetadata;
  lastProcessingError: string | null;
  processingLogs: string[];
  onBack: () => void;
}

export function FeedbackPage({
  currentStep,
  videoMetadata,
  lastProcessingError,
  processingLogs,
  onBack,
}: FeedbackPageProps) {
  const { t } = useTranslation();

  return (
    <div className="mx-auto max-w-md">
      <Card
        className="app-stage-card overflow-hidden"
        data-testid="feedback-page"
      >
        <div className="app-stage-header">
          <p className="app-stage-kicker">{t("feedback.page.kicker")}</p>
          <h2 className="app-stage-title">{t("feedback.title")}</h2>
          <p className="app-stage-description">
            {t("feedback.page.description")}
          </p>
        </div>

        <FeedbackForm
          currentStep={currentStep}
          videoMetadata={videoMetadata}
          lastProcessingError={lastProcessingError}
          processingLogs={processingLogs}
          onCancel={onBack}
          submitClassName="app-primary-action"
          cancelClassName="app-secondary-action"
        />
      </Card>
    </div>
  );
}
