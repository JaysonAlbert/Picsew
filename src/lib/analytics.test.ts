import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const append = vi.fn();
let gtag: ReturnType<typeof vi.fn>;
const load = () => import("./analytics");
beforeEach(() => {
  vi.resetModules();
  vi.stubEnv("PROD", false);
  vi.stubEnv("VITE_GA_TEST_MEASUREMENT_ID", "G-LOCALTEST");
  gtag = vi.fn();
  append.mockReset();
  vi.stubGlobal("window", {
    location: { origin: "http://localhost:3001" },
    dataLayer: [["consent", "default", { analytics_storage: "denied" }]],
    gtag,
  });
  vi.stubGlobal("document", {
    referrer: "https://example.com/private?email=alice@example.com#secret",
    head: { appendChild: append },
    createElement: () => ({}),
  });
});
afterEach(() => {
  vi.unstubAllEnvs();
  vi.unstubAllGlobals();
});

describe("gtag initialization and safe transport", () => {
  it("enables production only on its deployed origin and refuses production ID in development", async () => {
    const { getAnalyticsConfig } = await load();
    expect(getAnalyticsConfig(false, "http://localhost")).toBeNull();
    expect(
      getAnalyticsConfig(false, "http://localhost", "G-BBQ1PPGCCE"),
    ).toBeNull();
    expect(
      getAnalyticsConfig(true, "http://localhost", "G-LOCALTEST"),
    ).toBeNull();
    expect(getAnalyticsConfig(true, "https://picsew.ibotcloud.top")).toEqual({
      id: "G-BBQ1PPGCCE",
      debug: false,
    });
  });
  it("does not load or send events in development by default", async () => {
    vi.stubEnv("VITE_GA_TEST_MEASUREMENT_ID", "");
    const ga = await load();
    ga.initGA();
    ga.logPageView("/upload");
    ga.trackEvent("upload_started");
    expect(append).not.toHaveBeenCalled();
    expect(gtag).not.toHaveBeenCalled();
  });
  it("initializes once under StrictMode, disables automatic views and preserves consent/tag", async () => {
    const ga = await load();
    const original = window.gtag;
    ga.initGA();
    ga.initGA();
    expect(append).toHaveBeenCalledTimes(1);
    expect(append.mock.calls[0]?.[0]).toMatchObject({
      referrerPolicy: "origin",
    });
    expect(window.gtag).toBe(original);
    expect(window.dataLayer).toEqual([
      ["consent", "default", { analytics_storage: "denied" }],
    ]);
    expect(gtag).toHaveBeenCalledWith(
      "config",
      "G-LOCALTEST",
      expect.objectContaining({
        send_page_view: false,
        debug_mode: true,
        page_location: "http://localhost:3001/upload",
        page_referrer: "https://example.com",
      }),
    );
    expect(gtag.mock.calls.some((c) => c[0] === "consent")).toBe(false);
  });
  it("preserves initialization and view deduplication across module re-evaluation", async () => {
    const ga = await load();
    ga.initGA();
    ga.logPageView("/upload");
    vi.resetModules();
    const reloaded = await load();
    reloaded.initGA();
    reloaded.logPageView("/upload");
    expect(append).toHaveBeenCalledTimes(1);
    expect(
      gtag.mock.calls.filter((c) => c[0] === "event" && c[1] === "page_view"),
    ).toHaveLength(1);
  });
  it("deduplicates consecutive views but permits returning to a route; rejects raw paths", async () => {
    const ga = await load();
    ga.initGA();
    ga.logPageView("/upload");
    ga.logPageView("/upload");
    ga.logPageView("/feedback");
    ga.logPageView("/upload");
    ga.logPageView("/private?token=secret");
    expect(
      gtag.mock.calls.filter((c) => c[0] === "event" && c[1] === "page_view"),
    ).toHaveLength(3);
    expect(gtag).toHaveBeenLastCalledWith(
      "event",
      "page_view",
      expect.objectContaining({ platform: "web", analytics_schema: "2" }),
    );
    expect(JSON.stringify(gtag.mock.calls)).not.toContain("secret");
  });
  it("whitelists event names and parameters and pins version/platform/context", async () => {
    const ga = await load();
    ga.initGA();
    ga.trackEvent("task_error", {
      task_stage: "import",
      error_code: "metadata_unreadable",
      error_message: "secret",
      page_location: "secret",
      platform: "private",
    });
    expect(gtag).toHaveBeenLastCalledWith(
      "event",
      "task_error",
      expect.objectContaining({
        platform: "web",
        app_version: "0.1.0",
        analytics_schema: "2",
        error_code: "metadata_unreadable",
      }),
    );
    expect(JSON.stringify(gtag.mock.calls)).not.toContain("secret");
    // @ts-expect-error exercise runtime callers
    ga.trackEvent("private_event");
    expect(gtag).toHaveBeenLastCalledWith(
      "event",
      "task_error",
      expect.anything(),
    );
  });
  it("creates a compatible queue when no gtag exists, without throwing on transport errors", async () => {
    window.gtag = undefined as unknown as Window["gtag"];
    const ga = await load();
    ga.initGA();
    ga.trackEvent("upload_started");
    expect(Array.from(window.dataLayer.at(-1) as IArguments)).toEqual([
      "event",
      "upload_started",
      expect.anything(),
    ]);
    window.gtag = () => {
      throw new Error("blocked");
    };
    expect(() => ga.trackEvent("upload_started")).not.toThrow();
  });
});
