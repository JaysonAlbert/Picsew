import { useState, useRef, useEffect } from 'react';
import { Upload, Image, Play, Check, Smartphone } from 'lucide-react';
import { VideoUpload } from './components/VideoUpload';
import { ProcessingView } from './components/ProcessingView';
import { PreviewView } from './components/PreviewView';
import { processVideo as picsewProcessVideo } from './lib/picsew';
import { preloadOpenCV, isOpenCVLoaded } from './lib/opencv';

type AppStep = 'upload' | 'processing' | 'preview';

export default function App() {
  const [currentStep, setCurrentStep] = useState<AppStep>('upload');
  const [selectedVideo, setSelectedVideo] = useState<File | null>(null);
  const [videoPreviewUrl, setVideoPreviewUrl] = useState<string | null>(null);
  const [processProgress, setProcessProgress] = useState(0);
  const [generatedImage, setGeneratedImage] = useState<string | null>(null);
  const [isOpenCVReady, setIsOpenCVReady] = useState(false);
  const [isOpenCVLoading, setIsOpenCVLoading] = useState(false);

  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  // 应用启动后立即预加载OpenCV
  useEffect(() => {
    if (!isOpenCVReady && !isOpenCVLoading) {
      setIsOpenCVLoading(true);
      preloadOpenCV();
      
      // 检查OpenCV是否已加载完成
      const checkOpenCVStatus = () => {
        if (isOpenCVLoaded()) {
          setIsOpenCVReady(true);
          setIsOpenCVLoading(false);
          console.log('OpenCV.js 已准备就绪');
        } else {
          // 如果还没加载完成，继续检查
          setTimeout(checkOpenCVStatus, 100);
        }
      };
      
      // 延迟检查，给预加载一些时间
      setTimeout(checkOpenCVStatus, 500);
    }
  }, [isOpenCVReady, isOpenCVLoading]);

  useEffect(() => {
    if (selectedVideo && videoRef.current) {
      const url = URL.createObjectURL(selectedVideo);
      videoRef.current.src = url;
      setVideoPreviewUrl(url);

      return () => {
        URL.revokeObjectURL(url);
      };
    }
  }, [selectedVideo]);

  const handleVideoSelect = (file: File) => {
    setSelectedVideo(file);
  };

  const handleStartProcessing = async () => {
    setCurrentStep('processing');
    setProcessProgress(0);

    if (videoRef.current && canvasRef.current) {
      await picsewProcessVideo(
        videoRef.current,
        console.log, // or a state-based logger
        canvasRef.current,
        (p) => setProcessProgress(Math.round(p))
      );
      const imageUrl = canvasRef.current.toDataURL('image/png');
      setGeneratedImage(imageUrl);
      setCurrentStep('preview');
    } else {
      console.error("Video or canvas ref not available");
      // Handle error appropriately
      handleReset();
    }
  };

  const handleReset = () => {
    setCurrentStep('upload');
    setSelectedVideo(null);
    setVideoPreviewUrl(null);
    setProcessProgress(0);
    setGeneratedImage(null);
    if (videoRef.current) {
      videoRef.current.src = '';
    }
  };

  const handleDownload = () => {
    if (generatedImage) {
      const link = document.createElement('a');
      link.href = generatedImage;
      link.download = 'long-screenshot.png';
      link.click();
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      {/* Header */}
      <div className="bg-white border-b sticky top-0 z-10 shadow-sm">
        <div className="px-4 py-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center">
              <Smartphone className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-lg">长截图生成器</h1>
              <p className="text-xs text-gray-500">录屏转长图工具</p>
            </div>
          </div>
        </div>
      </div>

      {/* Progress Steps */}
      <div className="px-4 py-6 bg-white border-b">
        <div className="flex items-center justify-between max-w-md mx-auto">
          <div className="flex flex-col items-center gap-2 flex-1">
            <div className={`w-10 h-10 rounded-full flex items-center justify-center transition-colors ${
              currentStep === 'upload' 
                ? 'bg-blue-500 text-white' 
                : 'bg-green-500 text-white'
            }`}>
              {currentStep === 'upload' ? <Upload className="w-5 h-5" /> : <Check className="w-5 h-5" />}
            </div>
            <span className="text-xs text-center">选择视频</span>
          </div>
          
          <div className={`h-0.5 flex-1 mx-2 ${
            currentStep === 'upload' ? 'bg-gray-200' : 'bg-green-500'
          }`} />
          
          <div className="flex flex-col items-center gap-2 flex-1">
            <div className={`w-10 h-10 rounded-full flex items-center justify-center transition-colors ${
              currentStep === 'upload' 
                ? 'bg-gray-200 text-gray-400'
                : currentStep === 'processing'
                ? 'bg-blue-500 text-white'
                : 'bg-green-500 text-white'
            }`}>
              {currentStep === 'preview' ? <Check className="w-5 h-5" /> : <Play className="w-5 h-5" />}
            </div>
            <span className="text-xs text-center">处理中</span>
          </div>
          
          <div className={`h-0.5 flex-1 mx-2 ${
            currentStep === 'preview' ? 'bg-green-500' : 'bg-gray-200'
          }`} />
          
          <div className="flex flex-col items-center gap-2 flex-1">
            <div className={`w-10 h-10 rounded-full flex items-center justify-center transition-colors ${
              currentStep === 'preview'
                ? 'bg-green-500 text-white'
                : 'bg-gray-200 text-gray-400'
            }`}>
              {currentStep === 'preview' ? <Check className="w-5 h-5" /> : <Image className="w-5 h-5" />}
            </div>
            <span className="text-xs text-center">预览下载</span>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="px-4 py-6 pb-24">
        {currentStep === 'upload' && (
          <VideoUpload
            selectedVideo={selectedVideo}
            videoPreviewUrl={videoPreviewUrl}
            onVideoSelect={handleVideoSelect}
            onStartProcessing={handleStartProcessing}
            isOpenCVReady={isOpenCVReady}
            isOpenCVLoading={isOpenCVLoading}
          />
        )}

        {currentStep === 'processing' && (
          <ProcessingView progress={processProgress} />
        )}

        {currentStep === 'preview' && generatedImage && (
          <PreviewView
            imageUrl={generatedImage}
            onDownload={handleDownload}
            onReset={handleReset}
          />
        )}
      </div>

      {/* Hidden elements for processing */}
      <video ref={videoRef} className="hidden" muted playsInline />
      <canvas ref={canvasRef} className="hidden" />
    </div>
  );
}
