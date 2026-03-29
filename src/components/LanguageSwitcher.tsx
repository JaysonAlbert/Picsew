import type { ReactNode } from "react";
import { Languages } from "lucide-react";
import { useTranslation } from "react-i18next";
import { Button } from "./ui/button";

interface LanguageSwitcherProps {
  className?: string;
  showLabel?: boolean;
  icon?: ReactNode;
}

export function LanguageSwitcher({
  className = "",
  showLabel = false,
  icon,
}: LanguageSwitcherProps) {
  const { i18n } = useTranslation();
  const currentLanguage = i18n?.language ?? "";

  const toggleLanguage = () => {
    const nextLang = currentLanguage.startsWith("zh") ? "en" : "zh";
    i18n?.changeLanguage?.(nextLang);
  };

  const title = currentLanguage.startsWith("zh")
    ? "Switch to English"
    : "切换到中文";

  return (
    <Button
      type="button"
      variant={showLabel ? "outline" : "ghost"}
      size={showLabel ? "default" : "icon"}
      className={className}
      onClick={toggleLanguage}
      title={title}
    >
      {icon ?? <Languages className="h-5 w-5" />}
      {showLabel ? (
        <span>{currentLanguage.startsWith("zh") ? "English" : "中文"}</span>
      ) : (
        <span className="sr-only">{title}</span>
      )}
    </Button>
  );
}
