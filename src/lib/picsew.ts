import { getOpenCV } from './opencv';

const FRAME_RATE = 10; // frames per second

const extractFrames = async (
  videoElement: HTMLVideoElement,
  addLog: (message: string) => void,
  updateProgress: (progress: number) => void
): Promise<any[]> => {
  addLog("Extracting frames...");
  const cv = await getOpenCV() ;
  const canvas = document.createElement("canvas");
  const context = canvas.getContext("2d");
  const frames: any[] = [];

  canvas.width = videoElement.videoWidth;
  canvas.height = videoElement.videoHeight;

  let currentTime = 0;
  videoElement.currentTime = 0;

  return new Promise((resolve) => {
    const onSeeked = async () => {
      if (context) {
        context.drawImage(videoElement, 0, 0, canvas.width, canvas.height);
        const imageData = context.getImageData(0, 0, canvas.width, canvas.height);
        frames.push(cv.matFromImageData(imageData));
      }

      currentTime += 1 / FRAME_RATE;
      if (currentTime < videoElement.duration) {
        videoElement.currentTime = currentTime;
        const progress = (currentTime / videoElement.duration) * 100;
        updateProgress(progress);
      } else {
        videoElement.removeEventListener("seeked", onSeeked);
        addLog(`Extracted ${frames.length} frames.`);
        resolve(frames);
      }
    };

    videoElement.addEventListener("seeked", onSeeked);
    videoElement.currentTime = currentTime;
  });
};

const findRefinedScrollingWindow = async (frames: any[], addLog: (message: string) => void) => {
  addLog("Finding refined scrolling window...");
  const cv =await getOpenCV();
  const motionAccumulator = cv.Mat.zeros(frames[0].rows, frames[0].cols, cv.CV_32F);

  for (let i = 0; i < frames.length - 1; i++) {
    const gray1 = new cv.Mat();
    cv.cvtColor(frames[i], gray1, cv.COLOR_RGBA2GRAY);
    const gray2 = new cv.Mat();
    cv.cvtColor(frames[i + 1], gray2, cv.COLOR_RGBA2GRAY);

    const diff = new cv.Mat();
    cv.absdiff(gray1, gray2, diff);

    const thresh = new cv.Mat();
    cv.threshold(diff, thresh, 30, 255, cv.THRESH_BINARY);

    const thresh32F = new cv.Mat();
    thresh.convertTo(thresh32F, cv.CV_32F);

    cv.add(motionAccumulator, thresh32F, motionAccumulator);

    gray1.delete();
    gray2.delete();
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
  cv.findContours(motionMask, contours, hierarchy, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
  hierarchy.delete();

  if (contours.size() === 0) {
    addLog("No consistent motion detected.");
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
  const frameWidth = frames[0].cols;

  const originalFullWidthWindow = { x: 0, y: boundingRect.y, width: frameWidth, height: boundingRect.height };

  const outsideMask = cv.Mat.ones(frames[0].rows, frames[0].cols, cv.CV_8U);
  outsideMask.setTo(new cv.Scalar(255));
  const roi = new cv.Rect(0, boundingRect.y, frameWidth, boundingRect.height);
  const outsideMaskRoi = outsideMask.roi(roi);
  outsideMaskRoi.setTo(new cv.Scalar(0));
  outsideMaskRoi.delete();

  const insetPixels = Math.floor(boundingRect.height * 0.1);
  const refinedWindow = {
    x: 0,
    y: boundingRect.y + insetPixels,
    width: frameWidth,
    height: boundingRect.height - insetPixels * 2,
  };

  addLog(`Detected refined window: { x: ${refinedWindow.x}, y: ${refinedWindow.y}, width: ${refinedWindow.width}, height: ${refinedWindow.height} }`);

  contours.delete();

  return { refinedWindow, originalFullWidthWindow, outsideMask };
};

const selectKeyframes =async (frames: any[], refinedWindow: any, addLog: (message: string) => void): Promise<any[]> => {
  addLog("Selecting keyframes...");
  const cv =await getOpenCV();
  const { x, y, width, height } = refinedWindow;

  const candidateKeyframes: any[] = [frames[0]];
  let lastKeyframeIndex = 0;

  while (lastKeyframeIndex < frames.length - 1) {
    let accumulatedOffset = 0;
    let lastFrameInChunk = frames[lastKeyframeIndex];

    let foundNextKeyframe = false;
    for (let i = lastKeyframeIndex + 1; i < frames.length; i++) {
      const currentFrame = frames[i];

      const templateHeight = Math.floor(height / 4);
      const templateYStart = y + Math.floor(height / 2) - Math.floor(templateHeight / 2);
      const template = lastFrameInChunk.roi(new cv.Rect(x, templateYStart, width, templateHeight));
      
      const scrollingWindowContent = currentFrame.roi(new cv.Rect(x, y, width, height));
      const res = new cv.Mat();
      cv.matchTemplate(scrollingWindowContent, template, res, cv.TM_CCOEFF_NORMED);
      const minMaxLoc = cv.minMaxLoc(res, new cv.Mat());
      const maxVal = minMaxLoc.maxVal;
      const maxLoc = minMaxLoc.maxLoc;

      template.delete();
      scrollingWindowContent.delete();
      res.delete();

      if (maxVal > 0.7) {
        const offsetSinceLastFrame = (templateYStart - y) - maxLoc.y;
        if (offsetSinceLastFrame > 0) {
          accumulatedOffset += offsetSinceLastFrame;
        }
      }

      lastFrameInChunk = currentFrame;

      if (accumulatedOffset > height * 0.5) {
        candidateKeyframes.push(currentFrame);
        lastKeyframeIndex = i;
        foundNextKeyframe = true;
        break;
      }
    }
    
    if (!foundNextKeyframe) {
      break;
    }
  }

  if (lastKeyframeIndex !== frames.length - 1) {
    candidateKeyframes.push(frames[frames.length - 1]);
  }

  addLog(`Selected ${candidateKeyframes.length} candidate keyframes.`);
  return candidateKeyframes;
};

const filterKeyframes =async (candidateKeyframes: any[], originalFullWidthWindow: any, outsideMask: any, addLog: (message: string) => void): Promise<any[]> => {
  addLog("Filtering keyframes...");
  const cv =await getOpenCV();

  const cleanKeyframes: any[] = [candidateKeyframes[0]];

  for (let i = 1; i < candidateKeyframes.length; i++) {
    const gray1 = new cv.Mat();
    cv.cvtColor(candidateKeyframes[i - 1], gray1, cv.COLOR_RGBA2GRAY);
    const gray2 = new cv.Mat();
    cv.cvtColor(candidateKeyframes[i], gray2, cv.COLOR_RGBA2GRAY);

    const diff = new cv.Mat();
    cv.absdiff(gray1, gray2, diff);

    const thresh = new cv.Mat();
    cv.threshold(diff, thresh, 30, 255, cv.THRESH_BINARY);

    const changesOutside = new cv.Mat();

    addLog(`thresh type: ${thresh.type()}, size: ${thresh.size().width}x${thresh.size().height}`);
    addLog(`outsideMask type: ${outsideMask.type()}, size: ${outsideMask.size().width}x${outsideMask.size().height}`);

    try {
      cv.bitwise_and(thresh, thresh, changesOutside, outsideMask);
    }
    catch (e: any) {
      addLog(`Error in cv.bitwise_and: ${e.message}`);
      throw e; // Re-throw to stop execution
    }

    const totalOutsidePixels = cv.countNonZero(outsideMask);
    const changedOutsidePixels = cv.countNonZero(changesOutside);
    const changePercentage = (changedOutsidePixels / totalOutsidePixels) * 100;

    gray1.delete();
    gray2.delete();
    diff.delete();
    thresh.delete();
    changesOutside.delete();

    if (changePercentage < 1) {
      cleanKeyframes.push(candidateKeyframes[i]);
    }
  }

  addLog(`Selected ${cleanKeyframes.length} final keyframes after filtering.`);
  return cleanKeyframes;
};

const stitchKeyframes =async (keyframes: any[], refinedWindow: any, addLog: (message: string) => void): Promise<any> => {
  addLog("Stitching keyframes...");
  const cv =await getOpenCV();
  const { x, y, width, height } = refinedWindow;
  const frameWidth = keyframes[0].cols;

  if (keyframes.length === 0) {
    return null;
  }

  // 1. Calculate Offsets
  const offsets: { v_offset: number; h_offset: number }[] = [];
  for (let i = 0; i < keyframes.length - 1; i++) {
    const frame1 = keyframes[i];
    const frame2 = keyframes[i + 1];

    const window1 = frame1.roi(new cv.Rect(x, y, width, height));
    const window2 = frame2.roi(new cv.Rect(x, y, width, height));

    const templateHeight = Math.floor(height / 3);
    const template = window1.roi(new cv.Rect(0, height - templateHeight, width, templateHeight));

    const res = new cv.Mat();
    cv.matchTemplate(window2, template, res, cv.TM_CCOEFF_NORMED);
    const minMaxLoc = cv.minMaxLoc(res, new cv.Mat());
    const maxLoc = minMaxLoc.maxLoc;

    const vOffset = (height - templateHeight) - maxLoc.y;
    const hOffset = maxLoc.x;
    offsets.push({ v_offset: vOffset, h_offset: hOffset });

    window1.delete();
    window2.delete();
    template.delete();
    res.delete();
  }

  // 2. Stitch the Images
  const header = keyframes[0].roi(new cv.Rect(0, 0, frameWidth, y));
  const footer = keyframes[keyframes.length - 1].roi(new cv.Rect(0, y + height, frameWidth, keyframes[0].rows - (y + height)));

  let totalHeight = header.rows + height + footer.rows;
  for (const offset of offsets) {
    totalHeight += offset.v_offset;
  }

  const stitchedImage = new cv.Mat(totalHeight, frameWidth, keyframes[0].type(), new cv.Scalar(0, 0, 0, 0));

  let currentY = 0;
  const headerRoi = new cv.Rect(0, 0, frameWidth, header.rows);
  header.copyTo(stitchedImage.roi(headerRoi));
  currentY += header.rows;

  const firstWindowRoi = new cv.Rect(0, y, frameWidth, height);
  keyframes[0].roi(firstWindowRoi).copyTo(stitchedImage.roi(new cv.Rect(0, currentY, frameWidth, height)));
  currentY += height;

  for (let i = 0; i < offsets.length; i++) {
    const offset = offsets[i];
    if (!offset) continue;
    const { v_offset, h_offset } = offset;
    const keyframe = keyframes[i + 1];
    const scrollingWindow = keyframe.roi(new cv.Rect(x, y, width, height));

    const newPart = scrollingWindow.roi(new cv.Rect(0, height - v_offset, width, v_offset));

    if (newPart.rows > 0) {
      const newSlice = new cv.Mat(newPart.rows, width, keyframes[0].type(), new cv.Scalar(0, 0, 0, 0));
      const newSliceRoi = new cv.Rect(h_offset, 0, newPart.cols, newPart.rows);
      newPart.copyTo(newSlice.roi(newSliceRoi));

      const stitchedImageSliceRoi = new cv.Rect(0, currentY, width, newPart.rows);
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

  return stitchedImage.roi(new cv.Rect(0, 0, frameWidth, currentY));
};

export const processVideo = async (
  videoElement: HTMLVideoElement,
  addLog: (message: string) => void,
  outputCanvas: HTMLCanvasElement,
  updateProgress: (progress: number) => void
) => {
  addLog("Processing video with OpenCV.js");
  updateProgress(5);
  
  try {
    const cv =await getOpenCV();
    addLog(`OpenCV.js version: ${cv.CV_8U}`);
  updateProgress(10);

    updateProgress(10);
    const frames = await extractFrames(videoElement, addLog, (p) =>
      updateProgress(10 + p * 0.2)
    ); // 10-30%
    if (frames.length < 2) {
      addLog("Not enough frames to process.");
      return;
    }
    updateProgress(30);

    const windowInfo =await findRefinedScrollingWindow(frames, addLog);
    if (!windowInfo) {
      return;
    }
    updateProgress(50);

    const { refinedWindow, originalFullWidthWindow, outsideMask } = windowInfo;

    const candidateKeyframes = await selectKeyframes(frames, refinedWindow, addLog);
    updateProgress(70);

    const cleanKeyframes = await filterKeyframes(
      candidateKeyframes,
      originalFullWidthWindow,
      outsideMask,
      addLog
    );
    updateProgress(85);

    const stitchedImage = await stitchKeyframes(cleanKeyframes, refinedWindow, addLog);
    updateProgress(95);

    if (stitchedImage) {
      cv.imshow(outputCanvas, stitchedImage);
      stitchedImage.delete();
    }

    outsideMask.delete();
    frames.forEach((frame: any) => frame.delete());
    updateProgress(100);
  } catch (error) {
    addLog(`OpenCV.js 处理错误: ${error}`);
    console.error('OpenCV.js error:', error);
  }
};