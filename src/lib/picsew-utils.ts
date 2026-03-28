/**
 * When decoding keyframes to ImageData, cap the long edge on iOS so each frame
 * uses less RAM. Analysis still uses native resolution via low-res Mats.
 */
export function getFullResDecodeScale(
  videoWidth: number,
  videoHeight: number,
  isLikelyIOS: boolean,
): number {
  const maxEdge = Math.max(videoWidth, videoHeight);
  if (maxEdge <= 1) return 1;
  // iOS WebKit tabs are much more memory-constrained than desktop browsers.
  const cap = isLikelyIOS ? 1536 : 8192;
  if (maxEdge <= cap) return 1;
  return cap / maxEdge;
}

export const scaleRect = (
  r: { x: number; y: number; width: number; height: number },
  scale: number,
) => ({
  x: Math.round(r.x * scale),
  y: Math.round(r.y * scale),
  width: Math.round(r.width * scale),
  height: Math.round(r.height * scale),
});

export function getErrorMessage(error: unknown, cv?: any): string {
  let errorMessage = "Unknown error";
  if (typeof error === "number" && cv) {
    try {
      const exception = cv.exceptionFromPtr(error);
      errorMessage = `OpenCV Exception: ${exception.msg}`;
    } catch {
      errorMessage = `OpenCV Exception Pointer: ${error}`;
    }
  } else if (error instanceof Error) {
    errorMessage = error.message;
  } else if ((error as any)?.message) {
    errorMessage = (error as any).message;
  } else if ((error as any)?.msg) {
    errorMessage = (error as any).msg;
  } else {
    errorMessage = String(error);
  }
  return errorMessage;
}
