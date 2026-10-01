# Web desktop layout spacing fix

Date: 2026-10-01

## Problem and scope

The deployed Web layout expands both the main column and each route to fill the
viewport. An auto top margin then pushes the action area to the viewport bottom.
On desktop/tall windows this leaves an excessive empty block between the import
card/privacy caption and Create. The same shell affects processing and preview.

Scope: responsive Web spacing only. Preserve the shared iOS visual language,
media handling, processing algorithm, and native application.

## Design choice

At viewport widths of 640 CSS px and above, use a centered 40rem column and
size the main/route sections to their contents. Actions follow their preceding
content with the existing 16px gap and 12px action padding (28px total). Keep the
processing stage at its natural minimum height rather than stretching with the
window. Desktop headers get 24px top / 20px bottom spacing and a 2rem route title.
Desktop action groups align right: Create is 224px wide (bounded by available
space), export actions form a compact group up to 448px wide. Keep 52px minimum
button height and visible keyboard focus.
Narrow mobile layouts retain their normal-flow, bottom-aligned actions
and safe-area padding. Both variants allow document scrolling at enlarged text
sizes and small window heights; avoid absolute or fixed action placement.

This clarifies the desktop adaptation of [Web alignment](web-ui-alignment.md)
and the [shared product guidelines](../product-ui-guidelines.md).

## Visual references

The user requests official examples to guide the design.
[Archived references](../../reference/design/README.md) include Things on iPhone
and Mac, Craft desktop, and a CleanShot annotation detail. Adopt Things’ clear
reading hierarchy and compact actions, Craft’s content grouping, and CleanShot’s
image-first composition. Preserve the shared system font, teal accent, neutral
light/dark palette and single-stage structure. The generic ui-ux-pro-max search
was consulted for accessibility/layout checks; its unrelated ratings/chat
pattern, indigo palette and decorative font recommendation do not fit this utility.

## Acceptance criteria

- At 640/647/1280/1440 CSS px widths, empty and selected upload actions follow
  the privacy caption within 32px, independent of available window height.
- Desktop Create remains compact (160–280px at normal text), at least 44px
  tall, and within the content column. Export controls remain grouped and usable.
- Preview actions follow collapsed or expanded result details within 32px.
  Image scrolling, saving and starting again remain available.
- Processing uses a bounded content stage; desktop window height alone does not
  enlarge it. Review all three routes at desktop and mobile widths.
- At 390px width, upload keeps its bottom action placement. At enlarged text or
  short heights, actions remain reachable and no horizontal overflow appears.

## Planned verification

Add browser layout assertions derived from the spacing requirement through the
existing deterministic UI journey (mock only processing, not CSS/layout). Prove
that the desktop-spacing assertion fails against the existing stylesheet before
editing production CSS. Run Chromium/mobile WebKit UI tests, unit tests, lint,
typecheck and build. Capture fresh desktop/mobile upload, processing and preview
screenshots and inspect them explicitly. Remote CI and existing main deployment
must pass; verify the live desktop spacing after release.

## Local validation

- Spacing regression RED: at 647 × 871, the original caption-to-action gap was
  348.72px against the independently specified maximum of 32px.
- Compact-action RED: the spacing-only implementation still had a 504px Create
  button; the desktop width requirement (160–280px at normal text) failed.
- Final UI tests: 20 existing/new route checks plus two short-desktop/200%-text
  checks passed across Chromium and mobile WebKit. Four desktop widths
  (640/647/1280/1440px) cover empty/selected import, bounded processing, preview,
  expanded details and reset; narrow mobile preserves its bottom actions.
- The existing browser/feedback and real synthetic processing regression checks
  passed separately (16 tests). These preserve upload/preview interactions and
  the floating-control fix; the seven original long recordings were not rerun
  for this CSS-only delivery (they were verified in the preceding algorithm PR).
- All 38 unit tests passed. Lint/typecheck and production build passed; the
  existing 10 lint warnings and OpenCV chunk-size warning remain.
- Fresh desktop import/processing/preview and mobile route screenshots were
  explicitly inspected against the reference library and shared visual contract.
  Content, hierarchy, right-aligned desktop controls and mobile action placement
  match the documented design; desktop short-window large-text controls remain
  reachable through normal scrolling.

| Desktop import                                                     | Desktop processing                                                     | Desktop preview                                                     | Mobile import                                                     |
| ------------------------------------------------------------------ | ---------------------------------------------------------------------- | ------------------------------------------------------------------- | ----------------------------------------------------------------- |
| [Screenshot](../screenshots/web-desktop-layout/desktop-upload.png) | [Screenshot](../screenshots/web-desktop-layout/desktop-processing.png) | [Screenshot](../screenshots/web-desktop-layout/desktop-preview.png) | [Screenshot](../screenshots/web-desktop-layout/mobile-upload.png) |

Remote validation/deployment is tracked by the PR and main Actions run. Browser
engine tests do not replace the user's physical-device/desktop-browser check.
