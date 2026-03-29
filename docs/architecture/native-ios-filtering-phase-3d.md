---
status: approved
---

# Native iOS Filtering Phase 3D

## TL;DR

Phase 3D ports candidate keyframe filtering to Swift. It compares each neighboring candidate pair, measures binary grayscale change only outside the scrolling window, and keeps the current candidate only when outside change stays below `1%`, matching the current TypeScript baseline. This phase completes the native low-resolution keyframe-selection chain and stops before offset calculation and stitching.

## Terms

- Clean keyframe: A candidate keyframe that survives outside-window interruption filtering.
- Outside change percentage: The ratio of changed outside-mask pixels to total outside-mask pixels, expressed as a percentage.
- Outside mask: The low-resolution binary mask generated during scrolling-window detection where `255` means outside the scrolling content and `0` means inside it.

## Problem

The native pipeline can now:

- read metadata
- extract low-resolution grayscale frames
- detect the scrolling window
- select candidate keyframes

But it still cannot filter out candidate frames affected by changes outside the scrolling area. Without this step, the native chain stops at noisy candidate selection and cannot match the full low-resolution keyframe flow used by the current web implementation.

## Scope

### In scope

- Port keyframe filtering to `PicsewAlgorithm`.
- Reproduce the current TypeScript behavior:
  - compare neighboring candidate frames
  - compute grayscale absolute difference
  - threshold at `30`
  - count changed pixels only where `outsideMask` is non-zero
  - compute outside change percentage
  - keep the current candidate only if outside change stays below `1%`
  - always preserve the first candidate
- Add synthetic and sample-video tests.

### Out of scope

- Offset calculation
- Stitching
- Final full-resolution export

## Acceptance Criteria

- [ ] AC-01: [P0] The native algorithm package filters synthetic candidate keyframes based on outside-window changes using the same thresholding rule as the web baseline.
  - Given synthetic low-resolution frames and a known outside mask
  - When the Swift filter runs
  - Then it preserves candidates with low outside change and discards candidates with high outside change
- [ ] AC-02: [P0] The filter works end-to-end on the repository sample video after native media extraction, scrolling-window detection, and candidate selection.
  - Given `test-video.mp4`
  - When the native pipeline runs through clean-keyframe filtering
  - Then it returns an ordered subset of the candidate indices beginning with the first candidate
- [ ] AC-03: [P1] Filtering remains a distinct step after candidate selection rather than being folded into matching logic.

## Design

### ADR-001

- Status: Accepted
- Context: The TypeScript implementation uses binary diff + outside-mask counting to remove interruptions without changing the candidate selection step.
- Decision: Keep filtering as a separate pure-Swift pass that operates on low-resolution grayscale frames and the low-resolution outside mask.

#### Alternatives

| Option                                          | Pros                                            | Cons                                                                 | Conclusion |
| ----------------------------------------------- | ----------------------------------------------- | -------------------------------------------------------------------- | ---------- |
| Fold outside filtering into candidate selection | Fewer passes                                    | Couples two different decisions and diverges from the reference flow | Rejected   |
| Keep filtering as a separate pass               | Matches the web baseline and stays easy to test | Slightly more code                                                   | Accepted   |

#### Consequences

- The native algorithm remains aligned with the current web stage boundaries.
- Synthetic tests can target filtering behavior without involving template matching.

## Reference behavior

This phase mirrors the current TypeScript logic in `/Volumes/data/Projects/Picsew/src/lib/picsew.ts`:

- input: candidate keyframe indices, low-resolution grayscale frames, outside mask
- diff: `absdiff(gray1, gray2)`
- threshold: `30`
- count changed pixels only where `outsideMask > 0`
- outside change percentage: `(changedOutsidePixels / totalOutsidePixels) * 100`
- keep the current candidate if outside change percentage is `< 1`

## Planned Tests

- `swift test` in `apps/ios-native/Packages/PicsewAlgorithm`
  - synthetic filtering test
  - sample-video integration test
- additive repo validation:
  - `npm run lint`
  - `npm run typecheck`
  - `npm run build`

## Risks

- Real-video clean keyframe counts can shift as earlier native parity is tightened, so the sample-video test should assert stable ordering and subset behavior rather than overfit exact counts too early.

## Rollback

- This phase only changes the native algorithm package and can be reverted independently of the web app and media package.

## Implementation Checklist

- [ ] Add a phase-3D architecture document.
- [ ] Add clean-keyframe filtering result and error types to `PicsewAlgorithm`.
- [ ] Implement native outside-mask filtering for candidate keyframes.
- [ ] Add synthetic filtering tests.
- [ ] Add sample-video integration tests.
