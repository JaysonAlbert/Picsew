---
status: approved
---

# Native iOS System Integration Phase 7

## TL;DR

The native host app can now launch the SwiftUI shell, but it still cannot import a real video, save a stitched image, or share an export. Phase 7 wires the SwiftUI shell to iOS system capabilities while keeping algorithm execution inside the native pipeline packages and platform-specific file/export behavior inside the host app. The result should be the first end-to-end native user flow: import video, process, preview, save, and share.

## Problem

The current native app stack includes:

- a buildable native host app target
- a compileable SwiftUI shell package
- a fully wired native processing pipeline

What it still lacks is the bridge to real iOS app behavior. Today the app can only process a URL that is injected manually into the shell model, which means:

- there is no Photos picker flow
- there is no Files importer flow
- there is no save-to-Photos action
- there is no share action for the generated long screenshot

Without those pieces, the app is technically running but still not usable as a real iOS product.

## Scope

### In scope

- add a native system client abstraction for import and export actions
- wire the upload screen to Files import
- wire the upload screen to Photos import on iOS
- wire the preview screen to save the stitched image to Photos
- wire the preview screen to share a generated export file
- add host-app photo-library usage metadata required for export
- add app-level tests for the new shell-model behaviors
- validate the host app with an `xcodebuild` simulator build

### Out of scope

- large-scale UI redesign
- native feedback submission
- background processing
- replacing the web feedback backend
- algorithm changes

## Design

### ADR-001

- Status: Accepted
- Context: The app package needs import/save/share behavior, but those operations depend on iOS platform APIs and file-system ownership rules that should not live inside the algorithm packages.
- Decision: Introduce a host-provided system client that the SwiftUI shell uses for import/export operations, while keeping processing logic in `PicsewAppCore`.

#### Alternatives

| Option                                                               | Pros                                   | Cons                                                                                    | Conclusion |
| -------------------------------------------------------------------- | -------------------------------------- | --------------------------------------------------------------------------------------- | ---------- |
| Put Photos and file-system logic directly into `PicsewAppShellModel` | Fewer types                            | Couples the reusable app package to host-only platform behavior                         | Rejected   |
| Put all import/export behavior into `PicsewAppCore`                  | Central pipeline package               | `PicsewAppCore` should stay focused on processing orchestration, not app UX integration | Rejected   |
| Add a host-provided system client used by the shell model            | Keeps boundaries explicit and testable | Requires one extra integration type                                                     | Accepted   |

### Host boundary

The shell model will use a `PicsewSystemClient` to perform:

- file-based video import
- data-based video import from Photos picker results
- save-to-Photos export
- share-file preparation

The host app will supply the live implementation. The app package will depend only on the interface.

### Import flow

Files import:

1. SwiftUI presents `fileImporter`.
2. The selected file URL is passed to the shell model.
3. The system client copies the file into an app-owned temporary location.
4. The shell model stores the imported URL as the active input video.

Photos import:

1. SwiftUI presents `PhotosPicker`.
2. The selected movie asset is loaded as a temporary file representation.
3. The shell model passes the imported file URL to the same system-client import path.
4. The imported URL becomes the active input video.

Using one normalized imported-file path keeps the processing pipeline unchanged.

### Export flow

Preview export adds two behaviors:

- `Save to Photos`: encode the stitched image as PNG and write it to the photo library
- `Share`: encode the stitched image as PNG, persist it to a temporary file, and expose that file URL to `ShareLink`

The shell model will cache the prepared share URL for the current result and clear it when a new import starts.

## Acceptance Criteria

- [ ] AC-01: [P0] On iOS, the upload screen exposes both Files import and Photos import actions that update the selected video state through the shell model.
  - **Given**: the native host app is running on iOS and no video is selected
  - **When**: the user imports a valid video from Files or Photos
  - **Then**: the shell model stores an app-owned local file URL and enables processing
- [ ] AC-02: [P0] The preview screen exposes a working save action and a working share action for a generated stitched image.
  - **Given**: the native pipeline has produced a stitched image
  - **When**: the user taps save or share
  - **Then**: save writes to Photos and share exposes a temporary PNG file URL
- [ ] AC-03: [P0] The host app declares the required photo-library add usage string for export.
  - **Given**: the host app target is built from `apps/ios-native/HostApp/`
  - **When**: the app attempts to save a stitched image to Photos
  - **Then**: the required Info.plist usage description is present
- [ ] AC-04: [P1] The shell model remains testable with mocked system actions and does not require real iOS UI to validate import/export state changes.

## Planned Tests

- app package tests:
  - imported file selection updates the shell state through the system client
  - share preparation stores a share URL for the current result
  - save-to-Photos delegates to the system client and reports success
  - import errors surface an error message without crashing the shell
- package and repository validation:
  - `swift test` in `apps/ios-native/PicsewApp`
  - `swift test` in `apps/ios-native/Packages/PicsewMedia`
  - `swift test` in `apps/ios-native/Packages/PicsewAlgorithm`
  - `swift test` in `apps/ios-native/Packages/PicsewAppCore`
  - `npm run lint`
  - `npm run typecheck`
  - `npm run build`
- host validation:
  - `xcodebuild -project apps/ios-native/HostApp/PicsewNativeApp.xcodeproj -scheme PicsewNativeApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`

## Risks

- Photos import can produce temporary files with limited lifetimes, so imported assets must be copied into app-owned storage before processing.
- Share and save both require image export encoding, which should remain separated from the algorithm result object itself.
- iOS-only UI code must stay conditionally compiled so package tests can continue running on macOS.

## Rollback

This phase is additive. The host app can fall back to the previous shell behavior by removing the system client wiring and the new import/export buttons without affecting the native algorithm pipeline.
