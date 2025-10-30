// 使用动态导入来避免 TypeScript 类型问题
let opencvReady = false;
let opencvLoadPromise: Promise<any> | null = null;
let cvInstance: any = null;

export const loadOpenCV = async (): Promise<void> => {
  if (opencvReady) {
    return;
  }

  if (opencvLoadPromise) {
    await opencvLoadPromise;
    return;
  }

  // 使用动态导入来获取 Promise
  opencvLoadPromise = import('@techstark/opencv-js').then(module => {
    // 模块导出的默认值是一个 Promise
    return module.default;
  });
  
  try {
    cvInstance = await opencvLoadPromise;
    opencvReady = true;
  } catch (error) {
    throw new Error(`OpenCV.js 加载失败: ${error}`);
  }
};

export const getOpenCV = (): any => {
  if (!opencvReady || !cvInstance) {
    throw new Error('OpenCV.js 尚未加载完成，请先调用 loadOpenCV()');
  }
  return cvInstance;
};

export const isOpenCVReady = (): boolean => opencvReady;