import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";
import { ProcessingView } from "./ProcessingView";

vi.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}));

describe("ProcessingView", () => {
  it("renders the unified processing stage and milestones", () => {
    const markup = renderToStaticMarkup(<ProcessingView progress={64} />);

    expect(markup).toContain('data-testid="processing-stage-card"');
    expect(markup).toContain("processing.title");
    expect(markup).toContain("processing.steps.analysis");
    expect(markup).toContain("processing.steps.selection");
    expect(markup).toContain("processing.steps.generation");
  });
});
