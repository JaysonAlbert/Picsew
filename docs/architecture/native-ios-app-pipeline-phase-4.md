---
status: approved
---

# Native iOS App Pipeline Phase 4

## TL;DR

The core native media and algorithm packages now cover the reference pipeline end to end, but the iOS app still lacks a single app-facing entry point that coordinates those packages. Phase 4 introduces a dedicated native app-core package that composes metadata loading, low-resolution analysis, keyframe filtering, full-resolution decoding, offset calculation, and final stitching into one callable pipeline for the future SwiftUI app.

## Problem

`PicsewMedia` and `PicsewAlgorithm` are now mature enough to run the reference flow, but they are still exposed as low-level building blocks:

- the app layer would need to know the exact order of all pipeline stages
- progress reporting would be scattered across multiple calls
- feature code would risk duplicating orchestration logic
- the future native app target would not yet have a stable boundary for video processing

Without an orchestration layer, the native app cannot yet treat the reference pipeline as a cohesive product feature.

## Scope

### In scope

- add a new local Swift package for app-facing native pipeline composition
- expose one high-level `run(videoURL:)` entry point for the full processing pipeline
- define progress and result types that are stable for future SwiftUI consumption
- test the orchestration against the sample video fixture
- update repository rules so app-side composition prefers the new package

### Out of scope

- creating the final Xcode app target
- implementing the final SwiftUI screens in this phase
- save/share/export UI work
- changing the migrated algorithm behavior

## Design

### ADR-001

- Status: Accepted
- Context: The native app needs one stable boundary that can be called from feature code without teaching every screen how the underlying pipeline works.
- Decision: Add `PicsewAppCore`, a local Swift package that depends on `PicsewMedia` and `PicsewAlgorithm` and owns end-to-end processing orchestration.

#### Alternatives

| Option                                              | Pros                                                        | Cons                                                         | Conclusion |
| --------------------------------------------------- | ----------------------------------------------------------- | ------------------------------------------------------------ | ---------- |
| Orchestrate directly inside future SwiftUI features | Fast to start                                               | Duplicates pipeline knowledge in UI and makes testing harder | Rejected   |
| Put orchestration into `PicsewAlgorithm`            | Keeps fewer modules                                         | Mixes app workflow concerns into algorithm package           | Rejected   |
| Add a dedicated app-core package                    | Clear app boundary, testable, reusable by future app target | One more package to maintain                                 | Accepted   |

### Package responsibility

`PicsewAppCore` will own:

- end-to-end native processing orchestration
- pipeline progress events for the app
- app-facing result types
- future dependency injection seams for import, save, and share flows

It will not own:

- low-level video decoding details
- algorithm stage implementations
- SwiftUI screen layout

### Public API shape

The package will expose:

- `PicsewAppPipelineStage`
- `PicsewAppPipelineProgress`
- `PicsewAppPipelineResult`
- `PicsewAppPipelineRunning`
- `PicsewNativeAppPipeline`

`PicsewNativeAppPipeline` will call the underlying packages in this order:

1. load metadata
2. extract low-resolution grayscale frames
3. detect scrolling window
4. select candidate keyframes
5. filter clean keyframes
6. extract full-resolution grayscale keyframes
7. calculate offsets
8. extract full-resolution color keyframes
9. stitch final image

## Acceptance Criteria

- [ ] AC-01: [P0] The repository contains a compileable `PicsewAppCore` package under `apps/ios-native/Packages/`.
- [ ] AC-02: [P0] The package exposes one app-facing native pipeline entry point that returns the stitched image plus the key intermediate stage outputs needed by the app.
- [ ] AC-03: [P0] The package reports ordered stage progress suitable for future UI integration.
- [ ] AC-04: [P0] A sample-video test proves the orchestration returns a stitched image whose dimensions match the stitched output produced by the lower-level packages.

## Planned Tests

- `swift test` in `apps/ios-native/Packages/PicsewAppCore`
  - progress stages advance in the expected order
  - sample-video pipeline returns a non-empty stitched output with stable dimensions
- existing repo validation:
  - `npm run lint`
  - `npm run typecheck`
  - `npm run build`

## Risks

- A thin orchestration layer can still become leaky if it exposes too many low-level details.
- If progress types are unstable, future SwiftUI features may end up rewriting around them.

## Rollback

This phase is additive. `PicsewAppCore` can be reverted without affecting the web app or the already-migrated native algorithm packages.
