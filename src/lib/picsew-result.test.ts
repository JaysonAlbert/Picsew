import { afterEach, describe, expect, it, vi } from "vitest";
const { getCV } = vi.hoisted(() => ({ getCV: vi.fn() }));
vi.mock("./opencv", () => ({ getOpenCV: getCV }));
import { processVideo } from "./picsew";

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  getCV.mockReset();
});
describe("processing result contract", () => {
  it("reports an internally caught failure as failure, never normal completion", async () => {
    getCV.mockRejectedValue(new Error("private decoder details"));
    vi.spyOn(console, "error").mockImplementation(() => undefined);
    const result = await processVideo(
      {} as HTMLVideoElement,
      vi.fn(),
      {} as HTMLCanvasElement,
      vi.fn(),
    );
    expect(result).toBe("processing_failed");
  });
  it("reports no frames as empty output, without claiming canvas success", async () => {
    const imshow = vi.fn();
    getCV.mockResolvedValue({ imshow });
    vi.stubGlobal("HTMLMediaElement", { HAVE_METADATA: 1 });
    vi.stubGlobal("document", {
      createElement: () => ({ getContext: () => ({}) }),
    });
    const video = {
      readyState: 1,
      duration: 0,
      videoWidth: 10,
      videoHeight: 10,
      pause: vi.fn(),
    } as unknown as HTMLVideoElement;
    const result = await processVideo(
      video,
      vi.fn(),
      {} as HTMLCanvasElement,
      vi.fn(),
    );
    expect(result).toBe("empty_output");
    expect(imshow).not.toHaveBeenCalled();
  });
});
