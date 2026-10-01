import type { VideoSelectionSource } from "../lib/analytics-events";
import { useRef, useState } from "react";
import { Film, Check, Images, FolderOpen } from "lucide-react";
import { useTranslation } from "react-i18next";
import { Button } from "./ui/button";
import { Card } from "./ui/card";

interface VideoUploadProps {
  selectedVideo: File | null;
  videoPreviewUrl: string | null;
  onVideoSelect: (file: File | null, source?: VideoSelectionSource) => void;
  onStartProcessing: () => void;
  isOpenCVReady: boolean;
  supportsNativeImport?: boolean;
  isPickingNativeVideo?: boolean;
  onPickFromPhotos?: () => Promise<void>;
  onPickFromFiles?: () => Promise<void>;
}

export function VideoUpload({
  selectedVideo,
  videoPreviewUrl,
  onVideoSelect,
  onStartProcessing,
  isOpenCVReady,
  supportsNativeImport = false,
  isPickingNativeVideo = false,
  onPickFromPhotos,
  onPickFromFiles,
}: VideoUploadProps) {
  const { t } = useTranslation();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isDragging, setIsDragging] = useState(false);

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);

    const file = e.dataTransfer.files?.[0];
    if (file && file.type.startsWith("video/")) {
      onVideoSelect(file, "drop");
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file && file.type.startsWith("video/")) {
      onVideoSelect(file, "picker");
    }
  };

  const handleClearVideo = () => {
    if (fileInputRef.current) {
      fileInputRef.current.value = "";
    }
    onVideoSelect(null);
  };

  return (
    <div className="product-route">
      <Card
        data-testid="upload-stage-card"
        className="app-stage-card product-upload-stage"
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
      >
        <div
          className={`product-source ${isDragging ? "product-source-active" : ""}`}
          data-testid="upload-dropzone"
        >
          <div className="product-source-icon" aria-hidden="true">
            {selectedVideo ? <Check /> : <Film />}
          </div>
          <h2>{t(selectedVideo ? "upload.readyTitle" : "upload.heroTitle")}</h2>
          {selectedVideo ? (
            <>
              <p className="product-file-name">{selectedVideo.name}</p>
              <p className="product-caption">
                {(selectedVideo.size / 1024 / 1024).toFixed(2)} MB
              </p>
            </>
          ) : (
            <p className="product-caption">
              {t(isDragging ? "upload.dragDropActive" : "upload.supportFormat")}
            </p>
          )}
        </div>
        <div className="product-source-actions">
          {supportsNativeImport ? (
            <>
              <Button
                type="button"
                variant="outline"
                className="app-secondary-action"
                disabled={isPickingNativeVideo}
                onClick={() => void onPickFromPhotos?.()}
              >
                <Images aria-hidden="true" />
                {t("upload.native.fromPhotos")}
              </Button>
              <Button
                type="button"
                variant="outline"
                className="app-secondary-action"
                disabled={isPickingNativeVideo}
                onClick={() => void onPickFromFiles?.()}
              >
                <FolderOpen aria-hidden="true" />
                {t("upload.native.fromFiles")}
              </Button>
            </>
          ) : (
            <Button
              type="button"
              variant="outline"
              className="app-secondary-action"
              onClick={() => fileInputRef.current?.click()}
            >
              {t("upload.chooseVideo")}
            </Button>
          )}
        </div>
        {selectedVideo && videoPreviewUrl && (
          <details className="product-details product-video-details">
            <summary>{t("upload.previewVideo")}</summary>
            <video
              src={videoPreviewUrl}
              controls
              playsInline
              className="product-video"
            />
          </details>
        )}
        <input
          ref={fileInputRef}
          type="file"
          accept="video/*"
          onChange={handleFileChange}
          className="hidden"
        />
      </Card>
      <p className="product-caption product-privacy">
        {t("upload.localProcessingHint")}
      </p>
      <div data-testid="upload-action-tray" className="app-actions-tray">
        <Button
          onClick={onStartProcessing}
          disabled={!selectedVideo || !isOpenCVReady}
          className="app-primary-action"
        >
          {selectedVideo && !isOpenCVReady
            ? t("upload.loadingResources")
            : t("upload.startProcessing")}
        </Button>
        {selectedVideo && (
          <Button
            variant="ghost"
            onClick={handleClearVideo}
            className="app-secondary-action product-clear"
          >
            {t("upload.clearSelection")}
          </Button>
        )}
      </div>
    </div>
  );
}
