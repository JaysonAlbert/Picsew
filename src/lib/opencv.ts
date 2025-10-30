import type cv from '@techstark/opencv-js';

type Cv = typeof cv;

let cvPromise: Promise<Cv> | null = null;
let isPreloading = false;

// 预加载OpenCV，不阻塞主线程
export function preloadOpenCV(): void {
  if (!cvPromise && !isPreloading) {
    isPreloading = true;
    cvPromise = import('@techstark/opencv-js').then(module => {
      console.log('OpenCV.js 预加载完成');
      return module.default;
    }).catch(error => {
      console.error('OpenCV.js 预加载失败:', error);
      isPreloading = false;
      cvPromise = null;
      throw error;
    });
  }
}

export async function getOpenCV(): Promise<Cv> {
  if (!cvPromise) {
    // 如果没有预加载，则立即加载
    cvPromise = import('@techstark/opencv-js').then(module => {
      return module.default;
    });
  }
  return cvPromise;
}

// 检查OpenCV是否已加载完成
export function isOpenCVLoaded(): boolean {
  return cvPromise !== null;
}
