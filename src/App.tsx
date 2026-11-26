import { useState, useRef, useEffect } from "react";
import { ChevronLeft, ScanLine } from "lucide-react";
import { useTranslation } from "react-i18next";
import { AppUtilityMenu } from "./components/AppUtilityMenu";
import { FeedbackPage } from "./components/FeedbackPage";
import { OnboardingDialog } from "./components/OnboardingDialog";
import { VideoUpload } from "./components/VideoUpload";
import { ProcessingView } from "./components/ProcessingView";
import { PreviewView } from "./components/PreviewView";
import { initGA, logPageView, trackEvent } from "./lib/analytics";
import {
  ANALYTICS_EVENTS,
  getVideoFileAnalytics,
  getVideoMetadataAnalytics,
  type TaskErrorCode,
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
  const [selection, setSelection] = useState<{
    file: File;
    source: VideoSelectionSource;
  } | null>(null);
  const selectedVideo = selection?.file ?? null;
  const [videoPreviewUrl, setVideoPreviewUrl] = useState<string | null>(null);
  const [processProgress, setProcessProgress] = useState(0);
  const [generatedImage, setGeneratedImage] = useState<string | null>(null);
  const [engineStatus, setEngineStatus] = useState<
    "loading" | "ready" | "failed"
  >("loading");
  const [recordingStatus, setRecordingStatus] = useState<
    "checking" | "ready" | "unreadable"
  >("checking");
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
  const videoPickerRef = useRef<HTMLButtonElement>(null);
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
    if (selection && videoRef.current) {
      const url = URL.createObjectURL(selection.file);
      const videoElement = videoRef.current;

      const task = taskRef.current;
      const handleMetadataError = () => {
        setRecordingStatus("unreadable");
        task?.error("import", "metadata_unreadable");
      };
      const handleLoadedMetadata = () => {
        const { duration, videoWidth, videoHeight } = videoElement;
        if (
          !Number.isFinite(duration) ||
          duration <= 0 ||
          videoWidth <= 0 ||
          videoHeight <= 0
        ) {
          handleMetadataError();
          return;
        }
        setVideoMetadata({
          durationSeconds: duration,
          width: videoWidth,
          height: videoHeight,
        });
        setRecordingStatus("ready");
        task?.imported(
          getVideoMetadataAnalytics(duration, videoWidth, videoHeight),
        );
      };
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
  }, [selection]);

  useEffect(() => {
    let active = true;
    const loadOpenCV = async () => {
      try {
        await import("./lib/opencv").then((m) => m.getOpenCV());
        if (active) setEngineStatus("ready");
      } catch (error) {
        if (active) setEngineStatus("failed");
        console.error("Failed to load OpenCV:", error);
      }
    };
    void loadOpenCV();
    return () => {
      active = false;
    };
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
    setRecordingStatus("checking");
    setVideoMetadata({});
    setVideoPreviewUrl(null);
    setLastProcessingError(null);
    setProcessingLogs([]);
    setSelection(file ? { file, source } : null);
  };

  const handleStartProcessing = async (): Promise<void> => {
    if (
      processingRef.current ||
      !selection ||
      recordingStatus !== "ready" ||
      engineStatus !== "ready"
    )
      return;
    processingRef.current = true;
    const video = videoRef.current;
    const canvas = canvasRef.current;
    if (lastProcessingError !== null && video && !isNativeIos) {
      taskRef.current = new AnalyticsTask(
        getVideoFileAnalytics(selection.file, selection.source),
      );
      taskRef.current.imported(
        getVideoMetadataAnalytics(
          video.duration,
          video.videoWidth,
          video.videoHeight,
        ),
      );
    }
    const task = taskRef.current;
    task?.startGeneration();
    setIsUtilityMenuOpen(false);
    setCurrentView("main");
    setCurrentStep("processing");
    setProcessProgress(0);
    setProcessingLogs([]);
    setLastProcessingError(null);

    let failureCode: TaskErrorCode = "processing_failed";
    try {
      if (!video || !canvas) {
        failureCode = "resources_unavailable";
        throw new Error("Video or canvas ref not available");
      }
      const addProcessingLog = (message: string) => {
        console.log(message);
        setProcessingLogs((previous) => [...previous.slice(-199), message]);
      };
      canvas.width = 0;
      canvas.height = 0;
      const { processVideo } = await import("./lib/picsew");
      const result = await processVideo(
        video,
        addProcessingLog,
        canvas,
        (progress) => setProcessProgress(Math.round(progress)),
      );
      if (result !== "success") {
        failureCode = result;
        throw new Error("Screenshot generation did not complete.");
      }
      const imageUrl = canvas.toDataURL("image/png");
      if (imageUrl === "data:," || !canvas.width || !canvas.height) {
        failureCode = "empty_output";
        throw new Error("No screenshot was generated.");
      }
      task?.generated();
      setGeneratedImage(imageUrl);
      setCurrentStep("preview");
    } catch (error) {
      setLastProcessingError(
        error instanceof Error ? error.message : String(error),
      );
      task?.error("generate", failureCode);
      console.error("Processing failed:", error);
      setCurrentStep("upload");
    } finally {
      processingRef.current = false;
    }
  };

  const handleReset = () => {
    taskRef.current?.cancel("reset");
    taskRef.current = null;
    setIsUtilityMenuOpen(false);
    setCurrentView("main");
    setCurrentStep("upload");
    setSelection(null);
    setVideoPreviewUrl(null);
    setProcessProgress(0);
    setGeneratedImage(null);
    setRecordingStatus("checking");
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
      throw error;
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
            engineStatus={engineStatus}
            recordingStatus={recordingStatus}
            generationFailed={lastProcessingError !== null}
            videoPickerRef={videoPickerRef}
            onReload={() => window.location.reload()}
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
        onRestoreFocus={() => videoPickerRef.current?.focus()}
      />
    </div>
  );
}
