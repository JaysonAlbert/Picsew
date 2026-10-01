# Fixed floating controls in scrolling recordings

Date: 2026-10-01

## Problem and scope

The user confirmed that the repeated down arrows in the generated Web screenshot
are controls fixed to the recording viewport. Current stitching copies the first
scrolling window and appends bottom strips from subsequent keyframes, so an
in-window floating control can be copied multiple times. The rectangular motion
window cannot represent an occlusion inside scrolling content.

This is a focused algorithm bug fix after the Web UI delivery, based on
`src/lib/picsew.ts`. Scope is overlay-aware Web stitching and regression evidence;
preserve real scrolling content, existing header/footer and export behavior.
Do not erase arrow shapes by appearance or crop away whole content rows. Native
parity migration remains separate and must adopt any deliberate behavior change
with matching fixtures before claiming parity with the updated Web baseline.

Work is local in the Codex-owned `codex/floating-overlay-fix` worktree. Existing
open PRs are native UI changes, with no indicated competing algorithm work.

## Acceptance and investigation

1. Run all seven existing local recordings (`demo.mp4`, `demo1`–`demo5`, and
   `test-video.mp4`) through the real pipeline. Save output images and diagnostics
   locally, inspect actual results, and compare the failing examples after changes.
2. A deterministic scrolling fixture must expose the existing repeated-overlay
   defect through the public processing entry point before production edits.
   Expected underlying content comes from the known original document.
3. Preserve document arrows that move with the content and preserve real text
   under the overlay when another aligned frame reveals it. Do not fabricate
   pixels when no source frame provides them; record this boundary explicitly.
4. Run focused algorithm tests, existing unit/browser tests, lint, typecheck and
   build. Use original sample-video frame/keyframe summaries as regression signals,
   without treating unchanged counts as proof of image quality.
5. Source videos and derived real screenshots stay local/ignored. Public regression
   fixtures must be synthetic. Finish delivery only after image-level verification.

## Design and validation

Baseline: all seven recordings completed with saved PNGs. Visual inspection of
`demo3`–`demo5` found the fixed bottom buttons outside the refined body window;
these clips exercise compatibility but do not reproduce the uploaded screenshot.
The synthetic public-pipeline regression reproduces four repeated fixed controls,
versus one unrecoverable last control.

Detect compact stationary edges in existing low-resolution frames, using at
least three spatially separated scrolling views and a 87.5% consensus. Require stable signed local
contrast and motion around the component; exclude large regions and components
outside the scrolling window. Expand each candidate conservatively to cover its
button background/shadow. This is positional evidence, not arrow recognition.

Keep the streaming append behavior. Before estimating full-resolution offsets,
exclude detected overlay columns from the bottom template, using the widest clean
span at least a quarter of the window width. Match within the same source columns
to keep the vertical coordinates and horizontal behavior unchanged. This prevents
a control from pulling the best match one pixel away from the underlying document.
If no usable clean span exists, use the original template and disable recovery. For each copied overlay
rectangle, use an aligned later keyframe to recover the portion now visible at a
clean viewport coordinate. Also use the immediately preceding frame when it
covers a newly appended control. Copy source pixels only where the source lies
inside its scrolling window and outside every detected occlusion. Track pending
rectangles and repair them as future frames reveal them, without retaining all
full-resolution frames (at most the existing previous/current pair).

When no clean source exists, preserve the affected pixels. A last control near the
end can remain once; an occlusion larger than the overlap or insufficient motion
cannot be guaranteed recoverable. Header/footer controls remain unchanged.
Horizontal displacement or a template-match score below 0.7 disables recovery
rather than risking a wrong patch.

Validation includes a known synthetic document with genuine moving green arrows,
an interior fixed control, and pixel comparison against the original unoccluded
document. Public processing tests run in Chromium and mobile WebKit. Geometry and
stationary-edge detection get focused unit coverage. Original recordings are run
serially before/after, with dimensions and full pixels compared for unaffected
outputs. Keep all original recordings/derived screenshots local.

## Baseline compatibility evidence

All seven original clips produced the same dimensions and identical RGBA output
bytes before and after the fix on installed Chrome:

| Recording              | Output dimensions | Before/after pixels |
| ---------------------- | ----------------- | ------------------- |
| demo.mp4               | 1206 × 5004       | Identical           |
| demo1.mp4              | 1018 × 4173       | Identical           |
| demo2.mp4              | 880 × 4624        | Identical           |
| demo3.mp4              | 1206 × 7296       | Identical           |
| demo4.mp4              | 1206 × 26300      | Identical           |
| demo5.mp4 (local only) | 1206 × 10871      | Identical           |
| test-video.mp4         | 756 × 1022        | Identical           |

The existing `demo2.mp4` counter expectation was stale: an independent run using
the original `main` implementation also produced 117 low-resolution frames and
12 candidate/final frames, failing its old expectation of 10. Update that fixture
expectation to the verified unchanged baseline; this does not change selection.
An exploratory `demo3` run had a seek timeout; the final untouched-source run
completed successfully with identical pixels.

The final synthetic fixture was also run against the original implementation:
it failed on four pink control occurrences (rows 485, 725, 965, 1165). The fix
passed all eight Chromium/mobile WebKit cases, including neutral light/dark
controls and a clean document, recovering the moving green arrow previously
covered by the control. Fresh output images were explicitly visually reviewed:
recovered regions match the document, all four green arrows remain, and only the
last unrecoverable control remains. Header/footer and overall image extent remain.

The local opt-in recording harness saves PNGs/diagnostics beneath the Playwright
output directory. It requires all seven local assets, including ignored local
samples; CI runs the committed synthetic fixtures by default. No original videos
or derived real screenshots are added to this delivery.

## Final local validation

- `npm run check`: passed; zero errors, ten existing Playwright warnings.
- `npm run test:unit`: 38 passed, including ten overlay/geometry cases.
- `npm run test:e2e`: 26 passed in Chromium/mobile WebKit; 28 optional
  original-recording cases skipped in the default run. The eight synthetic cases
  actually decode video and execute OpenCV through the upload/preview UI.
- `PICSEW_VIDEO_E2E=1 npx playwright test e2e/algorithm-recordings.spec.ts
e2e/picsew.spec.ts --grep 'recording outputs|demo2.mp4: processing stats'`:
  eight passed, covering all seven local original recordings plus the corrected
  counter. The other six existing opt-in video tests passed in the preceding run.
- Before/after original PNG comparison: all seven dimensions and RGBA buffers
  identical. The timeout observed during exploration was not repeated in the
  final run.
- `npm run build`: passed, with the existing large OpenCV bundle warning.
- Fresh synthetic screenshots inspected after automation: recovered text/green
  arrows match the original document; light/dark controls behave consistently.

Detection remains conservative for intermittent, animated or translucent controls
and insufficient motion. The user's specific source recording was not supplied;
these results establish the known fixed-control regression and compatibility of
the project's recordings, without claiming every possible floating UI is removed.
Native Swift algorithm synchronization is outside this Web delivery.
