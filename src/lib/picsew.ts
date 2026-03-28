import { getOpenCV } from "./opencv";
import {
  getErrorMessage,
  getFullResDecodeScale,
  scaleRect,
} from "./picsew-utils";

const FRAME_RATE = 6; // frames per second
/** Avoid thousands of video seeks on long recordings (file size does not imply short duration). */
const MAX_EXTRACT_FRAMES = 480;

/** iOS Safari has strict per-tab memory limits; large full-res frame buffers add up quickly. */
const isLikelyIOS =
  typeof navigator !== "undefined" &&
  (/iPad|iPhone|iPod/.test(navigator.userAgent) ||
    (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1));

const clampRectToFrame = (
  rect: { x: number; y: number; width: number; height: number },
  frameWidth: number,
  frameHeight: number,
) => {
  const safeX = Math.max(
    0,
    Math.min(Math.round(rect.x), Math.max(0, frameWidth - 1)),
  );
  const safeY = Math.max(
    0,
    Math.min(Math.round(rect.y), Math.max(0, frameHeight - 1)),
  );
  const safeWidth = Math.max(
    1,
    Math.min(Math.round(rect.width), Math.max(1, frameWidth - safeX)),
  );
  const safeHeight = Math.max(
    1,
    Math.min(Math.round(rect.height), Math.max(1, frameHeight - safeY)),
  );

  return { x: safeX, y: safeY, width: safeWidth, height: safeHeight };
};

/**
 * Helper function to seek the video to a specific time and wait for
 * the 'seeked' event to ensure the frame is ready.
 */
const seekTo = (video: HTMLVideoElement, time: number): Promise<void> => {
  return new Promise((resolve, reject) => {
    // Set a timeout in case 'seeked' never fires
    const timeoutId = setTimeout(() => {
      reject(new Error(`Video seek to ${time}s timed out.`));
    }, 5000); // 5-second timeout per seek

    const onSeeked = () => {
      clearTimeout(timeoutId);
      video.removeEventListener("seeked", onSeeked);
      video.removeEventListener("error", onError);
      resolve();
    };

    const onError = (e: Event) => {
      clearTimeout(timeoutId);
      video.removeEventListener("seeked", onSeeked);
      video.removeEventListener("error", onError);
      reject(new Error(`Failed to seek video. Error: ${e.type}`));
    };

    // Add event listeners *before* setting currentTime
    video.addEventListener("seeked", onSeeked, { once: true });
    video.addEventListener("error", onError, { once: true });

    video.currentTime = time;
  });
};

const extractFrames = async (
  videoElement: HTMLVideoElement,
  addLog: (message: string) => void,
  updateProgress: (progress: number) => void,
): Promise<{ lowResGray: any[] }> => {
  addLog("Extracting frames using seek method...");
  const cv = await getOpenCV();
  const lowResGrayFrames: any[] = [];

  try {
    // Ensure video metadata is loaded before we do anything
    if (videoElement.readyState < HTMLMediaElement.HAVE_METADATA) {
      addLog("Waiting for video metadata...");
      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => {
          reject(new Error("Video metadata load timeout"));
        }, 30000); // 30 second timeout

        videoElement.addEventListener(
          "loadedmetadata",
          () => {
            clearTimeout(timeout);
            resolve();
          },
          { once: true },
        );
        videoElement.addEventListener(
          "error",
          () => {
            clearTimeout(timeout);
            reject(new Error("Failed to load video metadata"));
          },
          { once: true },
        );
        // Trigger load if needed
        videoElement.load();
      });
      addLog("Metadata loaded.");
    } else {
      addLog(
        `Video already has metadata: ${videoElement.videoWidth}x${videoElement.videoHeight}`,
      );
    }

    // Create the off-screen canvas
    const canvas = document.createElement("canvas");
    const context = canvas.getContext("2d", { willReadFrequently: true });
    if (!context) {
      throw new Error("Could not get 2D context");
    }

    // Set canvas dimensions *after* metadata is loaded
    canvas.width = videoElement.videoWidth;
    canvas.height = videoElement.videoHeight;

    // We must mute and pause the video, as we are controlling it manually
    videoElement.muted = true;
    videoElement.pause();

    const frameInterval = 1 / FRAME_RATE; // Time in seconds
    const targetFrameCount = Math.min(
      Math.floor(videoElement.duration * FRAME_RATE),
      MAX_EXTRACT_FRAMES,
    );
    addLog(`Targeting ${targetFrameCount} frames...`);

    for (let i = 0; i < targetFrameCount; i++) {
      const currentTime = i * frameInterval;

      // Seek to the target time and wait for the frame to be ready
      await seekTo(videoElement, currentTime);

      // Now that the 'seeked' event has fired, the frame is ready.
      // Draw it to the canvas.
      context.drawImage(videoElement, 0, 0, canvas.width, canvas.height);
      const imageData = context.getImageData(0, 0, canvas.width, canvas.height);

      // Do not retain full-res ImageData for every frame — only low-res Mats are kept
      // until keyframes are chosen; full-res keyframes are extracted in a second pass.

      // --- OpenCV processing ---
      // Convert to Mat ONLY for processing, then delete immediately
      const fullResFrame = cv.matFromImageData(imageData);

      // Create low-resolution grayscale image
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

      // CLEANUP: Delete the full resolution Mat immediately to free WASM memory
      fullResFrame.delete();
      lowResFrame.delete();
      // --- End of OpenCV processing ---

      // Update progress
      const progress = ((i + 1) / targetFrameCount) * 100;
      updateProgress(Math.min(progress, 100));
    }

    addLog(`Successfully extracted ${lowResGrayFrames.length} low-res frames.`);
    return { lowResGray: lowResGrayFrames };
  } catch (error: any) {
    const errorMessage = getErrorMessage(error, cv);
    addLog(`Frame extraction failed: ${errorMessage}`);
    console.error("Frame extraction error:", error);
    // Return empty arrays to prevent downstream errors
    throw new Error(errorMessage);
  }
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
      const mm = (cv.minMaxLoc as any)(res);
      const maxVal = mm.maxVal;
      const maxLoc = mm.maxLoc;

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
  videoElement: HTMLVideoElement,
  keyframeIndices: number[],
  refinedWindow: any,
  addLog: (message: string) => void,
  updateProgress: (progress: number) => void,
): Promise<any> => {
  addLog("Extracting full-resolution keyframes only...");
  const cv = await getOpenCV();
  const orderedKeyframeIndices = [...new Set(keyframeIndices)].sort(
    (a, b) => a - b,
  );

  if (orderedKeyframeIndices.length === 0) {
    addLog("Error: No keyframes to stitch");
    return null;
  }

  const vw = videoElement.videoWidth;
  const vh = videoElement.videoHeight;
  const decodeScale = getFullResDecodeScale(vw, vh, isLikelyIOS);

  const canvas = document.createElement("canvas");
  const context = canvas.getContext("2d", { willReadFrequently: true });
  if (!context) {
    throw new Error("Could not get 2D context for keyframe extraction");
  }
  canvas.width = Math.max(1, Math.floor(vw * decodeScale));
  canvas.height = Math.max(1, Math.floor(vh * decodeScale));

  if (decodeScale < 1) {
    addLog(
      `Decoding keyframes at ${canvas.width}x${canvas.height} (scale ${decodeScale.toFixed(3)}) to reduce memory.`,
    );
  }

  const refinedWindowForStitch = clampRectToFrame(
    decodeScale === 1 ? refinedWindow : scaleRect(refinedWindow, decodeScale),
    canvas.width,
    canvas.height,
  );
  const { x, y, width, height } = refinedWindowForStitch;

  videoElement.muted = true;
  videoElement.pause();

  const frameInterval = 1 / FRAME_RATE;
  const totalPasses = 2;
  const updateDecodeProgress = (
    passIndex: number,
    itemIndex: number,
    total: number,
  ) => {
    const safeTotal = Math.max(1, total);
    const completed = passIndex + itemIndex / safeTotal;
    updateProgress(Math.min((completed / totalPasses) * 100, 100));
  };

  const decodeMatAtIndex = async (frameIndex: number) => {
    await seekTo(videoElement, frameIndex * frameInterval);
    context.drawImage(videoElement, 0, 0, canvas.width, canvas.height);
    return cv.matFromImageData(
      context.getImageData(0, 0, canvas.width, canvas.height),
    );
  };

  addLog(
    `Streaming ${orderedKeyframeIndices.length} full-res keyframe(s) to reduce memory.`,
  );
  addLog("Stitching keyframes...");

  let stitchedImage: any = null;
  try {
    const firstIndex = orderedKeyframeIndices[0];
    if (firstIndex === undefined) {
      addLog("Error: Invalid first keyframe index");
      return null;
    }

    let previousFrame = await decodeMatAtIndex(firstIndex);
    const frameWidth = previousFrame.cols;
    const frameHeight = previousFrame.rows;
    const frameType = previousFrame.type();
    const headerHeight = y;
    const footerHeight = Math.max(0, frameHeight - (y + height));

    const offsets: { v_offset: number; h_offset: number }[] = [];
    for (let i = 1; i < orderedKeyframeIndices.length; i++) {
      const frameIndex = orderedKeyframeIndices[i];
      if (frameIndex === undefined) {
        continue;
      }

      const currentFrame = await decodeMatAtIndex(frameIndex);

      const window1 = previousFrame.roi(new cv.Rect(x, y, width, height));
      const window2 = currentFrame.roi(new cv.Rect(x, y, width, height));

      const templateHeight = Math.floor(height / 3);
      const template = window1.roi(
        new cv.Rect(0, height - templateHeight, width, templateHeight),
      );

      const res = new cv.Mat();
      cv.matchTemplate(window2, template, res, cv.TM_CCOEFF_NORMED);
      const mm = (cv.minMaxLoc as any)(res);
      const maxLoc = mm.maxLoc;

      const vOffset = height - templateHeight - maxLoc.y;
      const hOffset = maxLoc.x;
      offsets.push({ v_offset: vOffset, h_offset: hOffset });

      window1.delete();
      window2.delete();
      template.delete();
      res.delete();

      previousFrame.delete();
      previousFrame = currentFrame;
      updateDecodeProgress(0, i, orderedKeyframeIndices.length - 1);
    }
    previousFrame.delete();

    let totalHeight = headerHeight + height + footerHeight;
    for (const offset of offsets) {
      totalHeight += Math.max(0, offset.v_offset);
    }

    stitchedImage = new cv.Mat(
      totalHeight,
      frameWidth,
      frameType,
      new cv.Scalar(0, 0, 0, 0),
    );

    const firstFrame = await decodeMatAtIndex(firstIndex);
    let currentY = 0;
    if (headerHeight > 0) {
      const header = firstFrame.roi(
        new cv.Rect(0, 0, frameWidth, headerHeight),
      );
      const headerRoi = new cv.Rect(0, 0, frameWidth, header.rows);
      header.copyTo(stitchedImage.roi(headerRoi));
      currentY += header.rows;
      header.delete();
    }

    const firstWindowRoi = new cv.Rect(0, y, frameWidth, height);
    const firstWindow = firstFrame.roi(firstWindowRoi);
    firstWindow.copyTo(
      stitchedImage.roi(new cv.Rect(0, currentY, frameWidth, height)),
    );
    firstWindow.delete();
    firstFrame.delete();
    currentY += height;
    updateDecodeProgress(1, 0, orderedKeyframeIndices.length);

    for (let i = 0; i < offsets.length; i++) {
      const offset = offsets[i];
      if (!offset) continue;
      const { v_offset, h_offset } = offset;
      const frameIndex = orderedKeyframeIndices[i + 1];
      if (frameIndex === undefined) {
        continue;
      }

      const keyframe = await decodeMatAtIndex(frameIndex);
      const scrollingWindow = keyframe.roi(new cv.Rect(x, y, width, height));
      const safeVOffset = Math.max(0, Math.min(v_offset, height));

      const newPart = scrollingWindow.roi(
        new cv.Rect(0, height - safeVOffset, width, safeVOffset),
      );

      if (newPart.rows > 0) {
        const newSlice = new cv.Mat(
          newPart.rows,
          width,
          frameType,
          new cv.Scalar(0, 0, 0, 0),
        );

        const sourceX = h_offset < 0 ? Math.min(-h_offset, newPart.cols) : 0;
        const targetX = Math.max(0, h_offset);
        const copyWidth = Math.min(
          newPart.cols - sourceX,
          Math.max(0, width - targetX),
        );

        if (copyWidth > 0) {
          const sourceRoi = newPart.roi(
            new cv.Rect(sourceX, 0, copyWidth, newPart.rows),
          );
          const newSliceRoi = new cv.Rect(targetX, 0, copyWidth, newPart.rows);
          sourceRoi.copyTo(newSlice.roi(newSliceRoi));
          sourceRoi.delete();
        }

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
      keyframe.delete();
      updateDecodeProgress(1, i + 1, orderedKeyframeIndices.length);
    }

    if (footerHeight > 0) {
      const lastIndex =
        orderedKeyframeIndices[orderedKeyframeIndices.length - 1];
      if (lastIndex !== undefined) {
        const lastFrame = await decodeMatAtIndex(lastIndex);
        const footer = lastFrame.roi(
          new cv.Rect(0, y + height, frameWidth, footerHeight),
        );
        const footerStitchedRoi = new cv.Rect(
          0,
          currentY,
          frameWidth,
          footer.rows,
        );
        footer.copyTo(stitchedImage.roi(footerStitchedRoi));
        currentY += footer.rows;
        footer.delete();
        lastFrame.delete();
      }
    }

    addLog(`Streamed ${orderedKeyframeIndices.length} full-res keyframe(s).`);
    return stitchedImage;
  } catch (error) {
    if (stitchedImage) {
      stitchedImage.delete();
    }
    throw error;
  }
};

export const processVideo = async (
  videoElement: HTMLVideoElement,
  addLog: (message: string) => void,
  outputCanvas: HTMLCanvasElement,
  updateProgress: (progress: number) => void,
) => {
  addLog("Processing video with OpenCV.js");
  updateProgress(5);

  let lowResGray: any[] = [];
  let outsideMask: any = null;
  let stitchedImage: any = null;

  try {
    const cv = await getOpenCV();
    addLog(
      `OpenCV.js runtime ready${isLikelyIOS ? " (iOS memory mode)" : ""}.`,
    );
    updateProgress(10);

    updateProgress(10);
    const frameResult = await extractFrames(videoElement, addLog, (p) =>
      updateProgress(10 + p * 0.2),
    ); // 10-30%
    lowResGray = frameResult.lowResGray;

    if (lowResGray.length < 2) {
      addLog("Not enough frames to process.");
      lowResGray.forEach((frame: any) => frame.delete());
      return;
    }
    updateProgress(30);

    const windowInfo = await findRefinedScrollingWindow(lowResGray, addLog);
    if (!windowInfo) {
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
    updateProgress(80);

    if (cleanKeyframeIndices.length === 0) {
      addLog("No keyframes after filtering.");
      lowResGray.forEach((frame: any) => frame.delete());
      return;
    }

    stitchedImage = await stitchKeyframes(
      videoElement,
      cleanKeyframeIndices,
      refinedWindow,
      addLog,
      (p) => updateProgress(80 + p * 0.15),
    );
    updateProgress(95);

    if (stitchedImage) {
      cv.imshow(outputCanvas, stitchedImage);
    }

    updateProgress(100);
  } catch (error) {
    const cv = await getOpenCV().catch(() => null);
    const errorMessage = getErrorMessage(error, cv);
    addLog(`Error processing video: ${errorMessage}`);
    console.error("Video processing error:", error);
  } finally {
    // Ensure all resources are cleaned up
    try {
      if (outsideMask) {
        outsideMask.delete();
      }
      if (stitchedImage) {
        stitchedImage.delete();
      }

      lowResGray.forEach((frame: any) => {
        if (frame) {
          try {
            frame.delete();
          } catch {
            // Ignore deletion errors
          }
        }
      });
    } catch (cleanupError) {
      console.error("Error during cleanup:", cleanupError);
    }
  }
};
