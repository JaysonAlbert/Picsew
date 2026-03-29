import { Download, RotateCcw, Share2, CheckCircle2 } from "lucide-react";
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

  const handleShare = async () => {
    if (!supportsImageSharing()) {
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
    <div className="max-w-md mx-auto space-y-4">
      <Card className="p-4 bg-green-50 border-green-200">
        <div className="flex items-center gap-3">
          <CheckCircle2 className="w-6 h-6 text-green-600 flex-shrink-0" />
          <div>
            <h3 className="text-sm text-green-900">
              {t("preview.complete.title")}
            </h3>
            <p className="text-xs text-green-700">
              {t("preview.complete.desc")}
            </p>
          </div>
        </div>
      </Card>

      <Card className="p-4">
        <h2 className="mb-4">{t("preview.result.title")}</h2>

        <div className="bg-gray-100 rounded-2xl overflow-hidden">
          <div className="max-h-[60vh] overflow-y-auto">
            <ImageWithFallback
              src={imageUrl}
              alt={t("preview.result.alt")}
              className="w-full"
            />
          </div>
        </div>

        <div className="mt-4 p-3 bg-gray-50 rounded-xl">
          <p className="text-xs text-gray-600">{t("preview.result.hint")}</p>
        </div>
      </Card>

      <div className="grid grid-cols-2 gap-3">
        <Button
          onClick={onDownload}
          className="h-14 bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700"
        >
          <Download className="w-5 h-5 mr-2" />
          {isNativeSave
            ? t("preview.actions.save")
            : t("preview.actions.download")}
        </Button>

        {supportsImageSharing() && (
          <Button onClick={handleShare} variant="outline" className="h-14">
            <Share2 className="w-5 h-5 mr-2" />
            {t("preview.actions.share")}
          </Button>
        )}
      </div>

      <Button onClick={onReset} variant="outline" className="w-full h-12">
        <RotateCcw className="w-5 h-5 mr-2" />
        {t("preview.actions.startOver")}
      </Button>

      <Card className="p-4 bg-blue-50 border-blue-100">
        <h3 className="text-sm mb-2 text-blue-900">
          {t("preview.tips.title")}
        </h3>
        <ul className="text-xs text-blue-700 space-y-1">
          <li>• {t("preview.tips.save")}</li>
          <li>• {t("preview.tips.download")}</li>
          <li>• {t("preview.tips.share")}</li>
        </ul>
      </Card>
    </div>
  );
}
