import { Globe2, Menu, MessageSquareMore, X } from "lucide-react";
import { useTranslation } from "react-i18next";
import { LanguageSwitcher } from "./LanguageSwitcher";
import { Button } from "./ui/button";

type AppUtilityMenuProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onOpenFeedbackPage: () => void;
};

export function AppUtilityMenu({
  open,
  onOpenChange,
  onOpenFeedbackPage,
}: AppUtilityMenuProps) {
  const { t } = useTranslation();

  return (
    <>
      <Button
        type="button"
        variant="outline"
        size="icon"
        className="app-utility-menu-button"
        aria-expanded={open}
        aria-controls="app-utility-sheet"
        aria-label={t("app.menu.open")}
        onClick={() => onOpenChange(!open)}
      >
        {open ? (
          <X className="h-4.5 w-4.5" />
        ) : (
          <Menu className="h-4.5 w-4.5" />
        )}
      </Button>

      {open && (
        <div
          className="app-utility-sheet-overlay"
          onClick={() => onOpenChange(false)}
        >
          <div
            id="app-utility-sheet"
            className="app-utility-sheet"
            role="menu"
            aria-label={t("app.menu.title")}
            onClick={(event) => event.stopPropagation()}
          >
            <div className="app-utility-sheet-header">
              <p className="app-utility-sheet-kicker">{t("app.brandTitle")}</p>
              <h2 className="app-utility-sheet-title">{t("app.menu.title")}</h2>
              <p className="app-utility-sheet-description">
                {t("app.menu.description")}
              </p>
            </div>

            <div className="app-utility-sheet-actions">
              <Button
                type="button"
                variant="outline"
                className="app-utility-action"
                onClick={onOpenFeedbackPage}
              >
                <MessageSquareMore className="h-4.5 w-4.5" />
                {t("feedback.trigger")}
              </Button>
              <LanguageSwitcher
                className="app-utility-action"
                icon={<Globe2 className="h-4.5 w-4.5" />}
                showLabel
              />
            </div>
          </div>
        </div>
      )}
    </>
  );
}
