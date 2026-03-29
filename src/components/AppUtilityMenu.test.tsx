import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";
import { AppUtilityMenu } from "./AppUtilityMenu";

vi.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}));

describe("AppUtilityMenu", () => {
  it("renders the compact utility button and sheet content when open", () => {
    const markup = renderToStaticMarkup(
      <AppUtilityMenu
        currentStep="upload"
        videoMetadata={{}}
        lastProcessingError={null}
        processingLogs={[]}
        open
        onOpenChange={() => undefined}
      />,
    );

    expect(markup).toContain("app.menu.open");
    expect(markup).toContain("app.menu.title");
    expect(markup).toContain("feedback.trigger");
  });
});
