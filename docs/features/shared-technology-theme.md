# Shared technology theme and Web viewer alignment

Date: 2026-10-03

## Problem and scope

The user requests a technology-oriented theme with globally managed design roles.
The native content-first viewer shipped in PR #49, but Web still has result
details, a separate restart row and a 48vh image viewport. This delivery updates
both surfaces as one visual concern. Algorithms, exports and release metadata
stay outside scope.

## Design choice

Use crisp cool surfaces, an electric-blue primary action and restrained violet
accents. Follow system appearance: cool-white light mode and navy dark mode.
Use the existing system typography, spacing and button roles; decorative effects
must not consume preview space. The ui-ux-pro-max accessibility/stack guidance
informs the implementation; its generated chatbot/rose recommendation does not
fit this screenshot utility and is not adopted.

| Color role         | Light   | Dark    |
| ------------------ | ------- | ------- |
| Canvas             | #F3F6FC | #080F20 |
| Surface            | #FFFFFF | #121D33 |
| Ink                | #14213D | #EDF3FF |
| Supporting ink     | #52617A | #AABAD4 |
| Primary action     | #2457E6 | #2457E6 |
| On primary         | #FFFFFF | #FFFFFF |
| Interactive accent | #2457E6 | #8AB4FF |
| Secondary accent   | #6941C6 | #BAA7FF |
| Accent wash        | #E8EEFF | #1B2D50 |
| Border             | #D6DFEF | #34445F |
| Success            | #167252 | #70D9B0 |

Native color values live only in PicsewPalette. Web equivalents live only in
product.css, including the component-library semantic aliases. Button hover,
focus, disabled and secondary states use those roles. Brand glyphs may use a
blue-to-violet gradient; primary buttons keep a solid background for contrast.
No screen-specific color overrides are introduced. Screenshots retain their
original pixels in both appearances.

Web preview adopts a compact title/New capture bar, removes technical details
and the bottom restart row, and dedicates the remaining viewport to the image.
At normal mobile text sizes the image region occupies at least 75% of the app
viewport, with 44px export controls. Larger text can grow the shell and scroll
without clipping actions. Desktop preview uses a wider centered viewer.
Double-click/double-tap or Enter on the image region toggles 1x/2x zoom; horizontal
and vertical scrolling remain available. Export always uses the original image.
Upload and processing keep their existing hierarchy and receive the same theme.

## Acceptance and planned verification

- Review fresh native screenshots of all three routes in light/dark, compact
  iPhone and enlarged Dynamic Type. Run native harness smoke, simulator build,
  preview interaction and navigation edge-hit flows. Inspect original PNG regions
  before classifying an overlap/missing-control defect.
- Update Web interaction tests first: details absent, preview dominance, reachable
  44px targets, zoom/scroll, original-size download and return to upload. Run both
  Chromium and mobile WebKit, with mobile/desktop, light/dark and enlarged text.
- Check visible text contrast (4.5:1), action text and focus contrast in both
  appearances. Do not add tests merely to duplicate hex constants.
- Run lint/typecheck, build and affected unit tests before PR delivery. Update
  this document with actual evidence, including any unvalidated interaction.

## Delivery evidence

- `npm run check`: passed, zero errors and ten existing Playwright warnings.
- `npm run build`: passed; the existing OpenCV bundle-size warning remains.
- `npm run test:unit`: 39 tests passed. `npm run test:e2e:smoke`: 44 tests
  passed across Chromium and mobile WebKit. The focused Web UI suite also passed
  all 26 cases. Details-removal tests failed before implementation; a desktop
  export-in-viewport regression failed against the initial layout and passed
  after removing the inherited content-height rule from preview.
- Fresh browser artifacts include light/dark mobile, 320px at 200% text, desktop
  widths 640/647/1280/1440px and a short desktop window at 200% text. Mobile image
  regions exceed the 75% acceptance gate; 44px export targets, keyboard zoom,
  scrolling, unchanged 720 × 3600 PNG download and New capture all pass.
- `PICSEW_IOS_SMOKE_REQUIRE_MAESTRO=1 npm run ios:harness:smoke`: passed including
  Swift package tests, two simulator builds and `smoke-preview.yaml`.
  `swift test --package-path apps/ios-native/Packages/PicsewDesignSystem` passed.
- Repository-owned Maestro flows ran against this change: `capture-upload.yaml`,
  `capture-processing.yaml`, `capture-preview.yaml`, `capture-onboarding.yaml`,
  `capture-feedback.yaml`, `capture-upload-error.yaml`, `capture-preview-empty.yaml`,
  `preview-interaction.yaml` and `navigation-touch-interaction.yaml`.
  All calls selected a device explicitly. Edge points were Pro `10%,12%` and
  compact SE3 `10%,10%`.
- 26 fresh native route PNGs are retained in ignored `.derived-data/ui-technology/`:
  seven routes each for Pro light/dark; three primary routes for Pro at maximum
  accessibility text, compact light/dark and compact dark at maximum accessibility
  text. Both phones passed 1x/2x zoom, save, scroll and return-to-upload interactions.
- Explicit post-automation visual self-review: **GO**. Original PNGs show the
  cool-white/navy surfaces, blue/violet glyphs, legible supporting text, unchanged
  screenshot pixels and compact export areas. Small-screen and enlarged-text
  layouts keep the existing scrolling/icon-only adaptation. Desktop export
  buttons remain in the viewport after the layout fix.
- Contrast review: light supporting text 5.79:1, dark supporting text 9.72:1,
  white primary-action text 5.86:1, dark toolbar text 8.05:1. Browser tests also
  check actual computed shell/action text contrast in both appearances.

This is fixture-based UI/export verification; it does not repeat the private
recording algorithm benchmark. Physical browser double-tap/pinch, VoiceOver,
iPad and landscape were not manually evaluated. No TestFlight build was uploaded.
