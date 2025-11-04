import { getOpenCV } from "./opencv";

const FRAME_RATE = 10; // frames per second

const extractFrames = async (
  videoElement: HTMLVideoElement,
  addLog: (message: string) => void,
  updateProgress: (progress: number) => void,
): Promise<{ fullRes: any[]; lowResGray: any[] }> => {
  addLog("Extracting frames...");
  const cv = await getOpenCV();
  const fullResFrames: any[] = [];
  const lowResGrayFrames: any[] = [];

  return new Promise((resolve, reject) => {
    (async () => {
      try {
        // 创建离屏画布用于转换帧数据
        const canvas = document.createElement("canvas");
        const context = canvas.getContext("2d", { willReadFrequently: true });
        if (!context) {
          throw new Error("Could not get 2D context");
        }

        canvas.width = videoElement.videoWidth;
        canvas.height = videoElement.videoHeight;

        let frameCount = 0;
        const targetFrameCount = Math.floor(videoElement.duration * FRAME_RATE);
        let lastFrameTime = 0;
        const frameInterval = 1000 / FRAME_RATE; // 毫秒
        let isProcessing = true;

        const processFrame = (_now: number, _metadata: any) => {
          try {
            if (!isProcessing) return;

            const currentTime = performance.now();

            // 控制帧率，避免处理过多帧
            if (currentTime - lastFrameTime >= frameInterval) {
              // 使用更高效的 drawImage，但通过 requestVideoFrameCallback 避免阻塞
              context.drawImage(
                videoElement,
                0,
                0,
                canvas.width,
                canvas.height,
              );
              const imageData = context.getImageData(
                0,
                0,
                canvas.width,
                canvas.height,
              );
              const fullResFrame = cv.matFromImageData(imageData);
              fullResFrames.push(fullResFrame);

              // 创建低分辨率灰度图
              const lowResFrame = new cv.Mat();
              const scaleFactor = 0.5;
              cv.resize(
                fullResFrame,
                lowResFrame,
                new cv.Size(0, 0),
                scaleFactor,
                scaleFactor,
                cv.INTER_AREA,
              );

              const grayFrame = new cv.Mat();
              cv.cvtColor(lowResFrame, grayFrame, cv.COLOR_RGBA2GRAY);
              lowResGrayFrames.push(grayFrame);

              lowResFrame.delete();

              frameCount++;
              lastFrameTime = currentTime;

              // 更新进度
              const progress = (frameCount / targetFrameCount) * 100;
              updateProgress(Math.min(progress, 100));
            }

            // 检查是否完成
            if (
              frameCount >= targetFrameCount ||
              videoElement.ended ||
              videoElement.currentTime >= videoElement.duration - 0.1
            ) {
              isProcessing = false;
              addLog(`Extracted ${fullResFrames.length} frames.`);
              resolve({ fullRes: fullResFrames, lowResGray: lowResGrayFrames });
              return;
            }

            // 继续处理下一帧
            videoElement.requestVideoFrameCallback(processFrame);
          } catch (error) {
            isProcessing = false;
            reject(error);
          }
        };

        // 确保视频已加载元数据
        if (videoElement.readyState < HTMLMediaElement.HAVE_METADATA) {
          videoElement.addEventListener("loadedmetadata", () => {
            videoElement.requestVideoFrameCallback(processFrame);
            videoElement.play().catch(reject);
          });
        } else {
          videoElement.requestVideoFrameCallback(processFrame);
          videoElement.play().catch(reject);
        }

        // 设置超时保护
        setTimeout(
          () => {
            if (isProcessing) {
              addLog("Frame extraction timeout");
              isProcessing = false;
              reject(new Error("Frame extraction timeout"));
            }
          },
          Math.max(videoElement.duration * 1000 * 2, 30000),
        ); // 2倍视频时长或30秒
      } catch (error) {
        addLog(`Frame extraction failed: ${error}`);
        reject(error);
      }
    })();
  });
};

const findRefinedScrollingWindow = async (
  lowResGrayFrames: any[],
  addLog: (message: string) => void,
) => {
  addLog("Finding refined scrolling window...");
  const cv = await getOpenCV();

  // 检查输入帧是否有效
  if (lowResGrayFrames.length === 0 || !lowResGrayFrames[0]) {
    addLog("Error: No valid frames to process");
    return null;
  }

  const motionAccumulator = cv.Mat.zeros(
    lowResGrayFrames[0].rows,
    lowResGrayFrames[0].cols,
    cv.CV_32F,
  );

  for (let i = 0; i < lowResGrayFrames.length - 1; i++) {
    // 检查当前帧和下一帧是否有效
    if (!lowResGrayFrames[i] || !lowResGrayFrames[i + 1]) {
      addLog(`Warning: Invalid frame at index ${i}, skipping`);
      continue;
    }

    const diff = new cv.Mat();
    cv.absdiff(lowResGrayFrames[i], lowResGrayFrames[i + 1], diff);

    const thresh = new cv.Mat();
    cv.threshold(diff, thresh, 30, 255, cv.THRESH_BINARY);

    const thresh32F = new cv.Mat();
    thresh.convertTo(thresh32F, cv.CV_32F);

    cv.add(motionAccumulator, thresh32F, motionAccumulator);

    diff.delete();
    thresh.delete();
    thresh32F.delete();
  }

  cv.normalize(motionAccumulator, motionAccumulator, 0, 255, cv.NORM_MINMAX);
  const motionMask = new cv.Mat();
  cv.threshold(motionAccumulator, motionMask, 50, 255, cv.THRESH_BINARY);
  motionAccumulator.delete();
  motionMask.convertTo(motionMask, cv.CV_8U);

  const contours = new cv.MatVector();
  const hierarchy = new cv.Mat();
  cv.findContours(
    motionMask,
    contours,
    hierarchy,
    cv.RETR_EXTERNAL,
    cv.CHAIN_APPROX_SIMPLE,
  );
  hierarchy.delete();

  if (contours.size() === 0) {
    addLog("No consistent motion detected.");
    motionMask.delete();
    contours.delete();
    return null;
  }

  let largestContour;
  let maxArea = 0;
  for (let i = 0; i < contours.size(); i++) {
    const contour = contours.get(i);
    const area = cv.contourArea(contour);
    if (area > maxArea) {
      maxArea = area;
      largestContour = contour;
    }
  }

  const boundingRect = cv.boundingRect(largestContour!);
  const frameWidth = lowResGrayFrames[0].cols;

  // 由于是低分辨率，需要将坐标和尺寸缩放到全分辨率
  const scaleFactor = 2; // 因为下采样比例是0.5
  const originalFullWidthWindow = {
    x: 0,
    y: boundingRect.y * scaleFactor,
    width: frameWidth * scaleFactor,
    height: boundingRect.height * scaleFactor,
  };

  const outsideMask = cv.Mat.ones(
    lowResGrayFrames[0].rows,
    lowResGrayFrames[0].cols,
    cv.CV_8U,
  );
  outsideMask.setTo(new cv.Scalar(255));
  const roi = new cv.Rect(0, boundingRect.y, frameWidth, boundingRect.height);
  const outsideMaskRoi = outsideMask.roi(roi);
  outsideMaskRoi.setTo(new cv.Scalar(0));
  outsideMaskRoi.delete();

  const insetPixels = Math.floor(boundingRect.height * 0.1);
  const refinedWindow = {
    x: 0,
    y: (boundingRect.y + insetPixels) * scaleFactor,
    width: frameWidth * scaleFactor,
    height: (boundingRect.height - insetPixels * 2) * scaleFactor,
  };

  addLog(
    `Detected refined window: { x: ${refinedWindow.x}, y: ${refinedWindow.y}, width: ${refinedWindow.width}, height: ${refinedWindow.height} }`,
  );

  contours.delete();
  motionMask.delete();

  return { refinedWindow, originalFullWidthWindow, outsideMask };
};

const selectKeyframes = async (
  lowResGrayFrames: any[],
  refinedWindow: any,
  addLog: (message: string) => void,
): Promise<number[]> => {
  addLog("Selecting keyframes...");
  const cv = await getOpenCV();

  // 检查输入帧是否有效
  if (lowResGrayFrames.length === 0) {
    addLog("Error: No frames to process");
    return [0];
  }

  // 将全分辨率窗口坐标转换为低分辨率坐标
  const scaleFactor = 0.5; // 因为下采样比例是0.5
  const x = refinedWindow.x * scaleFactor;
  const y = refinedWindow.y * scaleFactor;
  const width = refinedWindow.width * scaleFactor;
  const height = refinedWindow.height * scaleFactor;

  const candidateKeyframeIndices: number[] = [0];
  let lastKeyframeIndex = 0;

  while (lastKeyframeIndex < lowResGrayFrames.length - 1) {
    let accumulatedOffset = 0;
    let lastFrameInChunk = lowResGrayFrames[lastKeyframeIndex];

    // 检查当前帧是否有效
    if (!lastFrameInChunk) {
      addLog("Warning: Invalid frame detected, stopping keyframe selection");
      break;
    }

    let foundNextKeyframe = false;
    for (let i = lastKeyframeIndex + 1; i < lowResGrayFrames.length; i++) {
      const currentFrame = lowResGrayFrames[i];

      // 检查当前帧是否有效
      if (!currentFrame) {
        addLog(`Warning: Invalid frame at index ${i}, skipping`);
        continue;
      }

      const templateHeight = Math.floor(height / 4);
      const templateYStart =
        y + Math.floor(height / 2) - Math.floor(templateHeight / 2);
      const template = lastFrameInChunk.roi(
        new cv.Rect(x, templateYStart, width, templateHeight),
      );

      const scrollingWindowContent = currentFrame.roi(
        new cv.Rect(x, y, width, height),
      );
      const res = new cv.Mat();
      cv.matchTemplate(
        scrollingWindowContent,
        template,
        res,
        cv.TM_CCOEFF_NORMED,
      );
      const minMaxLoc = cv.minMaxLoc(res, new cv.Mat());
      const maxVal = minMaxLoc.maxVal;
      const maxLoc = minMaxLoc.maxLoc;

      template.delete();
      scrollingWindowContent.delete();
      res.delete();

      if (maxVal > 0.7) {
        const offsetSinceLastFrame = templateYStart - y - maxLoc.y;
        if (offsetSinceLastFrame > 0) {
          accumulatedOffset += offsetSinceLastFrame;
        }
      }

      lastFrameInChunk = currentFrame;

      if (accumulatedOffset > height * 0.5) {
        candidateKeyframeIndices.push(i);
        lastKeyframeIndex = i;
        foundNextKeyframe = true;
        break;
      }
    }

    if (!foundNextKeyframe) {
      break;
    }
  }

  if (lastKeyframeIndex !== lowResGrayFrames.length - 1) {
    candidateKeyframeIndices.push(lowResGrayFrames.length - 1);
  }

  addLog(`Selected ${candidateKeyframeIndices.length} candidate keyframes.`);
  return candidateKeyframeIndices;
};

const filterKeyframes = async (
  candidateKeyframeIndices: number[],
  lowResGrayFrames: any[],
  originalFullWidthWindow: any,
  outsideMask: any,
  addLog: (message: string) => void,
): Promise<number[]> => {
  addLog("Filtering keyframes...");
  const cv = await getOpenCV();

  if (candidateKeyframeIndices.length === 0) {
    return [];
  }

  const firstIndex = candidateKeyframeIndices[0];
  if (firstIndex === undefined) {
    return [];
  }

  // 检查 outsideMask 是否有效
  if (!outsideMask || outsideMask.rows === 0 || outsideMask.cols === 0) {
    addLog("Warning: outsideMask is invalid, skipping filtering");
    return candidateKeyframeIndices;
  }

  const cleanKeyframeIndices: number[] = [firstIndex];

  for (let i = 1; i < candidateKeyframeIndices.length; i++) {
    const prevIndex = candidateKeyframeIndices[i - 1];
    const currIndex = candidateKeyframeIndices[i];

    if (prevIndex === undefined || currIndex === undefined) {
      continue;
    }

    const gray1 = lowResGrayFrames[prevIndex];
    const gray2 = lowResGrayFrames[currIndex];

    // 检查帧是否有效
    if (!gray1 || !gray2) {
      addLog("Warning: Invalid frame detected, skipping comparison");
      continue;
    }

    const diff = new cv.Mat();
    cv.absdiff(gray1, gray2, diff);

    const thresh = new cv.Mat();
    cv.threshold(diff, thresh, 30, 255, cv.THRESH_BINARY);

    const changesOutside = new cv.Mat();

    try {
      // 检查掩码和阈值图像的尺寸是否匹配
      if (
        thresh.rows === outsideMask.rows &&
        thresh.cols === outsideMask.cols
      ) {
        cv.bitwise_and(thresh, thresh, changesOutside, outsideMask);
      } else {
        addLog(
          "Warning: Mask and threshold image size mismatch, skipping bitwise operation",
        );
        // 如果尺寸不匹配，直接跳过这个关键帧
        diff.delete();
        thresh.delete();
        changesOutside.delete();
        continue;
      }
    } catch (e: any) {
      addLog(`Error in cv.bitwise_and: ${e.message}`);
      diff.delete();
      thresh.delete();
      changesOutside.delete();
      continue; // 继续处理下一个关键帧而不是停止执行
    }

    const totalOutsidePixels = cv.countNonZero(outsideMask);
    const changedOutsidePixels = cv.countNonZero(changesOutside);
    const changePercentage =
      totalOutsidePixels > 0
        ? (changedOutsidePixels / totalOutsidePixels) * 100
        : 0;

    diff.delete();
    thresh.delete();
    changesOutside.delete();

    if (changePercentage < 1) {
      cleanKeyframeIndices.push(currIndex);
    }
  }

  addLog(
    `Selected ${cleanKeyframeIndices.length} final keyframes after filtering.`,
  );
  return cleanKeyframeIndices;
};

const stitchKeyframes = async (
  keyframeIndices: number[],
  fullResFrames: any[],
  refinedWindow: any,
  addLog: (message: string) => void,
): Promise<any> => {
  addLog("Stitching keyframes...");
  const cv = await getOpenCV();
  const { x, y, width, height } = refinedWindow;

  // 检查输入帧是否有效
  if (keyframeIndices.length === 0 || fullResFrames.length === 0) {
    addLog("Error: No keyframes or frames to stitch");
    return null;
  }

  const frameWidth = fullResFrames[0].cols;

  // 获取全分辨率的关键帧
  const keyframes = keyframeIndices.map((index) => fullResFrames[index]);

  // 检查关键帧是否有效
  for (const frame of keyframes) {
    if (!frame) {
      addLog("Error: Invalid keyframe detected");
      return null;
    }
  }

  // 1. Calculate Offsets
  const offsets: { v_offset: number; h_offset: number }[] = [];
  for (let i = 0; i < keyframes.length - 1; i++) {
    const frame1 = keyframes[i];
    const frame2 = keyframes[i + 1];

    const window1 = frame1.roi(new cv.Rect(x, y, width, height));
    const window2 = frame2.roi(new cv.Rect(x, y, width, height));

    const templateHeight = Math.floor(height / 3);
    const template = window1.roi(
      new cv.Rect(0, height - templateHeight, width, templateHeight),
    );

    const res = new cv.Mat();
    cv.matchTemplate(window2, template, res, cv.TM_CCOEFF_NORMED);
    const minMaxLoc = cv.minMaxLoc(res, new cv.Mat());
    const maxLoc = minMaxLoc.maxLoc;

    const vOffset = height - templateHeight - maxLoc.y;
    const hOffset = maxLoc.x;
    offsets.push({ v_offset: vOffset, h_offset: hOffset });

    window1.delete();
    window2.delete();
    template.delete();
    res.delete();
  }

  // 2. Stitch the Images
  const header = keyframes[0].roi(new cv.Rect(0, 0, frameWidth, y));
  const footer = keyframes[keyframes.length - 1].roi(
    new cv.Rect(0, y + height, frameWidth, keyframes[0].rows - (y + height)),
  );

  let totalHeight = header.rows + height + footer.rows;
  for (const offset of offsets) {
    totalHeight += offset.v_offset;
  }

  const stitchedImage = new cv.Mat(
    totalHeight,
    frameWidth,
    keyframes[0].type(),
    new cv.Scalar(0, 0, 0, 0),
  );

  let currentY = 0;
  const headerRoi = new cv.Rect(0, 0, frameWidth, header.rows);
  header.copyTo(stitchedImage.roi(headerRoi));
  currentY += header.rows;

  const firstWindowRoi = new cv.Rect(0, y, frameWidth, height);
  keyframes[0]
    .roi(firstWindowRoi)
    .copyTo(stitchedImage.roi(new cv.Rect(0, currentY, frameWidth, height)));
  currentY += height;

  for (let i = 0; i < offsets.length; i++) {
    const offset = offsets[i];
    if (!offset) continue;
    const { v_offset, h_offset } = offset;
    const keyframe = keyframes[i + 1];
    const scrollingWindow = keyframe.roi(new cv.Rect(x, y, width, height));

    const newPart = scrollingWindow.roi(
      new cv.Rect(0, height - v_offset, width, v_offset),
    );

    if (newPart.rows > 0) {
      const newSlice = new cv.Mat(
        newPart.rows,
        width,
        keyframes[0].type(),
        new cv.Scalar(0, 0, 0, 0),
      );
      const newSliceRoi = new cv.Rect(h_offset, 0, newPart.cols, newPart.rows);
      newPart.copyTo(newSlice.roi(newSliceRoi));

      const stitchedImageSliceRoi = new cv.Rect(
        0,
        currentY,
        width,
        newPart.rows,
      );
      newSlice.copyTo(stitchedImage.roi(stitchedImageSliceRoi));
      currentY += newPart.rows;
      newSlice.delete();
    }
    newPart.delete();
    scrollingWindow.delete();
  }

  const footerStitchedRoi = new cv.Rect(0, currentY, frameWidth, footer.rows);
  footer.copyTo(stitchedImage.roi(footerStitchedRoi));
  currentY += footer.rows;

  header.delete();
  footer.delete();

  const finalImage = stitchedImage.roi(new cv.Rect(0, 0, frameWidth, currentY));
  stitchedImage.delete(); // 删除原始的大图像

  return finalImage;
};

export const processVideo = async (
  videoElement: HTMLVideoElement,
  addLog: (message: string) => void,
  outputCanvas: HTMLCanvasElement,
  updateProgress: (progress: number) => void,
) => {
  addLog("Processing video with OpenCV.js");
  updateProgress(5);

  let fullRes: any[] = [];
  let lowResGray: any[] = [];
  let outsideMask: any = null;

  try {
    const cv = await getOpenCV();
    addLog(`OpenCV.js version: ${cv.CV_8U}`);
    updateProgress(10);

    updateProgress(10);
    const frameResult = await extractFrames(videoElement, addLog, (p) =>
      updateProgress(10 + p * 0.2),
    ); // 10-30%
    fullRes = frameResult.fullRes;
    lowResGray = frameResult.lowResGray;

    if (fullRes.length < 2) {
      addLog("Not enough frames to process.");
      // 清理已提取的帧
      fullRes.forEach((frame: any) => frame.delete());
      lowResGray.forEach((frame: any) => frame.delete());
      return;
    }
    updateProgress(30);

    const windowInfo = await findRefinedScrollingWindow(lowResGray, addLog);
    if (!windowInfo) {
      // 清理已提取的帧
      fullRes.forEach((frame: any) => frame.delete());
      lowResGray.forEach((frame: any) => frame.delete());
      return;
    }
    updateProgress(50);

    const {
      refinedWindow,
      originalFullWidthWindow,
      outsideMask: mask,
    } = windowInfo;
    outsideMask = mask;

    const candidateKeyframeIndices = await selectKeyframes(
      lowResGray,
      refinedWindow,
      addLog,
    );
    updateProgress(70);

    const cleanKeyframeIndices = await filterKeyframes(
      candidateKeyframeIndices,
      lowResGray,
      originalFullWidthWindow,
      outsideMask,
      addLog,
    );
    updateProgress(85);

    const stitchedImage = await stitchKeyframes(
      cleanKeyframeIndices,
      fullRes,
      refinedWindow,
      addLog,
    );
    updateProgress(95);

    if (stitchedImage) {
      cv.imshow(outputCanvas, stitchedImage);
      stitchedImage.delete();
    }

    updateProgress(100);
  } catch (error) {
    addLog(`OpenCV.js 处理错误: ${error}`);
    console.error("OpenCV.js error:", error);
  } finally {
    // 确保清理所有资源
    try {
      if (outsideMask) {
        outsideMask.delete();
      }

      fullRes.forEach((frame: any) => {
        if (frame) {
          frame.delete();
        }
      });

      lowResGray.forEach((frame: any) => {
        if (frame) {
          frame.delete();
        }
      });
    } catch (cleanupError) {
      console.error("Error during cleanup:", cleanupError);
    }
  }
};
