import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";
import { FeedbackPage } from "./FeedbackPage";

vi.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string) => key,
    i18n: {
      language: "en",
      resolvedLanguage: "en",
    },
  }),
}));

describe("FeedbackPage", () => {
  it("renders the dedicated feedback page shell", () => {
    const markup = renderToStaticMarkup(
      <FeedbackPage
        currentStep="upload"
        videoMetadata={{}}
        lastProcessingError={null}
        processingLogs={[]}
        onBack={() => undefined}
      />,
    );

    expect(markup).toContain('data-testid="feedback-page"');
    expect(markup).toContain("feedback.page.kicker");
    expect(markup).toContain("feedback.title");
    expect(markup).toContain("feedback.page.description");
  });
});
