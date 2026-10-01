# Real floating-control regression recording

The original source supplied by the user for the repeated down-arrow issue is
stored locally as `floating-arrow-2026-10-01.mp4` in this directory. The user explicitly chose local-only storage for the original video; it is
ignored by Git. Only the test code and this sample documentation are committed.

- Original filename: `ScreenRecording_10-01-2026 12-38-08_1.MP4`.
- SHA-256: `b253a6975b933c41c96ec6ac6f3756a8944061e557985e2fba4ea79e88859560`.
- Size: 21,615,810 bytes; duration: 11.485261 seconds.
- Codec: HEVC; dimensions: 1206 × 2622; average frame rate: approximately 60 fps.
- Defect: a white circular scroll-to-bottom button stays at the same viewport
  position while the conversation scrolls; the old output repeats its black arrow.
- Preservation: original bytes; no transcode, crop or content modification.

Place the original file at the path above, then run:

```sh
PICSEW_VIDEO_E2E=1 npx playwright test e2e/algorithm-recordings.spec.ts --grep floating-arrow-2026-10-01
```

The test requires a browser that can decode HEVC (installed Chrome on this Mac).
It saves `stitched.png` and `diagnostics.json` under ignored `test-results/`.
The fixture's opt-in case fails if the original source is absent. Default CI
continues to validate the public synthetic floating-control fixtures.

See [fixture investigation](../../docs/features/real-floating-arrow-recording.md)
and [algorithm design](../../docs/features/floating-overlay-stitching-fix.md).

## Regression acceptance

The original baseline generated a 1206 × 5893 image with three fixed-arrow
occurrences, including cropped duplicates. The updated test seeks the input to
0.5 seconds and samples the measured upper glyph at x=578, y=2100 (50 × 34), then
counts matching black/white shapes in the output. The source template itself is
validated so a black or empty decoded frame cannot create a false pass.

Acceptance is exactly one occurrence in the final 600 output rows, where the
recording never reveals a clean background for the footer button. A nonempty
image alone no longer passes this sample's test. The new result is 1206 × 8108,
with one footer occurrence; restored candidates also recover omitted content.
See [the incremental fix](../../docs/features/floating-arrow-real-recovery.md).
Other local recordings retain their output-generation checks. Public synthetic
fixtures separately verify document pixels and genuine moving arrows.
