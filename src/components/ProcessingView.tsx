import { Loader2, Film, Scan, Layers, Blend, Scissors } from 'lucide-react';
import { Card } from './ui/card';
import { Progress } from './ui/progress';

interface ProcessingViewProps {
  progress: number;
}

export function ProcessingView({ progress }: ProcessingViewProps) {
  const getProcessingStage = () => {
    if (progress < 10) return { icon: Film, text: '准备中...' };
    if (progress < 30) return { icon: Film, text: '提取视频帧...' };
    if (progress < 50) return { icon: Scan, text: '查找滚动窗口...' };
    if (progress < 70) return { icon: Scissors, text: '选择关键帧...' };
    if (progress < 85) return { icon: Blend, text: '过滤关键帧...' };
    if (progress < 95) return { icon: Layers, text: '拼接长截图...' };
    return { icon: Layers, text: '生成最终图像...' };
  };

  const stage = getProcessingStage();
  const StageIcon = stage.icon;

  return (
    <div className="max-w-md mx-auto">
      <Card className="p-8">
        <div className="text-center space-y-6">
          <div className="relative w-24 h-24 mx-auto">
            <div className="absolute inset-0 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full opacity-20 animate-pulse" />
            <div className="absolute inset-2 bg-white rounded-full flex items-center justify-center">
              <StageIcon className="w-10 h-10 text-blue-600" />
            </div>
            <Loader2 className="w-24 h-24 text-blue-600 animate-spin" />
          </div>

          <div>
            <h2 className="mb-2">处理中</h2>
            <p className="text-sm text-gray-500">{stage.text}</p>
          </div>

          <div className="space-y-2">
            <Progress value={progress} className="h-2" />
            <p className="text-sm text-gray-600">{progress}%</p>
          </div>

          <div className="pt-4 space-y-2 text-left">
            <div className="flex items-center gap-3 text-xs text-gray-500">
              <div className={`w-2 h-2 rounded-full transition-colors ${progress >= 30 ? 'bg-green-500' : 'bg-gray-300'}`} />
              <span>视频帧分析</span>
            </div>
            <div className="flex items-center gap-3 text-xs text-gray-500">
              <div className={`w-2 h-2 rounded-full transition-colors ${progress >= 70 ? 'bg-green-500' : 'bg-gray-300'}`} />
              <span>关键帧选择</span>
            </div>
            <div className="flex items-center gap-3 text-xs text-gray-500">
              <div className={`w-2 h-2 rounded-full transition-colors ${progress >= 100 ? 'bg-green-500' : 'bg-gray-300'}`} />
              <span>长截图生成</span>
            </div>
          </div>
        </div>
      </Card>

      <div className="mt-6 p-4 bg-amber-50 border border-amber-100 rounded-xl">
        <p className="text-xs text-amber-800 text-center">
          请稍候，处理时间取决于视频长度和内容复杂度
        </p>
      </div>
    </div>
  );
}
