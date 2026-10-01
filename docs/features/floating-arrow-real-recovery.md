# Recover the real recording's floating arrow

Date: 2026-10-01

## Scope and baseline

Incremental L1 bug fix based on [fixed floating controls](floating-overlay-stitching-fix.md).
The exact local HEVC source registered in [real recording](real-floating-arrow-recording.md)
still repeats the fixed down-arrow. Only Web detection/alignment/recovery and directly
related regression evidence are in scope. Preserve document text, moving arrows,
header/footer and streaming memory behavior. Native migration remains separate.
Raw input and derived conversation images stay local/ignored as chosen by the user.

## Investigation and design

The control has a translucent circular background and crosses the refined scrolling
window's lower boundary. The baseline detects only a 106 × 66 region clipped to
that boundary. Investigate complete occlusion coverage and alignment confidence
before changing recovery. Investigation confirms that the first two candidate frames
(13 and 22) are dropped because content visible through the fixed translucent UI
changes outside the body. The surviving 0 → 32 pair no longer overlaps reliably:
its correlation is 0.108, yet the old code appends its arbitrary match and discards
pending recovery. This loses document continuity as well as leaving controls.

For a low-confidence or displacement-inconsistent pair with a detected control,
consider discarded candidate frames between its endpoints. Insert them only when their entire low-resolution
alignment chain is confident and forward; keep full-resolution verification and
streaming assembly. Compare the direct match displacement against the validated
chain as well: repeating scenery can give a high correlation for a wrong small
offset after a gap. In the synthetic reproduction the old result loses 560 rows.

Fresh real output also exposes rectangle-shaped brightness seams because glass
UI changes the background near the viewport edge. Where source rows are wholly
unoccluded, recover the full-width row band from that same aligned frame, instead
of a small isolated rectangle. Otherwise retain the narrower clean pieces. This
copies real document pixels across the brightness boundary; no background fill
or inpainting is used. Do not globally disable outside-UI filtering. Extend detected
occlusion padding to frame bounds when the control crosses the refined window,
so a partially outside control cannot become a supposedly clean source. Existing
no-control paths retain their current selection and pixels. Repair from aligned
visible source pixels; never erase text, synthesize replacement pixels or crop away entire rows to hide the button.
When the recording never reveals clean pixels, retain one final control and report
that boundary rather than claiming complete removal.

## Acceptance and verification

- Establish a failing public synthetic pipeline regression for the observed cause,
  with a known unoccluded document as independent pixel oracle; moving document
  arrows and surrounding text must survive.
- Strengthen the opt-in original-recording test with an image-level repetition
  check, derived from the original fixed button's geometry, not processing counts.
- Run the supplied recording and visually inspect fresh full output and seam crops.
  No repeated floating arrows should remain in the stitched body; one unavoidable
  final footer button may remain if the video supplies no clean source.
- Run all seven previous local recordings and compare output dimensions and pixels
  against the existing baseline. Investigate differences instead of accepting frame
  counts as proof of quality.
- Run algorithm unit tests, Chromium/mobile WebKit public pipeline regressions,
  lint, typecheck and build before commit/push/PR and authorized automatic merge.
- Reverting the focused algorithm commit restores the previous implementation.

## Verified outcome

The exact HEVC source changes from 1206 × 5893 with three arrow matches (rows
2100, 2479, 5371) to 1206 × 8108 with one match at row 7586. Frames 13 and 22 are
restored only after the complete intervening overlap chain passes. The detector
covers 106 × 88 instead of 106 × 66; 48,972 control pixels are recovered, with
6,996 pixels lacking a clean source at the final button. These are diagnostics;
acceptance comes from the input-derived glyph oracle and fresh visual inspection.

Fresh full output was split into four readable review crops; each was inspected,
along with the first repaired seam and the final footer. Repeated body arrows
and isolated white rectangles are absent, and the previously omitted paragraphs
are present. The last footer button remains deliberately. Viewport glass shading
can still create horizontal brightness seams; this fix does not promise a general
reconstruction of backgrounds that were never visible without glass UI.

All seven prior recordings have identical dimensions and RGBA pixels compared
with the saved verified baseline from the previous fix:

| Input          | Output       |
| -------------- | ------------ |
| demo.mp4       | 1206 × 5004  |
| demo1.mp4      | 1018 × 4173  |
| demo2.mp4      | 880 × 4624   |
| demo3.mp4      | 1206 × 7296  |
| demo4.mp4      | 1206 × 26300 |
| demo5.mp4      | 1206 × 10871 |
| test-video.mp4 | 756 × 1022   |

Regression strength was checked explicitly: the original real pipeline fails
with three glyph occurrences; the original synthetic path loses 560 document rows.
Reverting boundary padding fails its unit case. Disabling full-width band recovery
fails the synthetic repaired-row pixel oracle (mean error above 11 versus limit 7).
All temporary mutations were restored before final validation.

Local validation:

- `npm run check`: passed, zero errors; ten pre-existing warnings.
- `npm run test:unit`: 39 passed, including the boundary regression.
- `npx playwright test e2e/floating-overlay.spec.ts`: ten passed across Chromium
  and mobile WebKit, preserving the known document and all four moving arrows.
- `PICSEW_VIDEO_E2E=1 npx playwright test e2e/algorithm-recordings.spec.ts e2e/picsew.spec.ts`:
  19 passed, including all eight real recordings and existing codec flow/stat cases.
- The strengthened original-recording case was rerun after final test cleanup:
  one passed, with the image-level occurrence assertion actually executed.
- `npm run test:e2e`: 40 passed in Chromium/mobile WebKit; 30 local-recording
  cases skipped by default. The opt-in runs above actually execute the originals.
- `npm run build`: passed with the existing OpenCV bundle-size warning.

Raw media and real output remain ignored. Only the synthetic `glass` recordings,
source generator, test code and documents are published. Native Swift processing
has not adopted this incremental Web behavior and is not claimed as validated.
