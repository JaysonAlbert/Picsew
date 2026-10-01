# Native iOS minimal redesign

Date: 2026-10-01

## Problem and scope

Picsew's product investment is native iOS; the web app stays in maintenance mode.
The user requests a simpler, more attractive native app. PR #36 is an unmerged,
conflicting aesthetic experiment, and its local checkout contains user changes.
This delivery starts from current `main`, preserves that checkout, and replaces
the competing glass surfaces, oversized shell, repeated status, and inset preview
with a calm utility interface. Web compatibility will be addressed separately.

The user's follow-up requires consistent UI design across Web and native iOS.
[Product UI guidelines](../product-ui-guidelines.md) are the shared contract;
this native delivery establishes its visual baseline for the later Web work.

Scope: shared shell, import, processing, preview, and first-run onboarding.
Preserve Files/Photos import, pipeline order and algorithm behavior, save, share,
restart, existing route IDs, and release/signing configuration.

## Design

- Use adaptive system backgrounds and text colors. Reserve a dark teal accent
  for primary actions and progress; eliminate atmospheric blobs, heavy shadows,
  and decorative surface gradients. Retain system typography and Dynamic Type.
- Use one compact 44 pt utility row. Place one concise route heading below it.
  Remove the redundant journey dots and step badges from the visible shell.
  Respect the safe area once; do not add its top inset a second time.
- Import: one input card, either an empty prompt or selected filename, followed
  by lightweight Files and Photos choices. A single privacy caption sits below.
  Start remains disabled until a recording is selected; clearing returns to the
  empty state. Controls are at least 44 pt, with a 52 pt primary action.
- Processing: one centered stage with one teal progress ring and human-readable
  stage text. Do not duplicate the ring with a second progress bar, stage counter,
  or technical pipeline explanation. Expose progress to VoiceOver.
- Preview: a width-fitted long image in one simple viewport sized to the available
  screen height, vertically scrollable without horizontal scrolling. Result
  details stay outside that image viewport. Save is primary, Share is secondary, and New
  Capture is a lower-emphasis action. Technical result details are collapsed
  behind a disclosure. Export success/errors remain visible as inline status.
- Onboarding: one short promise and three plain steps; no nested cards or status
  chips. Continue dismisses it. Shared styles also apply to the existing feedback
  route; replace its placeholder with a clearly labeled GitHub feedback link.
  Keep its stage scrollable and heading fully wrapped at accessibility sizes.
  Building a native backend feedback form is outside this redesign.
- Content can scroll at large accessibility text sizes. Bottom actions use safe
  area insets and must not obscure content. Secondary actions use generous touch
  targets, not tiny text-only hit areas.
- At accessibility text sizes, use a short route heading and omit its repeated
  subtitle. Decorative navigation icons keep a fixed size. Import actions use
  shorter visible labels (Create / Clear) with complete spoken labels, so the
  footer leaves room for the input stage. Action labels expand vertically rather
  than truncating. Keep body text fully scalable and scrollable.
- The model owns route switching; the root does not need a second, empty
  navigation stack around its custom shell. Keep the modal onboarding surface
  full-height and the status bar consistent with system appearance. Empty preview
  uses state-aware introductory copy rather than promising an available export.

## Acceptance and planned validation

1. Fresh simulator screenshots of selected, empty, and failed import, processing,
   preview (including empty), expanded details, onboarding, and feedback show consistent surfaces,
   concise copy, and one clear focal stage. Include compact iPhone, Dark Mode,
   and accessibility text-size captures for layout risk.
2. Import clearing disables Start; tapping the empty Start cannot navigate to
   processing. Existing success/failure/import/save tests continue to pass.
3. Preview details are initially hidden, can be expanded, and do not prevent
   save or restart. A repository-owned Maestro interaction flow covers those
   observable guarantees. Verify it fails on the baseline before implementation.
4. All affected controls have at least 44 pt hit targets; text uses scalable
   system styles; progress has a spoken label/value. Image preview fits width.
5. Run design-system and app Swift tests, `npm run ios:harness:smoke` (including
   simulator build and Maestro smoke), plus lint, typecheck, and web build.
6. After automation, run a dedicated read-only evaluator against current-change
   artifacts using the repository's native iOS rubric. Iterate on hard failures.

Static capture flows end with their screenshot; clearing, onboarding dismissal,
and export/restart have separate interaction flows. Use
`bash scripts/ios-native/capture-ui-screenshots.sh <simulator-id> <output-directory>`
to run each repository-owned Maestro flow and then take a settled simulator PNG
after the command finishes. These post-flow PNGs are the evaluator artifacts;
the raw in-flow captures remain in ignored Maestro artifacts. This avoids
accepting a modal/launch transition as a stable page.

No new algorithm tests are needed because pipeline behavior is unchanged. The
existing route-title expectations must be updated to the concise user-facing
titles; they are not the primary proof of visual quality.

The preview screenshot fixture should resemble readable scrolling content,
rather than the previous solid color gradient, so the evaluator can judge image
width, padding, and scroll behavior. It is deterministic demo content, not a
claim of real-video processing or photo-library integration coverage.

## Delivery and risks

Commit only this concern on `codex/ios-minimal-redesign`. Deliver a separate PR
from `main`; do not merge or rewrite PR #36. Screenshots and validation results
will be linked below after running them. Maestro scenarios use fixture results;
real Photos permissions, sharing to other apps, and long-video performance are
outside this visual validation and remain release checks.

## Validation results

- App Swift tests: 11 passed. Design-system Swift tests: 1 passed.
- Lint: no errors; eight existing warnings in Web Playwright tests. Typecheck
  and Web production build passed; the build retains its existing chunk-size warning.
- The new preview interaction failed on the baseline at the absent result-details
  disclosure, then passed after implementation. The full Maestro directory
  passed all 12 flows: `capture-upload`, `capture-upload-error`,
  `upload-selection-interaction`, `capture-processing`, `capture-preview`,
  `capture-preview-empty`, `capture-preview-details`, `preview-details-interaction`,
  `capture-onboarding`, `onboarding-interaction`, `capture-feedback`, and `smoke-preview`.
  After the final feedback heading/scrolling adjustment, `capture-feedback` was
  rerun successfully at standard, maximum accessibility, and compact sizes,
  and the harness was rerun on the current code as recorded below.
- `PICSEW_IOS_SMOKE_REQUIRE_MAESTRO=1 npm run ios:harness:smoke` passed:
  ledger validation and its two tests, 11 app Swift tests, simulator build,
  simulator install, and the Maestro preview smoke. No Maestro step was skipped.
- Independent read-only evaluator: **Ready**, all visual hard gates passed.
  It inspected 26 settled originals, then accepted the final three feedback
  captures (two replacements and one additional maximum-size capture).
  The final set contains 27 current-change artifacts.

| Route                              | Evaluator score | Decision |
| ---------------------------------- | --------------- | -------- |
| Import (selected / empty / error)  | 96/100          | Ready    |
| Processing                         | 96/100          | Ready    |
| Preview (result / details / empty) | 94/100          | Ready    |
| Onboarding                         | 96/100          | Ready    |
| Feedback                           | 96/100          | Ready    |

Overall score uses the lowest route score: **94/100**. Large text, compact
layouts, stage/action hierarchy, contrast, and recovery gates passed. The
evaluator checked VoiceOver metadata in source; a full manual VoiceOver
navigation audit was not performed. Expanded details may need vertical scrolling
on small screens; their content remains reachable above the inset action area.

The current-change screenshot directory is
[`ios-minimal-redesign`](../screenshots/ios-minimal-redesign/). Standard references:

| Import                                                     | Processing                                                     | Preview                                                   | Onboarding                                                      |
| ---------------------------------------------------------- | -------------------------------------------------------------- | --------------------------------------------------------- | --------------------------------------------------------------- |
| [Selected](../screenshots/ios-minimal-redesign/upload.png) | [Progress](../screenshots/ios-minimal-redesign/processing.png) | [Result](../screenshots/ios-minimal-redesign/preview.png) | [First run](../screenshots/ios-minimal-redesign/onboarding.png) |

Additional references cover empty/failed import, empty preview, expanded details,
and feedback. The matrix includes four dark-mode routes, five routes at the largest
accessibility text size, and all nine states on iPhone SE (3rd generation).
Screenshots use fixture state on iOS 26.4 simulators. They do not prove real Photos
permission prompts, external share destinations, or real-video processing parity.
