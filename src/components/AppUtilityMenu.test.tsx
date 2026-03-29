import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";
import { AppUtilityMenu } from "./AppUtilityMenu";

vi.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string) => key,
    i18n: {
      language: "en",
      resolvedLanguage: "en",
      changeLanguage: () => undefined,
    },
  }),
}));

describe("AppUtilityMenu", () => {
  it("renders the compact utility button and sheet content when open", () => {
    const markup = renderToStaticMarkup(
      <AppUtilityMenu
        open
        onOpenChange={() => undefined}
        onOpenFeedbackPage={() => undefined}
      />,
    );

    expect(markup).toContain("app.menu.open");
    expect(markup).toContain("app.menu.title");
    expect(markup).toContain("feedback.trigger");
  });
});
