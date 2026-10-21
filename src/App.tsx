import { useState, useRef, useEffect } from "react";
import { ChevronLeft, ScanLine } from "lucide-react";
import { useTranslation } from "react-i18next";
import { AppUtilityMenu } from "./components/AppUtilityMenu";
import { FeedbackPage } from "./components/FeedbackPage";
import { OnboardingDialog } from "./components/OnboardingDialog";
import { VideoUpload } from "./components/VideoUpload";
import { ProcessingView } from "./components/ProcessingView";
import { PreviewView } from "./components/PreviewView";
import { processVideo as picsewProcessVideo } from "./lib/picsew";
import { initGA, logPageView, trackEvent } from "./lib/analytics";
import {
  ANALYTICS_EVENTS,
  getVideoFileAnalytics,
  getVideoMetadataAnalytics,
  type VideoSelectionSource,
} from "./lib/analytics-events";
import { AnalyticsTask } from "./lib/analytics-task";
import SEO from "./components/SEO";
import {
  canUseNativePhotoSave,
  canUseNativeVideoImport,
  isLikelyUserCancellation,
  isNativeIosApp,
  pickNativeVideo,
  saveImageToPhotos,
  shareGeneratedImage,
} from "./lib/native-media";

type AppStep = "upload" | "processing" | "preview";
type AppView = "main" | "feedback";
type VideoMetadata = {
  durationSeconds?: number;
  width?: number;
  height?: number;
};

const ONBOARDING_STORAGE_KEY = "picsew:onboarding-seen:v1";

export default function App() {
  const { t } = useTranslation();
  const isNativeIos = isNativeIosApp();
  const [currentStep, setCurrentStep] = useState<AppStep>("upload");
  const [currentView, setCurrentView] = useState<AppView>("main");
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
  const [isUtilityMenuOpen, setIsUtilityMenuOpen] = useState(false);
  const [showOnboarding, setShowOnboarding] = useState(false);

  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const taskRef = useRef<AnalyticsTask | null>(null);
  const processingRef = useRef(false);
  const exportingRef = useRef(false);

  useEffect(() => {
    initGA();
  }, []);

  useEffect(() => {
    logPageView(currentView === "feedback" ? "/feedback" : `/${currentStep}`);
  }, [currentStep, currentView]);

  useEffect(() => {
    if (currentStep === "preview" && generatedImage) {
      trackEvent(ANALYTICS_EVENTS.previewShown);
    }
  }, [currentStep, generatedImage]);

  useEffect(() => {
    if (selectedVideo && videoRef.current) {
      const url = URL.createObjectURL(selectedVideo);
      const videoElement = videoRef.current;

      const task = taskRef.current;
      const handleLoadedMetadata = () => {
        setVideoMetadata({
          durationSeconds: videoElement.duration,
          width: videoElement.videoWidth,
          height: videoElement.videoHeight,
        });
        if (
          Number.isFinite(videoElement.duration) &&
          videoElement.duration > 0 &&
          videoElement.videoWidth > 0 &&
          videoElement.videoHeight > 0
        ) {
          task?.imported(
            getVideoMetadataAnalytics(
              videoElement.duration,
              videoElement.videoWidth,
              videoElement.videoHeight,
            ),
          );
        } else {
          task?.error("import", "metadata_unreadable");
        }
      };

      const handleMetadataError = () =>
        task?.error("import", "metadata_unreadable");
      videoElement.addEventListener("error", handleMetadataError, {
        once: true,
      });
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
        videoElement.removeEventListener("error", handleMetadataError);
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

  useEffect(() => {
    if (typeof window === "undefined") {
      return;
    }

    if (!window.localStorage.getItem(ONBOARDING_STORAGE_KEY)) {
      setShowOnboarding(true);
    }
  }, []);

  const dismissOnboarding = () => {
    if (typeof window !== "undefined") {
      window.localStorage.setItem(ONBOARDING_STORAGE_KEY, "1");
    }
    setShowOnboarding(false);
  };

  const handleVideoSelect = (
    file: File | null,
    source: VideoSelectionSource = "picker",
  ) => {
    taskRef.current?.cancel(file ? "replace" : "clear");
    taskRef.current =
      file && !isNativeIos
        ? new AnalyticsTask(getVideoFileAnalytics(file, source))
        : null;
    setVideoMetadata({});
    setSelectedVideo(file);
  };

  const handleStartProcessing = async (): Promise<void> => {
    if (processingRef.current) return;
    processingRef.current = true;
    const task = taskRef.current;
    task?.startGeneration();
    setIsUtilityMenuOpen(false);
    setCurrentView("main");
    setCurrentStep("processing");
    setProcessProgress(0);
    setProcessingLogs([]);
    setLastProcessingError(null);

    if (videoRef.current && canvasRef.current) {
      const addProcessingLog = (message: string) => {
        console.log(message);
        setProcessingLogs((previous) => [...previous.slice(-199), message]);
      };
      try {
        canvasRef.current.width = 0;
        canvasRef.current.height = 0;
        const result = await picsewProcessVideo(
          videoRef.current,
          addProcessingLog,
          canvasRef.current,
          (p) => setProcessProgress(Math.round(p)),
        );
        if (result !== "success") {
          task?.error("generate", result);
          throw new Error("Screenshot generation did not complete.");
        }
        const imageUrl = canvasRef.current.toDataURL("image/png");
        if (
          imageUrl === "data:," ||
          !canvasRef.current.width ||
          !canvasRef.current.height
        ) {
          task?.error("generate", "empty_output");
          throw new Error("No screenshot was generated.");
        }
        task?.generated();
        setGeneratedImage(imageUrl);
        setCurrentStep("preview");
      } catch (error) {
        setLastProcessingError(
          error instanceof Error ? error.message : String(error),
        );
        task?.error("generate", "processing_failed");
        console.error("Processing failed:", error);
        alert(
          `Processing failed: ${error instanceof Error ? error.message : String(error)}`,
        );
        handleReset();
      }
    } else {
      console.error("Video or canvas ref not available");
      task?.error("generate", "resources_unavailable");
      handleReset();
    }
    processingRef.current = false;
  };

  const handleReset = () => {
    taskRef.current?.cancel("reset");
    taskRef.current = null;
    setIsUtilityMenuOpen(false);
    setCurrentView("main");
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

    if (exportingRef.current) return;
    exportingRef.current = true;
    const task = taskRef.current;
    task?.requestExport("download");

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

      task?.dispatched("download");
    } catch (error) {
      task?.error("export", "export_failed", "download");
      console.error("Failed to export image:", error);
      alert(t("preview.save.failed"));
    } finally {
      exportingRef.current = false;
    }
  };

  const handleShare = async () => {
    if (!generatedImage || exportingRef.current) return;
    exportingRef.current = true;
    const task = taskRef.current;
    task?.requestExport("share");
    try {
      await shareGeneratedImage(generatedImage, {
        title: t("preview.share.title"),
        text: t("preview.share.text"),
        fileName: "long-screenshot.png",
      });
      task?.dispatched("share");
    } catch (error) {
      // Web Share signals explicit cancellation with AbortError; never classify by raw text.
      if (error instanceof Error && error.name === "AbortError")
        task?.cancel("share_cancelled");
      else task?.error("export", "export_failed", "share");
    } finally {
      exportingRef.current = false;
    }
  };

  const handleOpenFeedbackPage = () => {
    setIsUtilityMenuOpen(false);
    setCurrentView("feedback");
    trackEvent(ANALYTICS_EVENTS.feedbackOpened, {
      feedback_stage: currentStep,
    });
  };

  const isPreview = currentView === "main" && currentStep === "preview";

  return (
    <div
      className={`product-shell ${isPreview ? "product-shell--preview" : ""} ${isNativeIos ? "ios-app-shell" : ""}`}
    >
      <SEO
        title={t("app.title")}
        description={t("app.subtitle")}
        keywords="screenshot, stitching, long screenshot, video to image, picsew"
      />
      {!isPreview && (
        <header className="product-header ios-safe-top">
          {currentView === "feedback" ? (
            <button
              type="button"
              className="app-secondary-back"
              onClick={() => setCurrentView("main")}
            >
              <ChevronLeft aria-hidden="true" />
              <span>{t("feedback.page.back")}</span>
            </button>
          ) : (
            <>
              <div className="product-brand">
                <ScanLine aria-hidden="true" />
                <span>{t("app.brandTitle")}</span>
              </div>
              <AppUtilityMenu
                open={isUtilityMenuOpen}
                onOpenChange={setIsUtilityMenuOpen}
                onOpenFeedbackPage={handleOpenFeedbackPage}
              />
            </>
          )}
        </header>
      )}
      <main className="product-main">
        {currentView === "main" && !isPreview && (
          <div className="product-heading">
            <h1>{t(`app.routes.${currentStep}.title`)}</h1>
            <p>{t(`app.routes.${currentStep}.subtitle`)}</p>
          </div>
        )}
        {currentView === "feedback" ? (
          <FeedbackPage
            currentStep={currentStep}
            videoMetadata={videoMetadata}
            lastProcessingError={lastProcessingError}
            processingLogs={processingLogs}
            onBack={() => setCurrentView("main")}
          />
        ) : currentStep === "upload" ? (
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
        ) : currentStep === "processing" ? (
          <ProcessingView progress={processProgress} />
        ) : (
          <PreviewView
            imageUrl={generatedImage!}
            onDownload={handleDownload}
            onShare={handleShare}
            onReset={handleReset}
            isNativeSave={canUseNativePhotoSave()}
          />
        )}
      </main>

      {/* Hidden elements for processing */}
      <video
        ref={videoRef}
        className="hidden"
        muted
        playsInline
        preload="metadata"
      />
      <canvas ref={canvasRef} className="hidden" />

      <OnboardingDialog
        open={showOnboarding}
        onSkip={dismissOnboarding}
        onStart={dismissOnboarding}
      />
    </div>
  );
}
