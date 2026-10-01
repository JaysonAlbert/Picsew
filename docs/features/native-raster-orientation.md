# Native decoded frame orientation

Date: 2026-10-01

## Problem and scope

The real Photos import regression exposed a vertically inverted native preview:
the public fixture's FIXED FOOTER was at the top, upside down, and its downward
arrow pointed upward. The source MP4 extracted independently with ffmpeg has
normal orientation. Both grayscale and RGBA bitmap conversions apply an extra
vertical reflection before reading CGContext memory.

Preserve the stitching algorithm and AVAssetImageGenerator's preferred-transform
handling. Correct decoded raster row order at the media boundary so row zero is
the video's visual top, matching the TypeScript reference. This focused fix is
separate from Photos selection wiring; the next TestFlight candidate combines
the independently validated fixes.

## Design and acceptance

- Remove the extra vertical reflection from grayscale and color bitmap drawing.
- Add a tiny public MP4 with literal red top and blue bottom. Verify decoded
  color channels and relative grayscale intensity against these independent
  expectations, at both full and low resolution. First observe the tests fail
  against the old converter.
- Existing metadata, frame cadence, dimensions and extraction tests stay green.
  Correct the sample detector test's inverted-coordinate expectation: independent
  source frames show scrolling text reaching the top edge, so the original
  motion window begins at row zero, rather than below row 600. Keep the other
  window bounds and all synthetic algorithm expectations intact.
- Include media package tests in the repository-owned native harness gate so the
  orientation regression runs in CI as well as locally. Run algorithm package
  tests there too to validate its consumers against the corrected media input.
- Run native harness smoke and simulator builds. Run the real Photos integration
  on the combined candidate, inspect a fresh preview against the original video:
  footer remains at the bottom, text upright and arrow points down.
- Run typecheck and web build before Git delivery; archive and upload the combined
  TestFlight build only after validation passes.

## Fixture

`fixtures/media-orientation/red-top-blue-bottom.mp4` is generated content with no
private information. It provides an independent row-order oracle rather than
comparing two implementations that might share the same inversion.

## Verification results

The two orientation tests failed on the original converter (blue first row,
red last row and reversed luminance), then passed after removing the reflection.
All seven Media tests and eleven Algorithm tests passed. The sample algorithm
expectation was corrected against independently extracted source frames; no
synthetic algorithm expectations or production algorithm logic changed.

Native harness smoke passed with Maestro required: eleven app tests, simulator
builds and preview smoke. The real Photos flow passed again on the combined
candidate, covering selection, clearing, same-video reselection and processing.
Fresh import and preview artifacts were explicitly reviewed: selected state and
primary action match the existing design, text is upright and arrows point down.
The generated share PNG was inspected in full: SCROLLING DOCUMENT is at the top
and FIXED FOOTER at the bottom. It still contains repeated floating controls;
porting the separately delivered Web overlay algorithm is outside this fix.

Repository typecheck/lint passed with zero errors and ten existing warnings;
production Web build passed with the existing chunk-size warning. Native Release
archive succeeded. TestFlight distribution is verified separately from archiving.
