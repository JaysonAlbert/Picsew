import { Film, Image, Sparkles } from "lucide-react";
import { useTranslation } from "react-i18next";
import { Button } from "./ui/button";

interface OnboardingDialogProps {
  open: boolean;
  onSkip: () => void;
  onStart: () => void;
}

export function OnboardingDialog({
  open,
  onSkip,
  onStart,
}: OnboardingDialogProps) {
  const { t } = useTranslation();

  if (!open) {
    return null;
  }

  const steps = [
    {
      icon: Film,
      title: t("app.onboarding.steps.import.title"),
      description: t("app.onboarding.steps.import.description"),
    },
    {
      icon: Sparkles,
      title: t("app.onboarding.steps.stitch.title"),
      description: t("app.onboarding.steps.stitch.description"),
    },
    {
      icon: Image,
      title: t("app.onboarding.steps.save.title"),
      description: t("app.onboarding.steps.save.description"),
    },
  ];

  return (
    <div className="app-onboarding-overlay">
      <div
        className="app-onboarding-dialog"
        role="dialog"
        aria-modal="true"
        aria-label={t("app.onboarding.title")}
        data-testid="app-onboarding"
      >
        <div className="app-onboarding-header">
          <h2 className="app-stage-title">{t("app.onboarding.title")}</h2>
          <p className="app-stage-description">
            {t("app.onboarding.subtitle")}
          </p>
        </div>

        <div className="app-onboarding-steps">
          {steps.map((step) => {
            const Icon = step.icon;
            return (
              <div key={step.title} className="app-onboarding-step">
                <div className="app-onboarding-step-icon">
                  <Icon className="h-4.5 w-4.5" />
                </div>
                <div className="min-w-0 flex-1">
                  <h3 className="app-onboarding-step-title">{step.title}</h3>
                  <p className="app-onboarding-step-description">
                    {step.description}
                  </p>
                </div>
              </div>
            );
          })}
        </div>

        <div className="app-onboarding-actions">
          <Button
            type="button"
            variant="ghost"
            className="app-secondary-action product-clear"
            onClick={onSkip}
          >
            {t("app.onboarding.skip")}
          </Button>
          <Button
            type="button"
            className="app-primary-action"
            onClick={onStart}
          >
            {t("app.onboarding.start")}
          </Button>
        </div>
      </div>
    </div>
  );
}
