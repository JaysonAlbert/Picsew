---
status: approved
---

# Native iOS UI Polish Phase 8

## TL;DR

The native app can now import, process, save, and share, but the shell still reads like an engineering prototype rather than a finished iOS utility app. Phase 8 redesigns the native SwiftUI shell around one compact top bar, one minimal three-dot progress indicator, one main stage card per screen, and sticky bottom actions where they matter. The goal is to make the upload, processing, preview, and onboarding flows feel cohesive, full-height, and intentionally native without changing the algorithm pipeline.

## Problem

The current native app has the right functionality but weak visual hierarchy:

- the default navigation title and toolbar still feel generic
- upload, processing, and preview do not share one clear shell language
- onboarding appears as a medium sheet instead of a real first-run experience
- actions and supporting details compete for attention
- the screen flow does not yet look like a polished single-purpose iOS app

Because the product is intentionally simple, the UI should not explain itself repeatedly. It should guide the user once, then keep each screen focused on one job.

## Scope

### In scope

- replace the default navigation chrome with a custom native shell
- add a compact three-dot progress indicator for upload, processing, and preview
- redesign the upload screen around one import stage and one primary CTA
- redesign the processing screen around one centered progress stage
- redesign the preview screen around one preview stage and a sticky export bar
- make onboarding a full-screen first-run experience
- keep the feedback route visually consistent with the new shell
- add a small testable route-presentation layer for shell metadata

### Out of scope

- algorithm changes
- new backend behavior
- native feedback submission plumbing
- advanced editing controls
- App Store marketing polish

## Design

### ADR-001

- Status: Accepted
- Context: The app already works functionally, but each route currently renders itself in isolation and falls back to generic `NavigationStack` chrome.
- Decision: Introduce a shared native shell scaffold that owns top chrome, progress dots, background treatment, and stage spacing, while feature views only provide their main content and bottom actions.

#### Alternatives

| Option                                                         | Pros                                          | Cons                                                                           | Conclusion |
| -------------------------------------------------------------- | --------------------------------------------- | ------------------------------------------------------------------------------ | ---------- |
| Keep each screen fully independent and tweak styles locally    | Fast small edits                              | Repeats layout logic and produces inconsistent spacing/chrome                  | Rejected   |
| Add one shared shell scaffold and keep feature content focused | Consistent hierarchy and easier future polish | Requires a small refactor across all feature views                             | Accepted   |
| Use `TabView` or standard navigation bars for the three stages | Familiar platform primitive                   | Overstates the complexity of the workflow and keeps too much persistent chrome | Rejected   |

### Shell structure

The native app should use this structure for the primary product journey:

```text
Top utility bar
Minimal three-dot stage indicator
Main stage card / canvas
Sticky bottom action area (when the route has primary actions)
```

Key rules:

- one dominant task per screen
- one primary call to action per route
- supporting metadata stays secondary and compact
- the top bar should feel branded but lightweight

### Route presentation

Each main route will expose:

- title
- subtitle
- active journey step
- whether the three-dot indicator is visible

That metadata will be used by the shared shell scaffold and also unit-tested so route semantics do not drift during later UI work.

### Screen decisions

#### Upload

- compact top bar plus journey dots
- one hero stage card with import actions
- selected-video details remain visible but compact
- bottom sticky primary CTA: `Start Processing`
- no duplicate large product branding inside the content area

#### Processing

- compact top bar plus journey dots
- one centered processing stage card
- subtle progress line plus current stage name
- no extra cards, no secondary buttons

#### Preview

- compact top bar plus journey dots
- one main preview card
- concise success label and small technical summary
- sticky export bar with `Save to Photos`, `Share`, and a lighter restart action

#### Onboarding

- full-screen cover instead of medium detent sheet
- one concise welcome headline
- three short steps
- one clear continue button

## Acceptance Criteria

- [ ] AC-01: [P0] Upload, processing, and preview share a consistent custom shell with a compact top bar and a minimal three-dot route indicator.
  - **Given**: the native app is running on iOS
  - **When**: the user moves across upload, processing, and preview
  - **Then**: each route uses the same shell language and highlights the active step with the compact dot indicator
- [ ] AC-02: [P0] The upload and preview routes provide full-height layouts with one dominant stage and a bottom action area.
  - **Given**: the app is shown on an iPhone-sized viewport
  - **When**: the user views the upload or preview route
  - **Then**: the route fills the available height and the main action is visually anchored near the bottom safe area
- [ ] AC-03: [P0] Onboarding is presented full-screen and no longer uses a partial-height sheet.
  - **Given**: the app launches for the first time
  - **When**: onboarding appears
  - **Then**: it covers the full screen with one focused welcome flow
- [ ] AC-04: [P1] Route presentation metadata is covered by automated tests so the shared shell keeps the intended titles and active-step semantics.

## Planned Tests

- `swift test` in `apps/ios-native/PicsewApp`
  - add route-presentation tests for title and active-step mapping
- `swift test` in `apps/ios-native/Packages/PicsewMedia`
- `swift test` in `apps/ios-native/Packages/PicsewAlgorithm`
- `swift test` in `apps/ios-native/Packages/PicsewAppCore`
- `xcodebuild -project apps/ios-native/HostApp/PicsewNativeApp.xcodeproj -scheme PicsewNativeApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `npm run lint`
- `npm run typecheck`
- `npm run build`

## Risks

- UI-only polish can easily become broad and subjective, so this phase must keep the scope focused on shell structure rather than endless visual tuning.
- Introducing a shared shell means feature screens need to stop owning their own top-level spacing and navigation assumptions.
- Some preview-heavy UI is harder to regression test automatically, so the route-presentation layer should stay small and deterministic.

## Rollback

This phase is mostly a SwiftUI composition refactor. The app can return to the older layout by restoring the previous route views and removing the shared shell scaffold without affecting the native processing pipeline.
