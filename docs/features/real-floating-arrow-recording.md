# Real floating-arrow recording fixture

Date: 2026-10-01

## Problem and scope

The user supplied the original iPhone recording that produced repeated fixed
scroll-to-bottom arrows. The earlier synthetic regression proves the general
recovery behavior but does not establish the result for this specific clip.

Register the supplied source as `fixtures/recordings/floating-arrow-2026-10-01.mp4`
and exercise it through the existing real-decoder/OpenCV upload → preview harness.
Preserve the source bytes and record a checksum, original filename and codec
metadata so the sample is identifiable and reusable. Raw input and generated
screenshots are local/ignored by default, matching existing real-sample handling.
The user explicitly chose to keep the original video local and publish only test
code and sample documentation. Do not commit the raw input or derived real images.

## Design and acceptance

- Copy the supplied source without re-encoding or trimming: HEVC, 1206 × 2622,
  approximately 11.485 seconds, 21,615,810 bytes.
- SHA-256: `b253a6975b933c41c96ec6ac6f3756a8944061e557985e2fba4ea79e88859560`.
- Document the local fixture path, reproduction command and the observed issue.
- Add the sample to the existing opt-in recording suite. Missing opted-in inputs
  must fail clearly; default CI must not claim to execute a missing local fixture.
- Run this exact recording on installed codec-capable Chrome without mocking the
  decoder or processing pipeline, inspect the generated image and floating-control
  diagnostics, and report the actual outcome. Do not infer arrow recovery from
  nonempty output or frame counts alone.
- This fixture registration does not claim a new algorithm fix, native parity,
  or general HEVC support in browsers that do not provide the codec.

## Planned verification

Reuse the existing real-recording characterization test; no new production
behavior and no synthetic TDD RED is needed. Verify source checksum after copying,
run the focused opt-in browser case, visually inspect source/output, run lint and
typecheck, and follow the normal PR delivery after relevant checks pass. Keep real
video/image data out of CI failure artifacts and Web deployment build output.

## Observed result on the current algorithm

The exact HEVC file completed the unmocked Chrome pipeline in 6.6 seconds and
produced a nonempty 1206 × 5893 PNG. The scrolling window was reported as
`{x:0,y:444,width:1206,height:1692}`. One stationary control region was detected
at `{x:550,y:2070,width:106,height:66}`. Diagnostics report 20,988 recovered
control pixels and 6,996 pixels without a clean source.

Explicit visual inspection still found repeated down-arrow controls in the
stitched conversation. This sample is therefore a **known unresolved visual
regression**; the nonempty-output characterization passing does not mean the
original defect is fixed. Preserve this source for the next algorithm recovery
investigation. Do not use its current output as an approved golden image.

The new opt-in test passed, as did lint and typecheck (existing warnings remain).
The original source hash was checked after copying. Generated PNGs and logs stay
under ignored local test output. No production algorithm changes are included.
