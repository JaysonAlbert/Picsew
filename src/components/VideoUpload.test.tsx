import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";
import { VideoUpload } from "./VideoUpload";

vi.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}));

describe("VideoUpload", () => {
  it("renders the unified upload stage and guidance chips", () => {
    const markup = renderToStaticMarkup(
      <VideoUpload
        selectedVideo={null}
        videoPreviewUrl={null}
        onVideoSelect={() => undefined}
        onStartProcessing={() => undefined}
        isOpenCVReady
        supportsNativeImport
        isPickingNativeVideo={false}
        onPickFromPhotos={async () => undefined}
        onPickFromFiles={async () => undefined}
      />,
    );

    expect(markup).toContain('data-testid="upload-stage-card"');
    expect(markup).toContain('data-testid="upload-dropzone"');
    expect(markup).toContain("upload.native.fromPhotos");
    expect(markup).toContain("upload.native.fromFiles");
    expect(markup).toContain("upload.instructions.step1");
    expect(markup).toContain("upload.instructions.step2");
    expect(markup).toContain("upload.instructions.step3");
  });

  it("shows the action tray when a video is selected", () => {
    const file = new File(["demo"], "demo.mp4", { type: "video/mp4" });
    const markup = renderToStaticMarkup(
      <VideoUpload
        selectedVideo={file}
        videoPreviewUrl="blob:demo"
        onVideoSelect={() => undefined}
        onStartProcessing={() => undefined}
        isOpenCVReady
      />,
    );

    expect(markup).toContain('data-testid="upload-action-tray"');
    expect(markup).toContain("upload.startProcessing");
    expect(markup).toContain("demo.mp4");
  });
});
