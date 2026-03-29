---
status: approved
---

# Native iOS Keyframes Phase 3C

## TL;DR

Phase 3C ports candidate keyframe selection to Swift. It consumes the low-resolution grayscale frames from `PicsewMedia` and the refined scrolling window from `PicsewAlgorithm`, then reproduces the current chunk-by-chunk accumulated-offset logic used by the TypeScript baseline. This phase stops at candidate selection and leaves interruption filtering for the next stage.

## Terms

- Candidate keyframe: A frame chosen when accumulated positive scroll since the last chosen keyframe exceeds half of the refined window height.
- Template strip: The middle-quarter vertical slice taken from the last frame in the current chunk.
- Match score: The normalized similarity score used to decide whether a template match is reliable enough to contribute scroll offset.

## Problem

The native pipeline can now:

- read metadata
- extract low-resolution grayscale frames
- detect the refined scrolling window

But it still cannot choose candidate keyframes, which means the later steps remain blocked:

- interruption filtering
- offset calculation
- final stitching

Keyframe selection is the next natural migration stage because it depends only on the pieces we have already ported.

## Scope

### In scope

- Port candidate keyframe selection to `PicsewAlgorithm`.
- Reproduce the current TypeScript behavior:
  - work in low resolution
  - use the refined window scaled down to low-res coordinates
  - extract the center-quarter template from the previous frame in the chunk
  - slide that template vertically through the current frame's refined window
  - accumulate only positive offsets when the match score exceeds `0.7`
  - emit a new candidate once accumulated offset exceeds `50%` of the refined window height
  - always include frame `0` and the final frame
- Add synthetic and sample-video tests.

### Out of scope

- Interruption filtering
- Final clean keyframe set
- Offset calculation
- Stitching

## Acceptance Criteria

- [ ] AC-01: [P0] The native algorithm package selects candidate keyframes from a synthetic scrolling sequence using the same accumulated-offset rule as the web baseline.
  - Given synthetic low-resolution grayscale frames whose content shifts upward by a known amount
  - When the Swift selector runs
  - Then it emits the expected candidate indices including frame `0` and the last frame
- [ ] AC-02: [P0] The selector works end-to-end on the repository sample video using native extracted frames and native window detection.
  - Given `test-video.mp4`
  - When the native media and algorithm pipeline runs through keyframe selection
  - Then it returns a stable, ordered set of candidate indices beginning at `0` and ending at the last extracted frame
- [ ] AC-03: [P1] The keyframe selector remains separate from later interruption filtering logic.

## Design

### ADR-001

- Status: Accepted
- Context: The web implementation relies on OpenCV template matching, but the early native migration should stay dependency-light and reuse the low-resolution grayscale buffers already produced in Swift.
- Decision: Implement vertical template matching with normalized cross-correlation in pure Swift, limited to the refined scrolling window.

#### Alternatives

| Option                                                           | Pros                                                              | Cons                                               | Conclusion |
| ---------------------------------------------------------------- | ----------------------------------------------------------------- | -------------------------------------------------- | ---------- |
| Add native OpenCV or Vision immediately                          | Familiar matching primitive                                       | Extra integration cost and more moving parts early | Rejected   |
| Use pure Swift normalized cross-correlation on grayscale buffers | Lightweight and easy to test against current pipeline assumptions | More manual math                                   | Accepted   |

#### Consequences

- The selector can be tested with synthetic data without extra native dependencies.
- If later profiling shows this stage is too slow, optimization can happen without changing the public algorithm boundary.

## Reference behavior

This phase mirrors the current TypeScript logic in `/Volumes/data/Projects/Picsew/src/lib/picsew.ts`:

- initial candidates: `[0]`
- use the refined window scaled to low resolution
- template height: `floor(height / 4)`
- template vertical start: `y + floor(height / 2) - floor(templateHeight / 2)`
- match threshold: `0.7`
- accumulate only positive offsets
- select a new candidate when accumulated offset exceeds `height * 0.5`
- append the final frame if not already selected

## Planned Tests

- `swift test` in `apps/ios-native/Packages/PicsewAlgorithm`
  - synthetic candidate-selection test
  - sample-video integration test
- additive repo validation:
  - `npm run lint`
  - `npm run typecheck`
  - `npm run build`

## Risks

- Pure Swift correlation can be slower than future optimized implementations, so tests should focus on correctness and stable boundaries first.
- Exact candidate counts on real videos can shift slightly as earlier native parity is tightened, so the sample-video test should assert stable ordering and endpoints unless a fully locked parity baseline exists.

## Rollback

- This phase only changes the native algorithm package and can be reverted independently of the web app and media package.

## Implementation Checklist

- [ ] Add a phase-3C architecture document.
- [ ] Add keyframe-selection result and error types to `PicsewAlgorithm`.
- [ ] Implement native candidate keyframe selection using low-resolution grayscale frames and the refined window.
- [ ] Add synthetic candidate-selection tests.
- [ ] Add sample-video integration tests.
