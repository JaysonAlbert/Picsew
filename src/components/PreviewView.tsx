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
    <div className="preview-screen mx-auto max-w-md space-y-4">
      <Card
        data-testid="preview-complete-card"
        className="overflow-hidden border-emerald-200/80 bg-gradient-to-r from-emerald-50 via-white to-emerald-50 shadow-[0_14px_40px_-28px_rgba(16,185,129,0.65)] backdrop-blur"
      >
        <div className="flex items-start gap-3 p-4">
          <div className="preview-status-orb bg-emerald-100 text-emerald-700">
            <CheckCircle2 className="h-5 w-5" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="mb-2 flex items-center gap-2">
              <span className="preview-badge bg-emerald-100 text-emerald-700">
                {t("preview.complete.badge")}
              </span>
            </div>
            <h3 className="text-sm font-semibold text-emerald-950">
              {t("preview.complete.title")}
            </h3>
            <p className="mt-1 text-xs leading-5 text-emerald-800/85">
              {t("preview.complete.desc")}
            </p>
          </div>
        </div>
      </Card>

      <Card
        data-testid="preview-stage-card"
        className="overflow-hidden border-white/80 bg-white/90 shadow-[0_24px_60px_-40px_rgba(15,23,42,0.35)] backdrop-blur"
      >
        <div className="border-b border-slate-100 px-4 pb-3 pt-4">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-[11px] font-medium uppercase tracking-[0.18em] text-slate-400">
                {t("preview.result.eyebrow")}
              </p>
              <h2 className="mt-1 text-base font-semibold text-slate-900">
                {t("preview.result.title")}
              </h2>
            </div>
            <span className="preview-badge bg-slate-100 text-slate-600">
              <Sparkles className="h-3.5 w-3.5" />
              {t("preview.result.badge")}
            </span>
          </div>
        </div>

        <div className="px-4 pb-4 pt-4">
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

          <div className="mt-3 flex items-center justify-between gap-3 rounded-2xl bg-slate-50 px-3 py-2.5 text-xs text-slate-500">
            <p className="min-w-0 flex-1 leading-5">
              {t("preview.result.hint")}
            </p>
            <span className="preview-badge shrink-0 bg-white text-slate-500 shadow-sm">
              PNG
            </span>
          </div>
        </div>
      </Card>

      <div
        data-testid="preview-action-bar"
        className="preview-action-bar rounded-[28px] border border-white/70 bg-white/85 p-3 shadow-[0_18px_50px_-32px_rgba(15,23,42,0.45)] backdrop-blur"
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
