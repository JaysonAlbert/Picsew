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
          submitClassName="h-12 rounded-2xl bg-gradient-to-r from-blue-600 via-blue-500 to-cyan-500 text-base font-medium shadow-[0_16px_30px_-18px_rgba(37,99,235,0.8)] hover:from-blue-700 hover:via-blue-600 hover:to-cyan-600"
          cancelClassName="h-12 rounded-2xl"
        />
      </Card>
    </div>
  );
}
