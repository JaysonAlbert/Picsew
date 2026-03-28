import type {
  AnalyticsEventName,
  AnalyticsEventParams,
} from "./analytics-events";

const GA_MEASUREMENT_ID = "G-BBQ1PPGCCE";

declare global {
  interface Window {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    dataLayer: any[];
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    gtag: (...args: any[]) => void;
  }
}

export const initGA = () => {
  const script = document.createElement("script");
  // Use the proxy for the script
  script.src = `https://picsew.ibotcloud.top/ga/js?id=${GA_MEASUREMENT_ID}`;
  script.async = true;
  document.head.appendChild(script);

  window.dataLayer = window.dataLayer || [];
  window.gtag = function () {
    // eslint-disable-next-line prefer-rest-params
    window.dataLayer.push(arguments);
  };
  window.gtag("js", new Date());

  // Configure transport_url to point to the proxy
  // GA4 will append /g/collect to this base URL
  window.gtag("config", GA_MEASUREMENT_ID, {
    transport_url: "https://picsew.ibotcloud.top/ga",
  });
};

export const logPageView = (path: string) => {
  if (typeof window.gtag === "function") {
    window.gtag("event", "page_view", {
      page_path: path,
    });
  }
};

export const trackEvent = (
  eventName: AnalyticsEventName,
  params: AnalyticsEventParams = {},
) => {
  if (typeof window.gtag === "function") {
    window.gtag("event", eventName, {
      platform: "web",
      ...params,
    });
  }
};

export const logEvent = (category: string, action: string, label?: string) => {
  trackEvent(action as AnalyticsEventName, {
    event_category: category,
    event_label: label,
  });
};
