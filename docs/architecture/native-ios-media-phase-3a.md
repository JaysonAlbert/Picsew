---
status: approved
---

# Native iOS Media Phase 3A

## TL;DR

Phase 3A ports the first real runtime segment of the pipeline to Swift: video metadata loading and low-resolution grayscale frame extraction. The implementation should match the current TypeScript baseline behavior of sampling at `6 fps`, capping extraction at `480` frames, and resizing each extracted frame to `0.5x` before grayscale conversion. This phase stops before scrolling-window detection, keyframe selection, or stitching.

## Terms

- Metadata phase: Reading display width, display height, duration, frame interval, and target frame count from a video asset.
- Low-resolution frame: A frame resized to half resolution and converted to grayscale to support later analysis stages.
- Reference cadence: The current TypeScript timing behavior of sampling frames at `1 / 6` second intervals.

## Problem

The native iOS foundation exists, but it does not yet run any real media pipeline logic. The next safe migration step is to port the earliest stages of the current TypeScript pipeline:

- read video metadata
- calculate target extraction count
- extract frames at the same cadence as the web implementation
- produce half-scale grayscale frames for downstream analysis

Without this step, the native migration remains architectural only and cannot begin validating algorithm parity on real inputs.

## Scope

### In scope

- Add a real AVFoundation-based metadata loader in `PicsewMedia`.
- Add a real frame extractor using the current sampling cadence.
- Convert extracted frames to half-scale grayscale buffers.
- Add package tests that exercise the implementation against the repository sample video.

### Out of scope

- Scrolling-window detection
- Keyframe selection
- Offset calculation
- Stitching
- Any algorithm behavior change beyond the metadata and low-resolution extraction stages

## Acceptance Criteria

- [ ] AC-01: [P0] The native media package can load video display size and duration from a real sample video.
  - Given the repository sample `test-video.mp4`
  - When the Swift metadata loader reads it
  - Then it returns the display width, display height, frame interval, and computed target frame count expected from the TypeScript baseline
- [ ] AC-02: [P0] The native media package can extract low-resolution grayscale frames from a real sample video.
  - Given the same sample video
  - When the Swift extractor samples the first few frames at the reference cadence
  - Then it returns grayscale buffers whose dimensions match half of the oriented display size
- [ ] AC-03: [P1] The package tests cover both metadata loading and low-resolution extraction against real input.

## Design

### ADR-001

- Status: Accepted
- Context: The earliest pipeline stages are easiest to port without risking downstream algorithm drift.
- Decision: Implement metadata loading and low-resolution grayscale extraction first, using AVFoundation and CoreGraphics while preserving the current TypeScript cadence and frame-count rules.

#### Alternatives

| Option                                            | Pros                                                  | Cons                                            | Conclusion |
| ------------------------------------------------- | ----------------------------------------------------- | ----------------------------------------------- | ---------- |
| Start by porting the full pipeline end-to-end     | Faster path to a demo                                 | Too much surface area for the first parity step | Rejected   |
| Port metadata and low-resolution extraction first | Clear parity boundary, easy to test with sample media | Does not yet produce a stitched result          | Accepted   |

#### Consequences

- We get a real native pipeline foothold without touching later algorithm stages.
- The next migration phase can depend on already validated grayscale frames.
- Real sample-video tests become part of the native media package contract.

## Reference behavior

This phase mirrors the current TypeScript logic in `/Volumes/data/Projects/Picsew/src/lib/picsew.ts`:

- frame rate: `6 fps`
- frame interval: `1 / 6` seconds
- target frame count: `min(floor(duration * 6), 480)`
- resize scale: `0.5`
- conversion: grayscale after resize

## Planned Tests

- `swift test` in `apps/ios-native/Packages/PicsewMedia`
  - metadata read test using `test-video.mp4`
  - low-resolution grayscale extraction test using `test-video.mp4`
- existing additive validation:
  - `npm run lint`
  - `npm run typecheck`
  - `npm run build`

## Risks

- AVFoundation display size handling must respect video orientation, or native dimensions will drift from the web baseline.
- Real media tests add a dependency on the repository sample file path, so the test helper must locate it robustly.

## Rollback

- This phase is additive to `apps/ios-native/Packages/PicsewMedia` and can be reverted without affecting the web app or other native packages.

## Implementation Checklist

- [ ] Add a phase-3A architecture document.
- [ ] Add metadata and low-resolution frame models to `PicsewMedia`.
- [ ] Implement AVFoundation metadata loading with oriented display size.
- [ ] Implement `6 fps` grayscale frame extraction with `0.5x` resize.
- [ ] Add real sample-video tests for metadata and grayscale frame extraction.
