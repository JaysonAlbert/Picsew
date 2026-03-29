import { useState, useRef, useEffect } from "react";
import { Upload, Image, Play, Check, Smartphone } from "lucide-react";
import { useTranslation } from "react-i18next";
import { FeedbackDialog } from "./components/FeedbackDialog";
import { VideoUpload } from "./components/VideoUpload";
import { ProcessingView } from "./components/ProcessingView";
import { PreviewView } from "./components/PreviewView";
import { LanguageSwitcher } from "./components/LanguageSwitcher";
import { processVideo as picsewProcessVideo } from "./lib/picsew";
import { initGA, logPageView, trackEvent } from "./lib/analytics";
import {
  ANALYTICS_EVENTS,
  getVideoFileAnalytics,
  getVideoMetadataAnalytics,
  sanitizeAnalyticsErrorMessage,
  type VideoSelectionSource,
} from "./lib/analytics-events";
import SEO from "./components/SEO";
import {
  canUseNativePhotoSave,
  canUseNativeVideoImport,
  isLikelyUserCancellation,
  pickNativeVideo,
  saveImageToPhotos,
} from "./lib/native-media";

type AppStep = "upload" | "processing" | "preview";
type VideoMetadata = {
  durationSeconds?: number;
  width?: number;
  height?: number;
};

export default function App() {
  const { t } = useTranslation();
  const [currentStep, setCurrentStep] = useState<AppStep>("upload");
  const [selectedVideo, setSelectedVideo] = useState<File | null>(null);
  const [videoPreviewUrl, setVideoPreviewUrl] = useState<string | null>(null);
  const [processProgress, setProcessProgress] = useState(0);
  const [generatedImage, setGeneratedImage] = useState<string | null>(null);
  const [isOpenCVReady, setIsOpenCVReady] = useState(false);
  const [videoMetadata, setVideoMetadata] = useState<VideoMetadata>({});
  const [processingLogs, setProcessingLogs] = useState<string[]>([]);
  const [lastProcessingError, setLastProcessingError] = useState<string | null>(
    null,
  );
  const [isPickingNativeVideo, setIsPickingNativeVideo] = useState(false);

  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    initGA();
  }, []);

  useEffect(() => {
    logPageView(`/${currentStep}`);
  }, [currentStep]);

  useEffect(() => {
    if (currentStep === "preview" && generatedImage) {
      trackEvent(ANALYTICS_EVENTS.previewShown);
    }
  }, [currentStep, generatedImage]);

  useEffect(() => {
    if (selectedVideo && videoRef.current) {
      const url = URL.createObjectURL(selectedVideo);
      const videoElement = videoRef.current;

      const handleLoadedMetadata = () => {
        setVideoMetadata({
          durationSeconds: videoElement.duration,
          width: videoElement.videoWidth,
          height: videoElement.videoHeight,
        });
        trackEvent(ANALYTICS_EVENTS.uploadCompleted, {
          ...getVideoFileAnalytics(selectedVideo),
          ...getVideoMetadataAnalytics(
            videoElement.duration,
            videoElement.videoWidth,
            videoElement.videoHeight,
          ),
        });
      };

      videoElement.addEventListener("loadedmetadata", handleLoadedMetadata, {
        once: true,
      });
      videoElement.src = url;
      videoElement.load();
      setVideoPreviewUrl(url);

      return () => {
        videoElement.removeEventListener(
          "loadedmetadata",
          handleLoadedMetadata,
        );
        URL.revokeObjectURL(url);
      };
    }
  }, [selectedVideo]);

  useEffect(() => {
    const loadOpenCV = async () => {
      try {
        await import("./lib/opencv").then((m) => m.getOpenCV());
        setIsOpenCVReady(true);
      } catch (error) {
        console.error("Failed to load OpenCV:", error);
      }
    };
    loadOpenCV();
  }, []);

  const handleVideoSelect = (
    file: File | null,
    source: VideoSelectionSource = "picker",
  ) => {
    if (file) {
      trackEvent(
        ANALYTICS_EVENTS.uploadStarted,
        getVideoFileAnalytics(file, source),
      );
    } else {
      setVideoMetadata({});
    }
    setSelectedVideo(file);
  };

  const handleStartProcessing = async (): Promise<void> => {
    setCurrentStep("processing");
    setProcessProgress(0);
    setProcessingLogs([]);
    setLastProcessingError(null);

    if (videoRef.current && canvasRef.current) {
      const startedAt = performance.now();
      const addProcessingLog = (message: string) => {
        console.log(message);
        setProcessingLogs((previous) => [...previous.slice(-199), message]);
      };
      try {
        trackEvent(ANALYTICS_EVENTS.processingStarted, {
          ...(selectedVideo ? getVideoFileAnalytics(selectedVideo) : {}),
          ...getVideoMetadataAnalytics(
            videoRef.current.duration,
            videoRef.current.videoWidth,
            videoRef.current.videoHeight,
          ),
        });

        await picsewProcessVideo(
          videoRef.current,
          addProcessingLog,
          canvasRef.current,
          (p) => setProcessProgress(Math.round(p)),
        );
        const imageUrl = canvasRef.current.toDataURL("image/png");
        trackEvent(ANALYTICS_EVENTS.processingCompleted, {
          processing_time_ms: Math.round(performance.now() - startedAt),
          ...getVideoMetadataAnalytics(
            videoRef.current.duration,
            videoRef.current.videoWidth,
            videoRef.current.videoHeight,
          ),
        });
        setGeneratedImage(imageUrl);
        setCurrentStep("preview");
      } catch (error) {
        setLastProcessingError(
          error instanceof Error ? error.message : String(error),
        );
        trackEvent(ANALYTICS_EVENTS.processingFailed, {
          error_message: sanitizeAnalyticsErrorMessage(error),
          processing_time_ms: Math.round(performance.now() - startedAt),
          ...getVideoMetadataAnalytics(
            videoRef.current.duration,
            videoRef.current.videoWidth,
            videoRef.current.videoHeight,
          ),
        });
        console.error("Processing failed:", error);
        alert(
          `Processing failed: ${error instanceof Error ? error.message : String(error)}`,
        );
        handleReset();
      }
    } else {
      console.error("Video or canvas ref not available");
      // Handle error appropriately
      handleReset();
    }
  };

  const handleReset = () => {
    setCurrentStep("upload");
    setSelectedVideo(null);
    setVideoPreviewUrl(null);
    setProcessProgress(0);
    setGeneratedImage(null);
    setVideoMetadata({});
    setProcessingLogs([]);
    setLastProcessingError(null);
    if (videoRef.current) {
      videoRef.current.src = "";
    }
  };

  const handlePickNativeVideo = async (
    source: "photos" | "files",
    analyticsSource: VideoSelectionSource,
  ) => {
    setIsPickingNativeVideo(true);
    try {
      const file = await pickNativeVideo(source);
      if (file) {
        handleVideoSelect(file, analyticsSource);
      }
    } catch (error) {
      if (!isLikelyUserCancellation(error)) {
        console.error("Failed to import video natively:", error);
        alert(t("upload.native.failed"));
      }
    } finally {
      setIsPickingNativeVideo(false);
    }
  };

  const handleDownload = async () => {
    if (!generatedImage) {
      return;
    }

    trackEvent(ANALYTICS_EVENTS.exportStarted);

    try {
      if (canUseNativePhotoSave()) {
        await saveImageToPhotos(generatedImage, "long-screenshot.png");
        alert(t("preview.save.success"));
      } else {
        const link = document.createElement("a");
        link.href = generatedImage;
        link.download = "long-screenshot.png";
        link.click();
      }

      trackEvent(ANALYTICS_EVENTS.exportCompleted);
    } catch (error) {
      console.error("Failed to export image:", error);
      alert(t("preview.save.failed"));
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      <SEO
        title={t("app.title")}
        description={t("app.subtitle")}
        keywords="screenshot, stitching, long screenshot, video to image, picsew"
      />
      {/* Header */}
      <div className="bg-white border-b sticky top-0 z-10 shadow-sm">
        <div className="px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center">
                <Smartphone className="w-5 h-5 text-white" />
              </div>
              <div>
                <h1 className="text-lg">{t("app.title")}</h1>
                <p className="text-xs text-gray-500">{t("app.subtitle")}</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <FeedbackDialog
                currentStep={currentStep}
                videoMetadata={videoMetadata}
                lastProcessingError={lastProcessingError}
                processingLogs={processingLogs}
              />
              <LanguageSwitcher />
            </div>
          </div>
        </div>
      </div>

      {/* Progress Steps */}
      <div className="px-4 py-6 bg-white border-b">
        <div className="flex items-center justify-between max-w-md mx-auto">
          <div className="flex flex-col items-center gap-2 flex-1">
            <div
              className={`w-10 h-10 rounded-full flex items-center justify-center transition-colors ${
                currentStep === "upload"
                  ? "bg-blue-500 text-white"
                  : "bg-green-500 text-white"
              }`}
            >
              {currentStep === "upload" ? (
                <Upload className="w-5 h-5" />
              ) : (
                <Check className="w-5 h-5" />
              )}
            </div>
            <span className="text-xs text-center">
              {t("app.steps.selectVideo")}
            </span>
          </div>

          <div
            className={`h-0.5 flex-1 mx-2 ${
              currentStep === "upload" ? "bg-gray-200" : "bg-green-500"
            }`}
          />

          <div className="flex flex-col items-center gap-2 flex-1">
            <div
              className={`w-10 h-10 rounded-full flex items-center justify-center transition-colors ${
                currentStep === "upload"
                  ? "bg-gray-200 text-gray-400"
                  : currentStep === "processing"
                    ? "bg-blue-500 text-white"
                    : "bg-green-500 text-white"
              }`}
            >
              {currentStep === "preview" ? (
                <Check className="w-5 h-5" />
              ) : (
                <Play className="w-5 h-5" />
              )}
            </div>
            <span className="text-xs text-center">
              {t("app.steps.processing")}
            </span>
          </div>

          <div
            className={`h-0.5 flex-1 mx-2 ${
              currentStep === "preview" ? "bg-green-500" : "bg-gray-200"
            }`}
          />

          <div className="flex flex-col items-center gap-2 flex-1">
            <div
              className={`w-10 h-10 rounded-full flex items-center justify-center transition-colors ${
                currentStep === "preview"
                  ? "bg-green-500 text-white"
                  : "bg-gray-200 text-gray-400"
              }`}
            >
              {currentStep === "preview" ? (
                <Check className="w-5 h-5" />
              ) : (
                <Image className="w-5 h-5" />
              )}
            </div>
            <span className="text-xs text-center">
              {t("app.steps.previewDownload")}
            </span>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="px-4 py-6 pb-24">
        {currentStep === "upload" && (
          <VideoUpload
            selectedVideo={selectedVideo}
            videoPreviewUrl={videoPreviewUrl}
            onVideoSelect={handleVideoSelect}
            onStartProcessing={handleStartProcessing}
            isOpenCVReady={isOpenCVReady}
            supportsNativeImport={canUseNativeVideoImport()}
            isPickingNativeVideo={isPickingNativeVideo}
            onPickFromPhotos={() =>
              handlePickNativeVideo("photos", "native_photos")
            }
            onPickFromFiles={() =>
              handlePickNativeVideo("files", "native_files")
            }
          />
        )}

        {currentStep === "processing" && (
          <ProcessingView progress={processProgress} />
        )}

        {currentStep === "preview" && generatedImage && (
          <PreviewView
            imageUrl={generatedImage}
            onDownload={handleDownload}
            onReset={handleReset}
            isNativeSave={canUseNativePhotoSave()}
          />
        )}
      </div>

      {/* Hidden elements for processing */}
      <video
        ref={videoRef}
        className="hidden"
        muted
        playsInline
        preload="metadata"
      />
      <canvas ref={canvasRef} className="hidden" />
    </div>
  );
}
