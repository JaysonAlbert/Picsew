import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";
import { VideoUpload } from "./VideoUpload";

vi.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}));

describe("VideoUpload", () => {
  it("renders the simplified upload stage and local processing note", () => {
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
    expect(markup).toContain("app.flow.step1");
    expect(markup).toContain("upload.heroTitle");
    expect(markup).toContain("upload.heroDescription");
    expect(markup).toContain("upload.native.fromPhotos");
    expect(markup).toContain("upload.native.fromFiles");
    expect(markup).toContain("upload.localProcessingHint");
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
