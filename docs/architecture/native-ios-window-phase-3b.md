---
status: approved
---

# Native iOS Window Phase 3B

## TL;DR

Phase 3B ports refined scrolling-window detection to Swift. It consumes the low-resolution grayscale frames produced by `PicsewMedia`, reproduces the current threshold-and-accumulate motion logic, and returns the full-width original and refined windows needed by later stages. This phase still stops before keyframe selection and stitching.

## Terms

- Motion accumulator: The per-pixel sum of thresholded absolute frame differences across consecutive low-resolution grayscale frames.
- Original full-width window: The first full-width vertical region derived from the largest motion contour before insetting.
- Refined window: The inlaid full-width window after trimming 10% from the top and bottom of the detected motion region.
- Outside mask: A low-resolution binary mask that marks everything outside the original motion window for later interruption filtering.

## Problem

The native pipeline can now load metadata and extract low-resolution grayscale frames, but it still cannot identify where the scrolling content lives. Without the scrolling-window stage:

- keyframe selection cannot be ported faithfully
- later interruption filtering has no outside mask
- the native algorithm has no validated handoff from media extraction into analysis

## Scope

### In scope

- Port the current scrolling-window detection logic into `PicsewAlgorithm`.
- Consume `PicsewMedia` low-resolution grayscale frames as input.
- Reproduce:
  - absolute frame differencing
  - threshold at `30`
  - accumulator normalization
  - threshold at `50`
  - largest connected motion region
  - original full-width window
  - 10% vertical inset refined window
  - low-resolution outside mask
- Add tests for both synthetic frames and the repository sample video.

### Out of scope

- Keyframe selection
- Interruption filtering beyond generating the outside mask
- Offset calculation
- Stitching

## Acceptance Criteria

- [ ] AC-01: [P0] The native algorithm package can detect a refined scrolling window from synthetic grayscale frames with a known motion band.
  - Given synthetic low-resolution grayscale frames with motion in a known vertical strip
  - When the Swift detector runs
  - Then it returns the expected full-width original window, refined window, and outside mask dimensions
- [ ] AC-02: [P0] The detector works on the repository sample video frames and produces a stable full-width refined window within the expected lower scrolling region.
  - Given low-resolution grayscale frames extracted from `test-video.mp4`
  - When the detector runs
  - Then it returns a non-empty full-width window in bounds, with the refined window nested inside the original window
- [ ] AC-03: [P1] The algorithm package keeps using the current TypeScript migration guardrails while adding the new scrolling-window types and tests.

## Design

### ADR-001

- Status: Accepted
- Context: The TypeScript implementation uses OpenCV contour detection, but the native port should avoid over-committing to a heavy dependency before the algorithm baseline is established.
- Decision: Implement the scrolling-window step with pure Swift array processing and connected-component detection over the binary motion mask.

#### Alternatives

| Option                                                 | Pros                                       | Cons                                                | Conclusion |
| ------------------------------------------------------ | ------------------------------------------ | --------------------------------------------------- | ---------- |
| Add OpenCV to the native algorithm package immediately | Closer API parity with web                 | Larger integration cost too early                   | Rejected   |
| Use pure Swift binary-mask analysis for this stage     | Lightweight, testable, enough for baseline | Requires our own connected-component implementation | Accepted   |

#### Consequences

- The native baseline remains dependency-light during the early migration.
- We can validate the algorithm stage behavior before deciding whether a heavier native CV dependency is needed later.

## Reference behavior

This phase mirrors the current TypeScript logic in `/Volumes/data/Projects/Picsew/src/lib/picsew.ts`:

- input: low-resolution grayscale frames
- diff: `absdiff(frame[i], frame[i + 1])`
- first threshold: `30`
- accumulate thresholded motion as floats
- normalize accumulator to `0...255`
- second threshold: `50`
- choose the largest external motion region
- use full frame width for the returned original and refined windows
- refine by trimming `floor(height * 0.1)` from top and bottom

## Planned Tests

- `swift test` in `apps/ios-native/Packages/PicsewAlgorithm`
  - existing baseline test
  - synthetic motion-band window detection test
  - real sample-video integration test via `PicsewMedia`
- additive repo validation:
  - `npm run lint`
  - `npm run typecheck`
  - `npm run build`

## Risks

- Connected-component detection must stay aligned with the contour-based intent of the TypeScript version.
- Frame-timing and resampling differences between native extraction and browser extraction can shift the exact real-video window numbers, so early integration tests should assert stable in-bounds behavior while exact parity is calibrated in a later pass.

## Rollback

- This phase only changes the native algorithm package and can be reverted independently of the web app and media package.

## Implementation Checklist

- [ ] Add a phase-3B architecture document.
- [ ] Add scrolling-window result types to `PicsewAlgorithm`.
- [ ] Add a detector that consumes `PicsewMedia` grayscale frames.
- [ ] Add synthetic window tests.
- [ ] Add real sample-video window tests.
