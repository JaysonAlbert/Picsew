# Native iOS Stitching Phase 3F

## Problem

The native migration now covers:

- metadata
- low-resolution frame extraction
- scrolling-window detection
- candidate keyframe selection
- keyframe filtering
- full-resolution offset calculation

What is still missing is the final stitch stage that turns the selected full-resolution keyframes plus the calculated offsets into a single long image.

Without this phase, the native pipeline cannot yet produce a final result that matches the web reference end to end.

## Scope

This phase ports the final stitching step to Swift while preserving the current TypeScript behavior.

In scope:

- extract selected full-resolution **color** keyframes in `PicsewMedia`
- stitch them in `PicsewAlgorithm` using the existing offset-calculation output
- preserve the current header / scrolling body / footer composition order
- preserve horizontal offset handling for each inserted slice
- add synthetic and sample-video tests

Out of scope:

- app UI integration
- save/share/export pipeline
- algorithm redesign or heuristics changes

## Design Choice

### Color Frames For Stitching

Offset calculation only needs grayscale, but the final output should preserve the original screenshot content. To match the web reference, `PicsewMedia` will add full-resolution RGBA keyframe extraction for only the filtered keyframes that will actually be stitched.

This keeps the pipeline memory-aware:

- low-resolution analysis remains grayscale
- offset calculation remains grayscale
- only the final stitch stage pulls color data
- only the selected keyframes are decoded

### Stitch Output Shape

`PicsewAlgorithm` will add:

- `PicsewStitchedImage`
- `PicsewStitchingError`
- `PicsewStitcher`

The stitcher will mirror the TypeScript baseline:

1. Copy the header from the first full-resolution keyframe.
2. Copy the full scrolling window from the first keyframe.
3. For each subsequent keyframe:
   - crop the bottom `safeVOffset` rows from the scrolling window
   - shift horizontally using `hOffset`
   - append the resulting slice
4. Copy the footer from the last keyframe.

### Implementation Strategy

The stitched image will be stored as an in-memory RGBA raster:

- `width`
- `height`
- `bytesPerRow`
- `pixels`

This avoids adding UIKit/CoreGraphics dependencies inside the algorithm package while still giving later app layers a predictable image buffer to render or encode.

## Acceptance Criteria

- [ ] AC-01: [P0] `PicsewMedia` can extract selected full-resolution RGBA keyframes from the sample video.
- [ ] AC-02: [P0] `PicsewStitcher` produces the expected stitched height for a synthetic sequence.
- [ ] AC-03: [P0] `PicsewStitcher` preserves the expected header/body/footer ordering in a synthetic sequence.
- [ ] AC-04: [P0] The native sample-video stitch produces an RGBA output whose width matches the video width and whose height matches `PicsewOffsetCalculation.totalHeight`.

## Planned Tests

- `PicsewMediaTests`
  - full-resolution color keyframe extraction preserves original dimensions and RGBA row size
- `PicsewAlgorithmTests`
  - synthetic stitch preserves color rows and final height
  - sample-video stitch returns stable dimensions and byte count

## Notes

- This phase completes the reference algorithm migration through the stitch stage.
- Export and preview can build on this raster output later without changing the core stitch logic.
