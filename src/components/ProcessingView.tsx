import { useTranslation } from "react-i18next";
import { Card } from "./ui/card";

interface ProcessingViewProps {
  progress: number;
}

export function ProcessingView({ progress }: ProcessingViewProps) {
  const { t } = useTranslation();
  const value = Number.isFinite(progress)
    ? Math.min(100, Math.max(0, Math.round(progress)))
    : 0;
  const stage =
    value < 10
      ? "preparing"
      : value < 30
        ? "extracting"
        : value < 50
          ? "finding"
          : value < 70
            ? "selecting"
            : value < 85
              ? "filtering"
              : value < 95
                ? "stitching"
                : "generating";
  return (
    <div className="product-route">
      <Card
        data-testid="processing-stage-card"
        className="app-stage-card product-processing-stage"
      >
        <div
          className="product-progress"
          role="progressbar"
          aria-label={t("processing.title")}
          aria-valuemin={0}
          aria-valuemax={100}
          aria-valuenow={value}
        >
          <svg viewBox="0 0 160 160" aria-hidden="true">
            <circle className="product-progress-track" cx="80" cy="80" r="70" />
            <circle
              className="product-progress-value"
              cx="80"
              cy="80"
              r="70"
              pathLength="100"
              strokeDasharray="100"
              strokeDashoffset={100 - value}
            />
          </svg>
          <span aria-hidden="true">{value}%</span>
        </div>
        <p className="product-progress-stage" aria-live="polite">
          {t(`processing.stages.${stage}`)}
        </p>
        <p className="product-caption">{t("processing.keepOpen")}</p>
      </Card>
    </div>
  );
}
