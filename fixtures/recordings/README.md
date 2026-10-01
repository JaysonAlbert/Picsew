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

## Known unresolved result

On the current algorithm, the exact source produces a nonempty 1206 × 5893 image,
but repeated down-arrow controls remain visible. The opt-in test currently checks
successful real decoding and output generation, **not complete overlay removal**.
Use the saved PNG and diagnostics for visual verification; this output is not a
correctness baseline. The existing synthetic fixtures remain the automated
pixel-level regression for their deliberately controlled inputs.
