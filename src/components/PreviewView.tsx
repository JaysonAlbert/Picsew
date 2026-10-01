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
  const [dimensions, setDimensions] = useState<{
    url: string;
    width: number;
    height: number;
  } | null>(null);

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
    <div className="product-route">
      <Card
        data-testid="preview-stage-card"
        className="app-stage-card product-preview-stage"
      >
        <div
          className="product-image-scroll"
          tabIndex={0}
          role="region"
          aria-label={t("preview.result.alt")}
        >
          <ImageWithFallback
            src={imageUrl}
            alt={t("preview.result.alt")}
            className="product-image"
            onLoad={(event) => {
              const image = event.currentTarget;
              setDimensions({
                url: imageUrl,
                width: image.naturalWidth,
                height: image.naturalHeight,
              });
            }}
          />
        </div>
      </Card>
      <details className="product-details">
        <summary>{t("preview.details.title")}</summary>
        {dimensions?.url === imageUrl && (
          <p>{t("preview.details.imageSize", dimensions)}</p>
        )}
      </details>
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
        <Button
          onClick={onReset}
          variant="ghost"
          className="app-secondary-action product-clear"
        >
          {t("preview.actions.startOver")}
        </Button>
      </div>
    </div>
  );
}
