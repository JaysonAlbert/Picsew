import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";
import { ProcessingView } from "./ProcessingView";

vi.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}));

describe("ProcessingView", () => {
  it("renders the simplified processing stage", () => {
    const markup = renderToStaticMarkup(<ProcessingView progress={64} />);

    expect(markup).toContain('data-testid="processing-stage-card"');
    expect(markup).toContain("app.flow.step2");
    expect(markup).toContain("processing.title");
    expect(markup).toContain("processing.keepOpen");
  });
});
