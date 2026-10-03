# Picsew product UI guidelines

Date: 2026-10-03

Picsew is one product with a maintenance Web surface and an actively developed
native iOS surface. The user explicitly requires the two surfaces to keep a
consistent UI design. This document is the shared visual contract for future
changes to either surface; native implementation details live in the relevant
feature document.

## Shared visual language

- Cool technology-oriented backgrounds, one simple main stage, and one clear primary action
  area. Content and the generated image take priority over branding and chrome.
- Electric blue `#2457E6` is the primary action with white text; dark-mode
  interactive text uses `#8AB4FF`. Violet is a restrained secondary accent.
  Both surfaces use the role table in
  [shared-technology-theme.md](features/shared-technology-theme.md).
- Use adaptive cool-white/navy surfaces and readable text. Native PicsewPalette
  and Web product.css own all color roles, including hover, focus and disabled
  states. Verify contrast on each surface.
- Use system typography, concise headings, a consistent spacing rhythm based on
  8/12/16/24/32 pt, rounded content surfaces, and restrained effects. Avoid stacked
  glass panels, decorative blobs, repeated badges, and large branded headers.
- Keep state labels and action meaning aligned between platforms and languages.
  Localization should preserve the same hierarchy and intent.

## Shared journey

| Stage      | Main content                                          | Primary action                                  | Supporting information                         |
| ---------- | ----------------------------------------------------- | ----------------------------------------------- | ---------------------------------------------- |
| Import     | Empty prompt or selected recording                    | Create screenshot; disabled without a selection | Source choices and one concise privacy caption |
| Processing | One progress presentation with a plain-language stage | No competing call to action                     | A short instruction to keep the app/page open  |
| Preview    | Dominant width-fitted long screenshot, scroll/zoom    | Save                                            | Share and New Capture                          |

Selected, empty, loading, failed, and completed states should remain recognizable
on both surfaces. Keep failures close to the affected content, explain recovery,
and keep usable actions visible. Native preview omits technical result metrics
and uses a compact toolbar.

## Platform adaptation

- iOS respects safe areas, Dynamic Type, native Files/Photos pickers, and system
  sharing. Its preview uses a compact title/action bar and a full-width image viewer;
  [native-content-first-ui.md](features/native-content-first-ui.md) defines its
  current acceptance. Web respects responsive widths, browser file selection, keyboard
  navigation, and browser export capabilities. Web preview adopts the same
  compact header, dominant viewer and compact export area; it omits result details.
- A desktop Web layout can use more width while preserving the same reading
  order, main stage, and action hierarchy as mobile Web and iOS. At 640 CSS px
  and above, Web uses a content-height column with compact actions immediately
  below the content; narrow mobile Web keeps its bottom action area. Preview
  instead uses a viewport-height viewer on both widths. Desktop
  controls retain the same comfortable minimum height and visual language.
- Keep controls at least 44 pt/CSS px in their smallest interactive dimension
  and use a comfortable create action height around 52 pt/CSS px. Native preview
  exports use compact 44pt targets in one 52pt toolbar.
- Browser limitations or native permissions should be explained with actionable
  product copy. Preserve the shared design when presenting those differences.

## Change and acceptance rules

1. Review the complete import → processing → preview journey whenever shared
   shell structure, colors, typography, or actions change.
2. Update this document before adopting a new shared visual direction. Update
   affected platform feature documents alongside it.
3. Native UI work requires current-change Maestro screenshots and a visual
   evaluator pass, including compact layouts and relevant states.
4. Web UI work requires browser interaction checks and fresh mobile/desktop
   screenshots. Compare those artifacts against the native reference and this
   contract, accounting for platform capabilities.

## Current adoption

The earlier native redesign shipped in [PR #37](https://github.com/JaysonAlbert/Picsew/pull/37).
The current native viewer and modular design system are defined in
[native-content-first-ui.md](features/native-content-first-ui.md).
The current shared theme and Web viewer adoption are described in
[shared-technology-theme.md](features/shared-technology-theme.md).
[web-ui-alignment.md](features/web-ui-alignment.md) records the earlier Web adoption.
Each platform keeps its own implementation and validation evidence while sharing
this visual contract.

## Visual reference library

[Official app references](../reference/design/README.md) archive Things, Craft
and CleanShot desktop interface images with sources and adoption notes for Web.
For native iOS, use the platform references and acceptance contract in
[native-content-first-ui.md](features/native-content-first-ui.md).
