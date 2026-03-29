# Native iOS Offset Calculation Phase 3E

## Problem

The native migration currently stops after low-resolution keyframe filtering. The web reference pipeline then decodes only the clean full-resolution keyframes, measures per-pair vertical offsets inside the refined scrolling window, and uses those offsets to determine the stitched output height.

Without a native offset-calculation stage, the iOS pipeline cannot yet prove parity with the web reference for the final pre-stitch geometry.

## Scope

This phase ports the offset-calculation step to Swift and keeps the current reference behavior intact.

In scope:

- decode only the filtered full-resolution keyframes needed for stitching
- represent full-resolution grayscale keyframes in `PicsewMedia`
- calculate per-pair offsets in `PicsewAlgorithm`
- compute `headerHeight`, `footerHeight`, and `totalHeight`
- add synthetic and sample-video tests

Out of scope:

- final image stitching
- UI integration
- algorithm redesign or heuristic tuning

## Design Choice

### Media Layer

`PicsewMedia` will add a focused extractor for full-resolution grayscale keyframes by frame index. It will reuse the existing `AVAssetImageGenerator` path and the same frame cadence derived from `PicsewVideoMetadata`.

This keeps memory usage aligned with the web reference:

- decode only the selected keyframes
- avoid materializing the entire video at full resolution
- keep frame data in grayscale because matching only needs luminance

### Algorithm Layer

`PicsewAlgorithm` will add:

- `PicsewStitchOffset`
- `PicsewOffsetCalculation`
- `PicsewOffsetCalculationError`
- `PicsewOffsetCalculator`

The offset calculator will reproduce the current TypeScript baseline:

1. Crop the refined scrolling window from the previous and current full-resolution keyframes.
2. Take the bottom third of the previous window as the template.
3. Run normalized template matching against the full current window.
4. Compute:
   - `vOffset = height - templateHeight - matchY`
   - `hOffset = matchX`
5. Sum positive vertical offsets to compute the stitched output height:
   - `headerHeight + refinedWindow.height + footerHeight + Σ max(0, vOffset)`

### Matching Approach

The native implementation will use a deterministic Swift normalized cross-correlation matcher over grayscale buffers. This preserves the same matching geometry as the TypeScript/OpenCV reference while avoiding a new OpenCV dependency on the native side.

## Acceptance Criteria

- [ ] AC-01: [P0] `PicsewMedia` can decode a selected subset of full-resolution grayscale keyframes from a sample video.
- [ ] AC-02: [P0] `PicsewOffsetCalculator` returns the expected offsets and total height for a synthetic scrolling sequence.
- [ ] AC-03: [P0] `PicsewOffsetCalculator` returns a stable ordered offset list for the sample video using filtered keyframes.
- [ ] AC-04: [P1] `totalHeight` is always at least the original frame height and reflects the accumulated positive offsets.

## Planned Tests

- `PicsewMediaTests`
  - selected full-resolution keyframe extraction preserves original video dimensions
- `PicsewAlgorithmTests`
  - synthetic offset calculation returns known `vOffset` values
  - sample-video offset calculation returns stable counts, bounds, and positive stitched height growth

## Notes

- This phase intentionally stops before stitching.
- Horizontal offset is still surfaced because it exists in the reference output shape, even though the current full-width scrolling-window baseline usually yields `0`.
