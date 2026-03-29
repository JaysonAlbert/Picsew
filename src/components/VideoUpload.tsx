import type { VideoSelectionSource } from "../lib/analytics-events";
import { useRef, useState } from "react";
import { Upload, Video, X, Play, Images, FolderOpen } from "lucide-react";
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
    <div className="max-w-md mx-auto space-y-4">
      <Card className="p-6">
        <h2 className="mb-4">{t("upload.title")}</h2>

        {!selectedVideo ? (
          <div className="space-y-3">
            <div
              onClick={() => fileInputRef.current?.click()}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              className={`border-2 border-dashed rounded-2xl p-8 text-center cursor-pointer transition-colors ${
                isDragging
                  ? "border-blue-500 bg-blue-50"
                  : "border-gray-300 hover:border-blue-400 hover:bg-blue-50/50"
              }`}
            >
              <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Upload className="w-8 h-8 text-blue-600" />
              </div>
              <p className="text-gray-600 mb-2">{t("upload.dragDrop")}</p>
              <p className="text-xs text-gray-400">
                {t("upload.supportFormat")}
              </p>
            </div>

            {supportsNativeImport && (
              <div className="grid grid-cols-2 gap-3">
                <Button
                  type="button"
                  variant="outline"
                  className="h-12"
                  disabled={isPickingNativeVideo}
                  onClick={() => void onPickFromPhotos?.()}
                >
                  <Images className="w-4 h-4 mr-2" />
                  {t("upload.native.fromPhotos")}
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  className="h-12"
                  disabled={isPickingNativeVideo}
                  onClick={() => void onPickFromFiles?.()}
                >
                  <FolderOpen className="w-4 h-4 mr-2" />
                  {t("upload.native.fromFiles")}
                </Button>
              </div>
            )}
          </div>
        ) : (
          <div className="space-y-4">
            <div className="relative bg-black rounded-2xl overflow-hidden">
              {videoPreviewUrl && (
                <video
                  src={videoPreviewUrl}
                  controls
                  className="w-full max-h-80 object-contain"
                />
              )}
              <button
                onClick={handleClearVideo}
                className="absolute top-3 right-3 w-8 h-8 bg-black/60 backdrop-blur-sm rounded-full flex items-center justify-center text-white hover:bg-black/80 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="flex items-start gap-3 p-4 bg-gray-50 rounded-xl">
              <Video className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" />
              <div className="flex-1 min-w-0">
                <p className="text-sm truncate">{selectedVideo.name}</p>
                <p className="text-xs text-gray-500">
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
        <Button
          onClick={onStartProcessing}
          disabled={!isOpenCVReady}
          className="w-full h-14 text-base bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isOpenCVReady ? (
            <>
              <Play className="w-5 h-5 mr-2" />
              {t("upload.startProcessing")}
            </>
          ) : (
            t("upload.loadingResources")
          )}
        </Button>
      )}

      <Card className="p-4 bg-blue-50 border-blue-100">
        <h3 className="text-sm mb-2 text-blue-900">
          {t("upload.instructions.title")}
        </h3>
        <ul className="text-xs text-blue-700 space-y-1">
          <li>• {t("upload.instructions.step1")}</li>
          <li>• {t("upload.instructions.step2")}</li>
          <li>• {t("upload.instructions.step3")}</li>
          <li>• {t("upload.instructions.step4")}</li>
        </ul>
      </Card>
    </div>
  );
}
