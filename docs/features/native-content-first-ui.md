# Native content-first interface

## Problem and scope

The user rejects the completion page: the screenshot occupies too little space,
Result details is unnecessary, and Save/Share controls are oversized. Focus this
delivery on native UI; review import → processing → preview together. Preserve
processing, import/export, feedback, release metadata and the maintenance Web
app. Leave the existing dirty aesthetic checkout untouched.

## Design choice and references

Use native image-viewer structure, compact navigation, SF Symbols and semantic
fonts/colors. The current blue/navy appearance is defined in
[shared-technology-theme.md](shared-technology-theme.md); PR #49 originally used teal. Borrow platform rules in
[mobile-ios-design](https://github.com/wshobson/agents/blob/main/plugins/ui-design/skills/mobile-ios-design/SKILL.md),
while implementing the layout against this acceptance contract.
Apple [image views](https://developer.apple.com/design/human-interface-guidelines/image-views)
and [toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
are the platform references. Desktop Things/Craft/CleanShot references cannot
substantiate this iPhone viewer layout.

- Shell: one compact 52pt title/action bar, composed from shared typography,
  palette and 44pt toolbar buttons. Retain NavigationStack and native safe-area
  handling; hide its platform navigation chrome. Own the action container so
  native toolbar conversion cannot shrink actual hit areas below 44pt. Remove
  the repeated brand row and large heading/subtitle. Import is titled Picsew;
  other routes have compact titles. Preview's leading text action New returns
  to empty import. Feedback remains reachable on import; Back returns to import.
  Like a native compact navigation bar, cap its text scale at xxxLarge while
  retaining accessibility labels; main content continues to the largest
  accessibility sizes. This prevents title/action overlap in the fixed bar.
- Preview: no details disclosure, metadata card, nested outer scroll container,
  capped height or decorative image padding. The full-width image viewport fills
  all space between navigation and the compact bottom toolbar. Initial scale
  fits width; long content scrolls vertically. Pinch and double-tap zoom/reset use
  native UIScrollView zoom, since SwiftUI has no equivalent integrated scroll/zoom
  container on the iOS 18 baseline. Reusable viewer lives in PicsewDesignSystem.
- Export: one 52pt toolbar with Save/Share labels and SF Symbols; targets are at
  least 44pt. No large filled buttons or restart row. Export success/error stays
  visible above actions. Empty preview has recovery through New and disabled
  exports. Large text can use icons with complete accessibility labels.
- Import: one recording stage, concise prompt/filename, Photos/Files choices,
  one privacy caption and one Create action. Preserve selection/error behavior.
- Processing: one centered progress ring and plain-language stage with short
  supporting copy; remove the enclosing card and repeated heading.
- Accessibility: adaptive fonts/colors, VoiceOver names and zoom actions,
  Reduce Motion aware zoom, 44pt targets, portrait phone and large-text support.
  Export state must not reset scroll/zoom. Size the viewer to its own bounds.

## Acceptance and planned tests

The follow-up explicitly requires a modular global design system. Centralize
roles in PicsewDesignSystem, and migrate all native feature views to them.
The package also owns reusable stage cards, action trays, hero symbols and the
zoomable viewer; the app shell only composes routes and compact navigation:

| Role                | System font at default size           | Use                         |
| ------------------- | ------------------------------------- | --------------------------- |
| Hero                | largeTitle bold (34pt)                | Onboarding promise          |
| Title               | title3 semibold (20pt)                | Main content heading        |
| Heading             | headline (17pt)                       | Section heading             |
| Body                | body (17pt)                           | Main explanation            |
| Supporting / strong | subheadline regular / semibold (15pt) | Secondary copy / step badge |
| Caption             | footnote (13pt)                       | Privacy and export status   |
| Action              | body semibold (17pt)                  | Primary/secondary buttons   |
| Toolbar             | callout semibold (16pt)               | Compact export actions      |
| Metric              | largeTitle semibold (34pt)            | Progress percentage         |

All text uses semantic Dynamic Type rather than fixed point sizes. Buttons have
primary (blue fill, 52pt), secondary (neutral surface, 52pt), toolbar (unfilled,
44pt), and quiet (unfilled secondary text, 44pt) roles, with shared disabled and
pressed behavior. Primary/secondary fill the available control width; toolbar
and quiet fit their labels. Spacing tokens are 4/8/12/16/20/24/32; shared metrics
own icon, touch target, action, toolbar and progress sizes. Palette roles own
adaptive canvas/surface/text, blue accent, subtle accent washes, progress track,
inverse text and disabled colors. Use these roles
throughout import, processing, preview, onboarding, feedback and shared shell.
Keep primary fill blue for white-label contrast; use a brighter blue for
accent foregrounds in Dark Mode. Native system components retain system font
behavior. Badges use caption/caption2 roles and icons use a shared 20pt metric.
Do not add tests duplicating token values; prove layout/interaction through the
real rendered routes and existing model regressions.

1. Standard and compact iPhone preview reserve at least 75% of available safe-area
   height for the image before export status. Image is full-width; chrome does
   not cover it. Verify this from fresh screenshots, not generic styling scores.
2. Interaction test must fail on the baseline's visible Result details, then
   prove its removal, image scrolling, zoom/reset, save status and New returning
   to empty import with Create disabled. Also retain a navigation edge-hit flow:
   iPhone 17 Pro uses (10%,12%) and SE3 uses (10%,10%), inside the intended 44pt
   control but outside the former 36pt control. Update obsolete details captures.
3. Current-change Maestro captures cover selected/empty/error import, processing,
   result/empty preview, onboarding and feedback. Include dark mode, compact
   iPhone and accessibility text sizes for primary routes.
4. Install Release, import the original local recording through Photos, inspect
   actual output in the new viewer, and preserve export pixels/geometry. Private
   video/images remain ignored.
5. After capture, a read-only independent evaluator inspects originals against
   this design. Content dominance is a hard gate. Repair and recapture failures.
6. Reuse model tests; run DesignSystem/App tests, required native harness smoke,
   simulator build, lint/typecheck/build before delivery.

This supersedes native preview structure and optional-details acceptance in
ios-minimal-redesign.md. Web viewer adoption is outside this delivery.

## Local validation (2026-10-03)

- `npm run ios:harness:init`; final `PICSEW_IOS_SMOKE_REQUIRE_MAESTRO=1 npm run ios:harness:smoke` passed, including simulator build and `smoke-preview.yaml`.
- Swift harness: 39 active tests passed; the private recording test is opt-in and skipped by the default harness. Ran that test separately in Release with the local recording and it passed. DesignSystem's existing test also passed.
- `npm run check` passed with zero errors and 10 existing Web warnings; `npm run build` passed with the existing bundle-size advisory. Focused formatting and `git diff --check` passed.
- Fresh final screenshots are retained locally under `.derived-data/ui-content-first/final/`; private recording/export artifacts remain under `.derived-data/ui-content-first/real/`, all ignored.

| Simulator / appearance                    | Final routes                                                                        |
| ----------------------------------------- | ----------------------------------------------------------------------------------- |
| iPhone 17 Pro, iOS 26.4, light            | selected/empty/error import, processing, result/empty preview, onboarding, feedback |
| iPhone 17 Pro, dark                       | selected import, processing, result preview                                         |
| iPhone 17 Pro, maximum accessibility text | selected import, processing, result preview                                         |
| iPhone SE3, iOS 26.4, light               | selected import, processing, result/empty preview                                   |
| iPhone SE3, maximum accessibility text    | selected import, processing, result preview                                         |

The 21 route-state screenshots plus 8 interaction screenshots come from the current UI change. Exact repository-owned flows:

- `capture-upload.yaml`, `upload-selection-interaction.yaml`, `capture-upload-error.yaml`
- `capture-processing.yaml`, `capture-preview.yaml`, `capture-preview-empty.yaml`
- `capture-onboarding.yaml`, `capture-feedback.yaml`
- `preview-interaction.yaml` on both phones: details absent, 100% → 200% → 100% zoom, save while zoomed without resetting scale, scroll and New recovery.
- `navigation-touch-interaction.yaml` on both phones: explicit `-e NAV_EDGE_POINT='10%,12%'` for Pro and `-e NAV_EDGE_POINT='10%,10%'` for SE3; both edge-hit checks passed.
- `smoke-preview.yaml` in the required native harness.

Final AX bounds agree with the screenshot geometry: Pro's image viewport is `[0,114][402,788]`, 674pt of 778pt safe-area height (86.6%); SE3's is `[0,72][375,615]`, 543pt of 647pt (83.9%). New and both exports have 44pt control height. The 75% hard gate passes on both default phones.

The original local recording ran through Release Photos import, processing and the viewer. Real save reported success and the system share sheet showed Copy/Save Image actions. Its exported PNG is 1206 × 8108 and byte-identical to the pre-UI simulator export. Zoomed and scrolled real-result screenshots were also captured.

A dedicated read-only evaluator concluded **GO** after inspecting the final original PNGs and targeted header/footer regions: shell, typography, spacing, action layout, recovery and content dominance match this design. Superseded navigation hit areas were repaired and both edge-hit flows re-run before acceptance.

Manual VoiceOver focus/announcements, physical pinch gestures, iPad layouts and iPad landscape were not validated. iPhone remains portrait as configured. This delivery does not upload a TestFlight build.
