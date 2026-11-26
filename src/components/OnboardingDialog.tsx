import { useRef } from "react";
import * as Dialog from "@radix-ui/react-dialog";
import { Film, Image, Sparkles } from "lucide-react";
import { useTranslation } from "react-i18next";
import { Button } from "./ui/button";

interface OnboardingDialogProps {
  open: boolean;
  onSkip: () => void;
  onStart: () => void;
  onRestoreFocus?: () => void;
}

export function OnboardingDialog({
  open,
  onSkip,
  onStart,
  onRestoreFocus,
}: OnboardingDialogProps) {
  const { t } = useTranslation();
  const titleRef = useRef<HTMLHeadingElement>(null);

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
    <Dialog.Root
      open={open}
      onOpenChange={(nextOpen) => {
        if (!nextOpen) onSkip();
      }}
    >
      <div className="app-onboarding-overlay">
        <Dialog.Content
          className="app-onboarding-dialog"
          data-testid="app-onboarding"
          aria-modal="true"
          onOpenAutoFocus={(event) => {
            event.preventDefault();
            titleRef.current?.focus({ preventScroll: true });
          }}
          onCloseAutoFocus={(event) => {
            event.preventDefault();
            onRestoreFocus?.();
          }}
          onPointerDownOutside={(event) => event.preventDefault()}
        >
          <div className="app-onboarding-header">
            <Dialog.Title
              className="app-stage-title"
              ref={titleRef}
              tabIndex={-1}
            >
              {t("app.onboarding.title")}
            </Dialog.Title>
            <Dialog.Description className="app-stage-description">
              {t("app.onboarding.subtitle")}
            </Dialog.Description>
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
              tabIndex={0}
              className="app-primary-action"
              onClick={onStart}
            >
              {t("app.onboarding.start")}
            </Button>
            <Button
              type="button"
              tabIndex={0}
              variant="ghost"
              className="app-secondary-action product-clear"
              onClick={onSkip}
            >
              {t("app.onboarding.skip")}
            </Button>
          </div>
        </Dialog.Content>
      </div>
    </Dialog.Root>
  );
}
