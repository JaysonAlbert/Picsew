import type { VideoSelectionSource } from "../lib/analytics-events";
import { useRef, useState, type Ref } from "react";
import { Film, Check, Images, FolderOpen } from "lucide-react";
import { useTranslation } from "react-i18next";
import { Button } from "./ui/button";
import { Card } from "./ui/card";

interface VideoUploadProps {
  selectedVideo: File | null;
  videoPreviewUrl: string | null;
  onVideoSelect: (file: File | null, source?: VideoSelectionSource) => void;
  onStartProcessing: () => void;
  engineStatus: "loading" | "ready" | "failed";
  recordingStatus: "checking" | "ready" | "unreadable";
  generationFailed?: boolean;
  videoPickerRef?: Ref<HTMLButtonElement>;
  onReload?: () => void;
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
  engineStatus,
  recordingStatus,
  generationFailed = false,
  videoPickerRef,
  onReload,
  supportsNativeImport = false,
  isPickingNativeVideo = false,
  onPickFromPhotos,
  onPickFromFiles,
}: VideoUploadProps) {
  const { t } = useTranslation();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const canCreate =
    !!selectedVideo && recordingStatus === "ready" && engineStatus === "ready";
  const engineFailed = engineStatus === "failed";
  const recordingUnreadable =
    !!selectedVideo && recordingStatus === "unreadable";
  const feedback = engineFailed
    ? "upload.errors.engine"
    : recordingUnreadable
      ? "upload.errors.recording"
      : generationFailed
        ? "upload.errors.generation"
        : null;
  const actionLabel =
    selectedVideo && !recordingUnreadable && !canCreate
      ? "upload.loadingResources"
      : generationFailed && !recordingUnreadable
        ? "upload.retryProcessing"
        : "upload.startProcessing";
  let sourceTitle = "upload.heroTitle";
  if (selectedVideo) {
    sourceTitle =
      recordingStatus === "checking"
        ? "upload.checkingTitle"
        : recordingUnreadable
          ? "upload.unreadableTitle"
          : "upload.readyTitle";
  }

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
    e.target.value = "";
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
            {selectedVideo && recordingStatus === "ready" ? (
              <Check />
            ) : (
              <Film />
            )}
          </div>
          <h2>{t(sourceTitle)}</h2>
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
                ref={videoPickerRef}
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
              ref={videoPickerRef}
              onClick={() => fileInputRef.current?.click()}
            >
              {t("upload.chooseVideo")}
            </Button>
          )}
        </div>
        {selectedVideo && recordingStatus === "ready" && videoPreviewUrl && (
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
        {feedback && (
          <p role="alert" className="product-action-feedback">
            {t(feedback)}
          </p>
        )}
        <Button
          onClick={engineFailed ? onReload : onStartProcessing}
          disabled={!engineFailed && !canCreate}
          className="app-primary-action"
        >
          {t(engineFailed ? "upload.reloadPage" : actionLabel)}
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
