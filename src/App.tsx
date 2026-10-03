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
  sanitizeAnalyticsErrorMessage,
  type VideoSelectionSource,
} from "./lib/analytics-events";
import SEO from "./components/SEO";
import {
  canUseNativePhotoSave,
  canUseNativeVideoImport,
  isLikelyUserCancellation,
  isNativeIosApp,
  pickNativeVideo,
  saveImageToPhotos,
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
    setIsUtilityMenuOpen(false);
    setCurrentView("main");
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
