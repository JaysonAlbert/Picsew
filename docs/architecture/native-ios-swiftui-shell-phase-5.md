---
status: approved
---

# Native iOS SwiftUI Shell Phase 5

## TL;DR

The native processing pipeline is now available through `PicsewAppCore`, but the future iOS app still does not have a compileable SwiftUI shell that can drive that pipeline. Phase 5 turns `apps/ios-native/PicsewApp/` into a compileable Swift package that owns app-only state, routing, and SwiftUI feature views for the upload -> processing -> preview journey.

## Problem

The repository now has:

- low-level media and algorithm packages
- one app-facing orchestration package

What it still lacks is the first native app shell layer that future app targets can embed directly. Right now:

- `PicsewApp/` is still only placeholder files
- upload / processing / preview state is not modeled natively
- there is no app-side route or screen model that consumes `PicsewAppCore`
- the future Xcode app target would still have to invent its own feature wiring

Without a compileable SwiftUI shell, the native app is still missing the product layer between orchestration and the eventual executable target.

## Scope

### In scope

- turn `apps/ios-native/PicsewApp/` into a compileable Swift package
- add app-side route and screen state for upload / processing / preview / feedback
- add a main shell model that drives `PicsewNativeAppPipeline`
- add SwiftUI views for the first app shell
- add a preview adapter that can render `PicsewStitchedImage` as a SwiftUI image
- add tests for route and state transitions using a mock pipeline

### Out of scope

- the final Xcode app project / iOS app bundle target
- Photos picker integration
- save/share/export integration
- full native visual polish pass

## Design

### ADR-001

- Status: Accepted
- Context: The app now needs real product-facing shell code, but creating the final Xcode project in the same step would add a lot of build-system noise.
- Decision: Make `PicsewApp/` a compileable Swift package first, then add the final app target in the next phase.

#### Alternatives

| Option                                                        | Pros                                                                 | Cons                                                                    | Conclusion              |
| ------------------------------------------------------------- | -------------------------------------------------------------------- | ----------------------------------------------------------------------- | ----------------------- |
| Create the final Xcode app target immediately                 | Feels closer to the end product                                      | Mixes project-file work with feature-shell logic and makes review noisy | Rejected for this phase |
| Keep `PicsewApp/` as placeholders until the app target exists | Less setup now                                                       | Delays shell design and leaves no testable app layer                    | Rejected                |
| Make `PicsewApp/` a compileable Swift package first           | Testable shell, cleaner review, easier future app-target integration | One transitional packaging step                                         | Accepted                |

### Responsibilities

`PicsewApp/` will own:

- app navigation state
- app-only shell model
- screen-specific SwiftUI views
- preview adapters from stitched raster output to UI display

It will not own:

- low-level video extraction
- algorithm logic
- export/save integration

### App flow

The shell will model this journey:

1. upload
2. processing
3. preview

Feedback remains a lightweight app route but does not need full backend integration changes in this phase.

### Public surface

The package will expose:

- `PicsewAppShellModel`
- `PicsewRootView`
- `UploadFeatureView`
- `ProcessingFeatureView`
- `PreviewFeatureView`

`PicsewAppShellModel` will:

- hold the selected video URL
- drive route transitions
- call `PicsewNativeAppPipeline`
- store the final stitched result
- expose an error message for the shell

## Acceptance Criteria

- [ ] AC-01: [P0] `apps/ios-native/PicsewApp/` is a compileable Swift package.
- [ ] AC-02: [P0] The shell model can transition from upload to processing to preview using a mock pipeline.
- [ ] AC-03: [P0] The preview route can render a `PicsewStitchedImage` through a SwiftUI-compatible adapter.
- [ ] AC-04: [P1] The shell package can be validated with `swift test`.

## Planned Tests

- `swift test` in `apps/ios-native/PicsewApp`
  - shell transitions to processing and then preview on success
  - shell returns to upload or stays safe on failure
  - progress updates are recorded during execution
- existing repo validation:
  - `swift test` in `PicsewMedia`
  - `swift test` in `PicsewAlgorithm`
  - `swift test` in `PicsewAppCore`
  - `npm run lint`
  - `npm run typecheck`
  - `npm run build`

## Risks

- SwiftUI and shell state can drift into app-target concerns if the package surface gets too broad.
- Rendering the stitched raster in SwiftUI needs a stable RGBA-to-`CGImage` bridge.

## Rollback

This phase is additive. The `PicsewApp` Swift package and shell code can be reverted without affecting the already-migrated native pipeline packages.
