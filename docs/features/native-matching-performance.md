# Native correlation performance

## Problem and scope

The native low-resolution motion estimator already exists. Its exhaustive
normalized correlation spends most of the runtime copying each candidate
window and recomputing pixel statistics. Full-resolution alignment repeats the
same work. Optimize these two kernels without changing selection, search
bounds, confidence thresholds, continuity recovery, or stitching pixels.

Use the corrected latest-main pipeline as the baseline, including the local
chat recording's 1206 x 8108 output. The recording and all generated artifacts
remain local and ignored. UI and TestFlight release metadata are out of scope.

## Design choice

Share one vertical normalized-correlation kernel in PicsewAlgorithm. Matching
already uses identical source/search columns, so each candidate is a contiguous
slice. Convert bytes to Double once; precompute row prefix sums and squared
sums for constant-time candidate statistics, and use Accelerate's vector dot
product for the cross product. Search every existing integer Y displacement.

For almost-constant areas, avoid cancellation in the variance/cross-product
formula by using the original centered scalar calculation. For nearly tied scores, use the original centered scalar calculation to retain
the previous winner and first-match tie ordering. Preserve nil for constant
templates/search windows and the offset calculator's existing zero-score
fallback. Keep existing pipeline APIs and orchestration unchanged.

This preserves the exhaustive search rather than introducing a coarse
prediction radius, FFT, or changed candidate policy in a performance delivery.
Those changes need separate behavior and ambiguity evaluation if still needed.

## Acceptance and verification

- Add passing-before-change characterization cases through the existing
  offset/selection entry points. Compare against the original scalar NCC for
  seeded noise, known translations, constant/low-contrast areas, alternating
  contrast and repeated patterns/ties. This is behavior-preserving validation,
  not a claimed TDD RED.
- Run existing algorithm, continuity, public recording and application tests.
- Measure Release pipeline stage timings on the original recording before and
  after, excluding compilation. Preserve candidates, retained frames, offsets
  and the exported PNG exactly on the same macOS decoder.
- Target at least a 2x reduction in combined selection/alignment duration;
  record actual end-to-end improvement and remaining bottlenecks.
- Run native harness smoke, a simulator Release build and real Photos import
  to processing/preview; inspect the actual exported result and fresh screenshot.
- Run lint/typecheck/build and review the focused diff before delivery.

Primary API reference: [Apple Accelerate correlation and convolution](https://developer.apple.com/documentation/accelerate/1d-correlation-and-convolution).

## Local results

Three sequential Release runs per implementation, excluding compilation, on
the same Mac and original 11.485-second recording:

| Stage                              | Baseline median | Optimized median |
| ---------------------------------- | --------------: | ---------------: |
| Whole processing pipeline          |         15.841s |           3.808s |
| Low-resolution candidate selection |          9.054s |           0.953s |
| Full-resolution alignment          |          4.075s |           0.322s |
| Low-resolution video extraction    |          1.937s |           1.951s |

End-to-end speedup is 4.16x; combined selection/alignment is about 10.3x faster.
All six outputs have identical PNG bytes, candidates, retained frames, offsets
and geometry. Final numerical tie protection was widened to 1e-7; a subsequent
Release run took 3.664s and still produced the identical PNG. Scores at close
winners are recomputed with the original centered formula.

The native harness passes Media, Algorithm, AppCore and App tests (39 active
Swift tests; the private-recording test is skipped by default and ran separately),
simulator builds and Maestro preview smoke. The two new characterization tests
cover eight patterns each; the first seven were also run successfully before
replacing the kernel. Lint/typecheck/build pass with existing warnings.

The iPhone 17 Pro / iOS 26.4 simulator ran the Release app with the original
recording imported through Photos, without a fixture automation scenario. The
same local Maestro flow reached preview 5.167s after the processing tap completed
(previous correctness build: 18.684s). This includes automation/UI scheduling,
not just algorithm CPU time. The actual exported simulator PNG is byte-identical
to the previous simulator export. Fresh complete-page and seam images were
inspected; text remains intact and geometry is 1206 x 8108. No UI redesign or
TestFlight upload is included.

Low-resolution video decoding is now the main remaining cost. Double buffers
are allocated once per match and released after it. Extremely low-contrast or
ambiguous repeated content may use slower scalar verification to preserve the
original decision. These measurements are not iPhone device benchmarks.
