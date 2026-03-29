import type { VideoSelectionSource } from "../lib/analytics-events";
import { useRef, useState } from "react";
import {
  Upload,
  Video,
  X,
  Play,
  Images,
  FolderOpen,
  Sparkles,
} from "lucide-react";
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
    <div className="mx-auto max-w-md space-y-4">
      <Card
        data-testid="upload-stage-card"
        className="app-stage-card overflow-hidden"
      >
        <div className="app-stage-header">
          <p className="app-stage-kicker">{t("upload.title")}</p>
          <h2 className="app-stage-title">{t("app.title")}</h2>
          <p className="app-stage-description">{t("app.subtitle")}</p>
        </div>

        {!selectedVideo ? (
          <div className="space-y-4">
            <div
              data-testid="upload-dropzone"
              onClick={() => fileInputRef.current?.click()}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              className={`app-upload-dropzone ${
                isDragging
                  ? "app-upload-dropzone-active"
                  : "app-upload-dropzone-idle"
              }`}
            >
              <div className="app-upload-orb">
                <Upload className="h-7 w-7 text-blue-600" />
              </div>
              <p className="text-sm font-medium text-slate-700">
                {t("upload.dragDrop")}
              </p>
              <p className="mt-2 text-xs text-slate-400">
                {t("upload.supportFormat")}
              </p>
            </div>

            {supportsNativeImport && (
              <div className="grid grid-cols-2 gap-3">
                <Button
                  type="button"
                  variant="outline"
                  className="h-12 rounded-2xl border-slate-200 bg-white/85"
                  disabled={isPickingNativeVideo}
                  onClick={() => void onPickFromPhotos?.()}
                >
                  <Images className="w-4 h-4 mr-2" />
                  {t("upload.native.fromPhotos")}
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  className="h-12 rounded-2xl border-slate-200 bg-white/85"
                  disabled={isPickingNativeVideo}
                  onClick={() => void onPickFromFiles?.()}
                >
                  <FolderOpen className="w-4 h-4 mr-2" />
                  {t("upload.native.fromFiles")}
                </Button>
              </div>
            )}

            <div className="app-guidance-grid">
              <div className="app-guidance-chip">
                <Sparkles className="h-3.5 w-3.5 text-blue-500" />
                <span>{t("upload.instructions.step1")}</span>
              </div>
              <div className="app-guidance-chip">
                <Sparkles className="h-3.5 w-3.5 text-blue-500" />
                <span>{t("upload.instructions.step2")}</span>
              </div>
              <div className="app-guidance-chip">
                <Sparkles className="h-3.5 w-3.5 text-blue-500" />
                <span>{t("upload.instructions.step3")}</span>
              </div>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="app-media-frame relative">
              {videoPreviewUrl && (
                <video
                  src={videoPreviewUrl}
                  controls
                  className="w-full max-h-80 rounded-[1.4rem] object-contain"
                />
              )}
              <button
                onClick={handleClearVideo}
                className="absolute right-3 top-3 flex h-8 w-8 items-center justify-center rounded-full bg-black/60 text-white backdrop-blur-sm transition-colors hover:bg-black/80"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="app-inline-note items-start">
              <Video className="mt-0.5 h-4.5 w-4.5 flex-shrink-0 text-blue-600" />
              <div className="flex-1 min-w-0">
                <p className="truncate text-sm font-medium text-slate-700">
                  {selectedVideo.name}
                </p>
                <p className="text-xs text-slate-500">
                  {(selectedVideo.size / 1024 / 1024).toFixed(2)} MB
                </p>
              </div>
            </div>
          </div>
        )}

        <input
          ref={fileInputRef}
          type="file"
          accept="video/*"
          onChange={handleFileChange}
          className="hidden"
        />
      </Card>

      {selectedVideo && (
        <div
          data-testid="upload-action-tray"
          className="app-actions-tray rounded-[28px] border border-white/70 bg-white/88 p-3 shadow-[0_18px_50px_-32px_rgba(15,23,42,0.35)] backdrop-blur"
        >
          <Button
            onClick={onStartProcessing}
            disabled={!isOpenCVReady}
            className="h-14 w-full rounded-2xl bg-gradient-to-r from-blue-600 via-blue-500 to-cyan-500 text-base font-medium shadow-[0_16px_30px_-18px_rgba(37,99,235,0.8)] hover:from-blue-700 hover:via-blue-600 hover:to-cyan-600 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {isOpenCVReady ? (
              <>
                <Play className="mr-2 h-5 w-5" />
                {t("upload.startProcessing")}
              </>
            ) : (
              t("upload.loadingResources")
            )}
          </Button>
        </div>
      )}
    </div>
  );
}
