import { useRef } from 'react';
import { Upload, Video, X, Play } from 'lucide-react';
import { Button } from './ui/button';
import { Card } from './ui/card';

interface VideoUploadProps {
  selectedVideo: File | null;
  videoPreviewUrl: string | null;
  onVideoSelect: (file: File) => void;
  onStartProcessing: () => void;
}

export function VideoUpload({
  selectedVideo,
  videoPreviewUrl,
  onVideoSelect,
  onStartProcessing,
}: VideoUploadProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file && file.type.startsWith('video/')) {
      onVideoSelect(file);
    }
  };

  const handleClearVideo = () => {
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
    onVideoSelect(null as unknown as File);
  };

  return (
    <div className="max-w-md mx-auto space-y-4">
      <Card className="p-6">
        <h2 className="mb-4">上传录屏视频</h2>
        
        {!selectedVideo ? (
          <div
            onClick={() => fileInputRef.current?.click()}
            className="border-2 border-dashed border-gray-300 rounded-2xl p-8 text-center cursor-pointer hover:border-blue-400 hover:bg-blue-50/50 transition-colors"
          >
            <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Upload className="w-8 h-8 text-blue-600" />
            </div>
            <p className="text-gray-600 mb-2">点击上传视频</p>
            <p className="text-xs text-gray-400">支持 MP4, MOV, AVI 等格式</p>
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
          className="w-full h-14 text-base bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700"
        >
          <Play className="w-5 h-5 mr-2" />
          开始处理
        </Button>
      )}

      <Card className="p-4 bg-blue-50 border-blue-100">
        <h3 className="text-sm mb-2 text-blue-900">使用说明</h3>
        <ul className="text-xs text-blue-700 space-y-1">
          <li>• 上传包含滑动操作的录屏视频</li>
          <li>• 系统会自动识别滑动内容</li>
          <li>• 生成一张完整的长截图</li>
          <li>• 支持预览和下载保存</li>
        </ul>
      </Card>
    </div>
  );
}