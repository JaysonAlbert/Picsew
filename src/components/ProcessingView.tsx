import { Loader2, Film, Scan, Layers, Blend, Scissors } from "lucide-react";
import { useTranslation } from "react-i18next";
import { Card } from "./ui/card";
import { Progress } from "./ui/progress";

interface ProcessingViewProps {
  progress: number;
}

export function ProcessingView({ progress }: ProcessingViewProps) {
  const { t } = useTranslation();

  const getProcessingStage = () => {
    if (progress < 10)
      return { icon: Film, text: t("processing.stages.preparing") };
    if (progress < 30)
      return { icon: Film, text: t("processing.stages.extracting") };
    if (progress < 50)
      return { icon: Scan, text: t("processing.stages.finding") };
    if (progress < 70)
      return { icon: Scissors, text: t("processing.stages.selecting") };
    if (progress < 85)
      return { icon: Blend, text: t("processing.stages.filtering") };
    if (progress < 95)
      return { icon: Layers, text: t("processing.stages.stitching") };
    return { icon: Layers, text: t("processing.stages.generating") };
  };

  const stage = getProcessingStage();
  const StageIcon = stage.icon;

  return (
    <div className="mx-auto max-w-md">
      <Card
        data-testid="processing-stage-card"
        className="app-stage-card overflow-hidden p-6"
      >
        <div className="text-center">
          <div className="app-stage-header items-center text-center">
            <p className="app-stage-kicker">{t("app.flow.step2")}</p>
            <h2 className="app-stage-title">{t("processing.title")}</h2>
            <p className="app-stage-description">
              {t("processing.waitMessage")}
            </p>
          </div>

          <div className="processing-hero-orb">
            <div className="processing-hero-orb-core">
              <StageIcon className="h-10 w-10 text-blue-600" />
            </div>
            <Loader2 className="processing-hero-spinner h-24 w-24 text-blue-600" />
          </div>

          <div className="processing-progress-panel">
            <div className="mb-3 flex items-center justify-between text-sm">
              <span className="font-medium text-slate-700">{stage.text}</span>
              <span className="text-slate-400">{progress}%</span>
            </div>
            <Progress value={progress} className="h-2.5" />
            <p className="mt-3 text-sm text-slate-500">
              {t("processing.keepOpen")}
            </p>
          </div>
        </div>
      </Card>
    </div>
  );
}
