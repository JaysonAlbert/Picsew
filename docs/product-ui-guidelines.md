# Picsew product UI guidelines

Date: 2026-10-01

Picsew is one product with a maintenance Web surface and an actively developed
native iOS surface. The user explicitly requires the two surfaces to keep a
consistent UI design. This document is the shared visual contract for future
changes to either surface; native implementation details live in the relevant
feature document.

## Shared visual language

- Calm neutral backgrounds, one simple main stage, and one clear primary action
  area. Content and the generated image take priority over branding and chrome.
- Teal is the product accent. The current native primary action uses approximately
  `#087A70`, with white text. Use it consistently for primary actions and progress,
  rather than assigning unrelated colors to each stage or surface.
- Use adaptive light/dark surfaces and readable text. Native uses system grouped
  backgrounds; Web should use comparable neutral tones. The native light-mode
  supporting text is approximately `#5C636B`. Verify contrast on each surface.
- Use system typography, concise headings, a consistent spacing rhythm based on
  8/12/16/24/32 pt, rounded content surfaces, and restrained effects. Avoid stacked
  glass panels, decorative blobs, repeated badges, and large branded headers.
- Keep state labels and action meaning aligned between platforms and languages.
  Localization should preserve the same hierarchy and intent.

## Shared journey

| Stage      | Main content                                          | Primary action                                  | Supporting information                          |
| ---------- | ----------------------------------------------------- | ----------------------------------------------- | ----------------------------------------------- |
| Import     | Empty prompt or selected recording                    | Create screenshot; disabled without a selection | Source choices and one concise privacy caption  |
| Processing | One progress presentation with a plain-language stage | No competing call to action                     | A short instruction to keep the app/page open   |
| Preview    | Width-fitted long screenshot, scrollable vertically   | Save                                            | Share, New Capture, and optional result details |

Selected, empty, loading, failed, and completed states should remain recognizable
on both surfaces. Keep failures close to the affected content, explain recovery,
and keep usable actions visible. Technical metrics belong in optional details.

## Platform adaptation

- iOS respects safe areas, Dynamic Type, native Files/Photos pickers, and system
  sharing. Web respects responsive widths, browser file selection, keyboard
  navigation, and browser export capabilities.
- A desktop Web layout can use more width while preserving the same reading
  order, main stage, and action hierarchy as mobile Web and iOS.
- Keep controls at least 44 pt/CSS px in their smallest interactive dimension
  and use a comfortable primary action height around 52 pt/CSS px.
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

The native redesign in [ios-minimal-redesign.md](features/ios-minimal-redesign.md)
implements this direction. The deployed Web version has not been redesigned in
this delivery; its compatibility fixes and visual alignment are a separate
follow-up. This document defines that follow-up's design baseline and does not
claim the current two implementations already match.
