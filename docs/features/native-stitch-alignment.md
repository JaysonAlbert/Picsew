# Native stitch alignment regression

## Problem and scope

TestFlight 1.0 (3) repeats or omits text at seams in the local-only recording
`ScreenRecording_10-01-2026 12-38-08_1.MP4`. Fix the native pipeline's frame
continuity and alignment; keep the completion-screen redesign separate.
The original recording and generated chat images must remain ignored/local.

## Design

Use the current TypeScript pipeline as the behavior baseline. It already
restores filtered candidate frames when an independent chain of confident
matches proves that retained frames lost document overlap. Native code still
matches the bottom third of retained frames unconditionally, even when those
frames no longer overlap. Investigate that divergence with the original input
before changing production code. Keep orchestration in PicsewAppCore and
matching/continuity logic in PicsewAlgorithm.

Do not weaken the existing outside-window filter globally. Restore intermediate
frames only when their reliable matches establish continuity. Exclude fixed
floating controls from the matching template as the reference does. Reject
unreliable matches rather than fabricate content or report success. Fresh seam
inspection also shows fixed glass controls covering text at append boundaries.
Port reference pixel recovery: replace copied control regions only with real
visible pixels from a confidently aligned neighboring frame. Copy a full clean
row band where possible to avoid isolated shading patches; preserve regions
that the recording never reveals. This is part of content-correctness parity,
not the separate performance optimization or screen-layout change.

## Acceptance and planned tests

- Reproduce the reported native failure on the original input and capture
  ignored diagnostics plus the actual output PNG.
- Prove retained-frame recovery using a public synthetic sequence with known
  document rows; text-equivalent rows must occur exactly once and in order.
- Compare native output with the reviewed Web result (1206 x 8108), inspecting
  seams and content rather than treating nonempty output as success.
- Keep normal scrolling/filtered-noise behavior covered by existing tests.
- Run Swift package tests, native harness smoke, simulator build, lint,
  typecheck and build before delivery.
- Performance investigation is included: capture per-stage Release timings on the original recording. Optimizations or replacement matchers require a separate delivery and parity validation.
- This algorithm fix does not change UI structure. Use real pipeline output
  inspection as the visual correctness check; do not count fixture-only UI
  screenshots as proof of stitch correctness.

## Reproduction

The current native Release pipeline fails the original-input extent guard and
produces a 1206 x 7195 image, matching the reported phone output. It selected
[0,13,22,32,43,53,63,67], retained [0,22,32,43,53,63,67], and used offsets
[802,879,898,923,983,88]. The output has a visibly cut paragraph after the table.
Processing took 19.278 seconds on this Mac, excluding the 7.64-second compile.
This is not an iPhone performance measurement.

## Verified results

- Original native output: 1206 x 7195, missing text after a bad retained-frame
  match. The opt-in regression failed on that baseline.
- Corrected output: 1206 x 8108 with offsets [862,853,879,898,923,983,88].
  The source-derived glyph oracle finds one occurrence at row 7586, in the final
  footer. Fresh seam crops confirm the P0/P2 paragraphs are complete.
- The public glass MP4 returns its independently specified 480 x 1400 geometry.
  Public synthetic tests prove pixel preservation, reliable bridging, rejection
  of unrelated frames, and keeping the outside-UI filter when overlap agrees.
- Disabling control recovery fails its pixel test with 200 mismatched pixels.
- iPhone 17 Pro / iOS 26.4: installed a Release simulator build, imported the
  original byte-identical HEVC recording through Photos, processed to preview,
  and asserted 1206 x 8108. Exported the actual app share PNG for review. It has
  one final control occurrence, matching the reviewed native result. Simulator
  and macOS PNGs are not byte/pixel-identical; sRGB comparison reports mean
  absolute channel error 0.642/255. Geometry and seam text were inspected directly.
- Native harness smoke passed, including Media, Algorithm, AppCore and App
  package tests, simulator builds, and `flows/smoke-preview.yaml` screenshots.
  The opt-in private recording test ran separately; it is skipped in default CI.
- `npm run check` passed with zero errors and ten existing warnings; Web build
  passed with its existing large-chunk warning.

### Remaining limits

The screen layout is unchanged and still has the previously reported preview
space problem. Glass backgrounds can leave brightness seams; pixels never
revealed cleanly by the recording are preserved. This is a correctness fix,
not a speed optimization or a new TestFlight upload.

## Performance findings and recommended direction

The initial native Release baseline took 19.278 seconds on this Mac for an
11.485-second recording. A corrected run took 17.153 seconds: keyframe selection
9.667s, full-resolution alignment 4.322s, low-resolution decoding 2.173s.
These are desktop measurements, not iPhone results. In the actual simulator UI,
the measured wait for preview was 18.684s after the processing tap completed;
that interval includes UI/export scheduling and is not a profiler sample.

For scroll recordings, prefer a translation-constrained coarse-to-fine matcher:
exclude fixed UI, estimate motion on smaller grayscale images, verify/refine
integer-pixel offsets only near the estimate, and validate overlap before
appending pixels. Phase correlation is a candidate for coarse motion; local
normalized correlation can perform refinement. Benchmark repeated text, blank
areas, fast scrolls and glass overlays before choosing thresholds or replacing
the current matcher. No universal best algorithm is claimed.

Use Apple's Accelerate for vectorized correlation/FFT/image operations, retaining
parity fixtures. Removing per-candidate array copies and repeated statistics is
a focused first optimization; a replacement matcher belongs in a separate delivery.
References: [OpenCV phase correlation](https://docs.opencv.org/4.x/d7/df3/group__imgproc__motion.html)
and [Apple Accelerate](https://developer.apple.com/documentation/accelerate).
