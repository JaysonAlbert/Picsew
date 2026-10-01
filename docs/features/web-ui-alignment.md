# Web UI alignment with native iOS

Date: 2026-10-01

## Problem and scope

The deployed Web app still uses blue gradients, repeated headings, nested cards,
and a small unlabeled clear button. The user requests that Web adopt the latest
native iOS design, then merge and deploy it for verification on their iPhone.
Native reference: [PR #37](https://github.com/JaysonAlbert/Picsew/pull/37).
The [product UI guidelines](../product-ui-guidelines.md) define the shared contract.

Scope: Web shell, import, processing, preview, onboarding, and shared feedback
styling. Preserve the TypeScript processing algorithm, local media handling,
analytics, feedback submission, native picker/export adapters, and release metadata.
This delivery does not merge the native PR or promise to resolve unknown codec,
memory, or device-specific compatibility issues.

## Design

- Neutral adaptive light/dark surfaces, system typography, teal `#087A70` accent,
  one compact brand row, one route heading, one main stage and one action area.
- Import: a keyboard-accessible browser video chooser, selected filename and
  clear action, one privacy caption. Create is visible but disabled without a
  selection or while resources load. Keep the selected video preview behind a
  disclosure so users can inspect it without competing with the main action.
  Capacitor continues to offer its Photos and Files pickers.
- Processing: one accessible progress ring with percentage and a plain-language
  stage, plus one keep-open instruction. Remove the duplicate bar and spinner.
- Preview: one width-fitted, vertically scrollable image viewport, optional
  dimensions behind initially collapsed details. Save image is primary, Share
  appears only when supported, and New capture is secondary. Browser save uses
  its existing download behavior; native photo save retains its explicit label.
- Onboarding: one short promise, three plain steps and Continue. Preserve Skip
  as a secondary dismissal. Use a scrollable dialog at small heights/large text.
- Controls are at least 44 CSS px, primary actions at least 52 px. Text wraps;
  page content and disclosures remain reachable above safe-area-aware actions.
  Keep the action area in normal flow, pushed to the bottom on narrow mobile layouts when there is room;
  a sticky footer obscured content at large text sizes during visual validation.
  Use a centered constrained column on desktop with the same reading order.
  At widths of 640 CSS px and above, let content determine the column height
  and keep actions directly below it; only narrow mobile layouts push actions
  down when there is spare height. See [desktop spacing fix](web-desktop-layout.md).

## Acceptance and planned tests

1. Real browser interactions prove empty Create disabled, select/clear behavior,
   upload → processing → preview, collapsed/expanded details, download and reset.
2. Run Chromium and mobile WebKit tests, including 320 px width, small height,
   200% text, dark mode and Chinese. Assert no horizontal overflow and reachable
   controls. Preserve onboarding-once and feedback navigation checks.
3. UI journey tests replace only the OpenCV/processing module boundary with a
   deterministic tall image. These tests do not claim codec/algorithm coverage.
   Separately run the existing real short-video test when its fixture is available.
4. Capture fresh mobile journey, onboarding, dark, large text and desktop images;
   explicitly inspect them against the native reference before delivery.
5. Run lint, typecheck, unit tests, browser tests and production build. Extend the
   existing deployment workflow to validate PRs and install both browser engines.
   SSH/SCP deployment steps run only on main/master pushes, never on PR events.
6. Commit on a focused branch, open and merge its PR after validation, then wait
   for the existing main deployment and verify the live UI and new build assets.

## Validation and deployment

- Lint has no errors (eight pre-existing warnings in optional video tests).
  Typecheck, all 28 unit tests and the production build passed. The existing
  OpenCV bundle-size warning remains.
- Browser regression suite: 18 passed across Chromium and mobile WebKit.
  The new journey test failed on the baseline at the missing disabled Create
  action, then passed with select/clear, accessible progress, result disclosure,
  download and reset. Large-text and dark-mode journeys passed on both engines.
- Real processing: `PICSEW_VIDEO_E2E=1 npx playwright test e2e/picsew.spec.ts
--grep 'test-video.mp4: upload'` passed in codec-capable Chrome, using the
  existing 2.36 MB video. The in-app browser independently processed this video
  and reached preview. Other optional long-video statistics scenarios were not run.
- Current-change [screenshots](../screenshots/web-ui-alignment/) cover the three
  routes on mobile and desktop, expanded details, Chinese dark import, dark
  processing/preview and 320 px layouts at 200% text. Visual self-review against
  native PR #37 and the shared contract accepted the final hierarchy, colors,
  width-fitted image and readable actions after removing the footer overlap.
  The enlarged onboarding capture shows its dismissal controls after scrolling.
- These browser-engine checks do not replace verification on a physical iPhone,
  especially browser codec support, long-video memory use, sharing destinations
  and the operating system's file/download UI. The user will verify the deployed
  version on their phone.

| Import                                                 | Processing                                                 | Preview                                               | Details                                                         |
| ------------------------------------------------------ | ---------------------------------------------------------- | ----------------------------------------------------- | --------------------------------------------------------------- |
| [Selected](../screenshots/web-ui-alignment/upload.png) | [Progress](../screenshots/web-ui-alignment/processing.png) | [Result](../screenshots/web-ui-alignment/preview.png) | [Expanded](../screenshots/web-ui-alignment/preview-details.png) |

Deployment uses the existing main push workflow. Its final run and live UI are
verified after the PR merge; the PR and Actions records own that delivery state.
