import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";
import { OnboardingDialog } from "./OnboardingDialog";

vi.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}));

describe("OnboardingDialog", () => {
  it("renders the first-launch onboarding content", () => {
    const markup = renderToStaticMarkup(
      <OnboardingDialog
        open
        onSkip={() => undefined}
        onStart={() => undefined}
      />,
    );

    expect(markup).toContain('data-testid="app-onboarding"');
    expect(markup).toContain("app.onboarding.title");
    expect(markup).toContain("app.onboarding.steps.import.title");
    expect(markup).toContain("app.onboarding.steps.stitch.title");
    expect(markup).toContain("app.onboarding.steps.save.title");
  });
});
