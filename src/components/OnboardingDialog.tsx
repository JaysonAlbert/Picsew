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
          <p className="app-stage-kicker">{t("app.onboarding.kicker")}</p>
          <h2 className="app-stage-title">{t("app.onboarding.title")}</h2>
          <p className="app-stage-description">
            {t("app.onboarding.subtitle")}
          </p>
        </div>

        <div className="app-onboarding-steps">
          {steps.map((step, index) => {
            const Icon = step.icon;
            return (
              <div key={step.title} className="app-onboarding-step">
                <div className="app-onboarding-step-icon">
                  <Icon className="h-4.5 w-4.5" />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="app-onboarding-step-index">
                    {t("app.onboarding.stepLabel", {
                      step: index + 1,
                      total: steps.length,
                    })}
                  </p>
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
            className="h-11 rounded-2xl px-4 text-slate-500"
            onClick={onSkip}
          >
            {t("app.onboarding.skip")}
          </Button>
          <Button
            type="button"
            className="h-12 rounded-2xl bg-gradient-to-r from-blue-600 via-blue-500 to-cyan-500 px-5 text-base font-medium shadow-[0_16px_30px_-18px_rgba(37,99,235,0.8)] hover:from-blue-700 hover:via-blue-600 hover:to-cyan-600"
            onClick={onStart}
          >
            {t("app.onboarding.start")}
          </Button>
        </div>
      </div>
    </div>
  );
}
