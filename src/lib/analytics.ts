import { version } from "../../package.json";
import {
  ANALYTICS_EVENTS,
  sanitizeAnalyticsParams,
  type AnalyticsEventName,
  type AnalyticsEventParams,
} from "./analytics-events";

const PRODUCTION_ID = "G-BBQ1PPGCCE";
const PRODUCTION_ORIGIN = "https://picsew.ibotcloud.top";
const commonParams = {
  platform: "web",
  app_version: version,
  analytics_schema: "2",
};

declare global {
  interface Window {
    dataLayer: unknown[];
    gtag: (...args: unknown[]) => void;
    __picsewAnalytics?: { initialized: boolean; lastPage: string };
  }
}

export const getAnalyticsConfig = (
  production: boolean,
  origin: string,
  testId?: string,
) => {
  if (production && origin === PRODUCTION_ORIGIN)
    return { id: PRODUCTION_ID, debug: false };
  if (
    !production &&
    /^G-[A-Z0-9]+$/.test(testId ?? "") &&
    testId !== PRODUCTION_ID
  )
    return { id: testId!, debug: true };
  return null;
};

const config = () =>
  getAnalyticsConfig(
    import.meta.env.PROD,
    window.location.origin,
    import.meta.env.VITE_GA_TEST_MEASUREMENT_ID,
  );
const safeReferrer = () => {
  try {
    return new URL(document.referrer).origin;
  } catch {
    return "";
  }
};
// Keep initialization stable across duplicate module evaluation/HMR in the same page.
// This state is never persisted across page loads or sessions.
const state = () =>
  (window.__picsewAnalytics ??= { initialized: false, lastPage: "" });
const pageContext = (path = state().lastPage || "/upload") => ({
  page_location: `${window.location.origin}${path}`,
  page_referrer: safeReferrer(),
  page_title: "Picsew",
});
const send = (...args: unknown[]) => {
  // Analytics must never fail the local media journey. Do not report transport errors.
  try {
    window.gtag?.(...args);
  } catch {
    /* best effort */
  }
};

export const initGA = () => {
  const settings = config();
  if (!settings || state().initialized) return;
  state().initialized = true;
  window.dataLayer = window.dataLayer || [];
  // Preserve an existing tag/consent queue. Never emit a consent grant here.
  window.gtag =
    window.gtag ||
    function () {
      // Match the existing gtag.js command queue protocol.
      // eslint-disable-next-line prefer-rest-params
      window.dataLayer.push(arguments);
    };
  send("js", new Date());
  send("config", settings.id, {
    transport_url: `${PRODUCTION_ORIGIN}/ga`,
    send_page_view: false,
    allow_google_signals: false,
    allow_ad_personalization_signals: false,
    ...pageContext(),
    ...(settings.debug ? { debug_mode: true } : {}),
  });
  const script = document.createElement("script");
  script.src = `${PRODUCTION_ORIGIN}/ga/js?id=${settings.id}`;
  script.async = true;
  script.referrerPolicy = "origin";
  document.head.appendChild(script);
};

export const logPageView = (path: string) => {
  if (
    !state().initialized ||
    !config() ||
    !["/upload", "/processing", "/preview", "/feedback"].includes(path) ||
    path === state().lastPage
  )
    return;
  state().lastPage = path;
  // Set persistent context too, so automatic engagement events do not use raw URL parameters.
  send("set", pageContext(path));
  send("event", "page_view", {
    ...commonParams,
    ...pageContext(path),
    page_path: path,
  });
};

export const trackEvent = (
  eventName: AnalyticsEventName,
  params: AnalyticsEventParams = {},
) => {
  if (
    !state().initialized ||
    !config() ||
    !Object.values(ANALYTICS_EVENTS).includes(eventName)
  )
    return;
  send("event", eventName, {
    ...sanitizeAnalyticsParams(params),
    ...pageContext(),
    ...commonParams,
  });
};
