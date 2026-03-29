import { renderToStaticMarkup } from "react-dom/server";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { PreviewView } from "./PreviewView";

const supportsImageSharingMock = vi.fn();

vi.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}));

vi.mock("../lib/native-media", () => ({
  supportsImageSharing: () => supportsImageSharingMock(),
  shareGeneratedImage: vi.fn(),
}));

describe("PreviewView", () => {
  beforeEach(() => {
    supportsImageSharingMock.mockReset();
  });

  it("renders the redesigned preview stage and sticky action tray", () => {
    supportsImageSharingMock.mockReturnValue(true);

    const markup = renderToStaticMarkup(
      <PreviewView
        imageUrl="data:image/png;base64,ZmFrZQ=="
        onDownload={() => undefined}
        onReset={() => undefined}
        isNativeSave
      />,
    );

    expect(markup).toContain('data-testid="preview-stage-card"');
    expect(markup).toContain('data-testid="preview-action-bar"');
    expect(markup).toContain("preview.complete.badge");
    expect(markup).toContain("preview.result.badge");
    expect(markup).toContain("preview.actions.save");
    expect(markup).toContain("preview.actions.share");
  });

  it("hides the share button when image sharing is unavailable", () => {
    supportsImageSharingMock.mockReturnValue(false);

    const markup = renderToStaticMarkup(
      <PreviewView
        imageUrl="data:image/png;base64,ZmFrZQ=="
        onDownload={() => undefined}
        onReset={() => undefined}
      />,
    );

    expect(markup).toContain("preview.actions.download");
    expect(markup).not.toContain("preview.actions.share");
  });
});
