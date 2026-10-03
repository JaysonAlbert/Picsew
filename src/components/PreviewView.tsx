import { useState } from "react";
import { Download, Share2 } from "lucide-react";
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
  const [zoom, setZoom] = useState(1);
  const toggleZoom = () => setZoom((value) => (value === 1 ? 2 : 1));

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
    <div className="product-route product-preview-route">
      <header className="product-preview-header">
        <Button
          onClick={onReset}
          aria-label={t("preview.actions.startOver")}
          variant="ghost"
          className="product-new-capture"
        >
          {t("preview.actions.new")}
        </Button>
        <h1>{t("app.routes.preview.title")}</h1>
      </header>
      <Card
        data-testid="preview-stage-card"
        className="app-stage-card product-preview-stage"
      >
        <div
          className="product-image-scroll"
          tabIndex={0}
          role="region"
          aria-label={t("preview.result.alt")}
          aria-description={t("preview.result.zoomHint")}
          onDoubleClick={toggleZoom}
          onKeyDown={(event) => {
            if (event.key === "Enter") {
              event.preventDefault();
              toggleZoom();
            }
          }}
        >
          <ImageWithFallback
            src={imageUrl}
            alt={t("preview.result.alt")}
            className="product-image"
            data-zoom={zoom}
          />
        </div>
      </Card>
      <div data-testid="preview-action-bar" className="app-actions-tray">
        <div className="product-export-actions">
          <Button onClick={onDownload} className="app-primary-action">
            <Download aria-hidden="true" />
            {isNativeSave
              ? t("preview.actions.save")
              : t("preview.actions.download")}
          </Button>
          {canShare && (
            <Button
              onClick={handleShare}
              variant="outline"
              className="app-secondary-action"
            >
              <Share2 aria-hidden="true" />
              {t("preview.actions.share")}
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}
