import {
  Download,
  RotateCcw,
  Share2,
  CheckCircle2,
  Sparkles,
} from "lucide-react";
import { useTranslation } from "react-i18next";
import { Button } from "./ui/button";
import { Card } from "./ui/card";
import { ImageWithFallback } from "./figma/ImageWithFallback";
import { shareGeneratedImage, supportsImageSharing } from "../lib/native-media";

interface PreviewViewProps {
  imageUrl: string;
  onDownload: () => Promise<void> | void;
  onReset: () => void;
  isNativeSave?: boolean;
}

export function PreviewView({
  imageUrl,
  onDownload,
  onReset,
  isNativeSave = false,
}: PreviewViewProps) {
  const { t } = useTranslation();
  const canShare = supportsImageSharing();

  const handleShare = async () => {
    if (!canShare) {
      alert(t("preview.share.unsupported"));
      return;
    }

    try {
      await shareGeneratedImage(imageUrl, {
        title: t("preview.share.title"),
        text: t("preview.share.text"),
        fileName: "long-screenshot.png",
      });
    } catch (err) {
      console.log(t("preview.share.failed"), err);
    }
  };

  return (
    <div className="mx-auto max-w-md space-y-4">
      <Card
        data-testid="preview-stage-card"
        className="app-stage-card overflow-hidden"
      >
        <div className="app-stage-header">
          <div className="mb-1 flex items-center gap-2">
            <div className="preview-status-orb bg-emerald-100 text-emerald-700">
              <CheckCircle2 className="h-4.5 w-4.5" />
            </div>
            <span className="preview-badge bg-emerald-100 text-emerald-700">
              {t("preview.complete.badge")}
            </span>
            <span className="preview-badge bg-slate-100 text-slate-600">
              <Sparkles className="h-3.5 w-3.5" />
              {t("preview.result.badge")}
            </span>
          </div>
          <p className="app-stage-kicker">{t("preview.result.eyebrow")}</p>
          <h2 className="app-stage-title">{t("preview.result.title")}</h2>
          <p className="app-stage-description">{t("preview.complete.desc")}</p>
        </div>

        <div className="preview-stage-surface">
          <div className="preview-image-shell">
            <div className="preview-image-scroll">
              <ImageWithFallback
                src={imageUrl}
                alt={t("preview.result.alt")}
                className="w-full"
              />
            </div>
          </div>
        </div>

        <div className="app-inline-note mt-4">
          <Sparkles className="h-4.5 w-4.5 flex-shrink-0 text-blue-500" />
          <span>{t("preview.result.hint")}</span>
        </div>
      </Card>

      <div
        data-testid="preview-action-bar"
        className="app-actions-tray rounded-[28px] border border-white/70 bg-white/88 p-3 shadow-[0_18px_50px_-32px_rgba(15,23,42,0.35)] backdrop-blur"
      >
        <div
          className={`grid gap-3 ${canShare ? "grid-cols-2" : "grid-cols-1"}`}
        >
          <Button
            onClick={onDownload}
            className="h-14 rounded-2xl bg-gradient-to-r from-blue-600 via-blue-500 to-cyan-500 text-base font-medium shadow-[0_16px_30px_-18px_rgba(37,99,235,0.8)] hover:from-blue-700 hover:via-blue-600 hover:to-cyan-600"
          >
            <Download className="mr-2 h-5 w-5" />
            {isNativeSave
              ? t("preview.actions.save")
              : t("preview.actions.download")}
          </Button>

          {canShare && (
            <Button
              onClick={handleShare}
              variant="outline"
              className="h-14 rounded-2xl border-slate-200 bg-white/90 text-base text-slate-700 shadow-sm"
            >
              <Share2 className="mr-2 h-5 w-5" />
              {t("preview.actions.share")}
            </Button>
          )}
        </div>

        <Button
          onClick={onReset}
          variant="ghost"
          className="mt-2 h-11 w-full rounded-2xl text-slate-500 hover:bg-slate-100 hover:text-slate-700"
        >
          <RotateCcw className="mr-2 h-4.5 w-4.5" />
          {t("preview.actions.startOver")}
        </Button>
      </div>
    </div>
  );
}
