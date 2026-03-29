---
status: approved
---

# Native iOS Foundation Phase 2

## TL;DR

Phase 2 establishes the native iOS engineering foundation inside `apps/ios-native/` without yet porting the stitching algorithm. The goal is to create a stable module layout that supports a future Swift app target and lets us migrate algorithm, media, and UI code independently. This phase should produce compileable Swift packages and clear ownership boundaries, while the current web app and Capacitor shell remain untouched as runtime paths.

## Terms

- Foundation phase: The first native-code phase where module boundaries, package manifests, and starter source trees are created.
- App target: The future native iOS executable target that will compose packages and feature modules.
- Package boundary: A Swift package or target line that keeps concerns separated and testable.

## Problem

Phase 1 defined the repository shape, but `apps/ios-native/` is still mostly empty. Without real Swift modules:

- Native migration work has no compileable home.
- Algorithm, media, and UI code would be at risk of getting mixed together too early.
- Future iOS work would drift back into the transitional Capacitor shell instead of building the native product.

## Scope

### In scope

- Define the native iOS module map for the first compileable foundation.
- Create Swift package manifests for `PicsewAlgorithm`, `PicsewMedia`, and `PicsewDesignSystem`.
- Add minimal source and test targets so the packages build cleanly.
- Add starter app-side Swift source structure under `apps/ios-native/PicsewApp/`.
- Update governance docs to steer new native work into the new structure.

### Out of scope

- Creating the final Xcode app project in this phase.
- Porting algorithm logic from TypeScript to Swift in this phase.
- Replacing the current Capacitor shell in this phase.
- Changing production website behavior or deployment in this phase.

## Acceptance Criteria

- [ ] AC-01: [P0] `apps/ios-native/Packages/` contains compileable Swift packages for algorithm, media, and design system concerns.
  - Given a developer opens the repository after phase 2
  - When they run package-level Swift tests
  - Then each planned native module already has a manifest, source target, and test target
- [ ] AC-02: [P0] The native app-side source tree contains explicit placeholders for app composition and feature slices.
  - Given a developer starts native implementation work
  - When they inspect `apps/ios-native/PicsewApp/`
  - Then they can see where app wiring, features, resources, and support code belong
- [ ] AC-03: [P0] The repository rules steer future native work into the new package boundaries instead of the transitional Capacitor path.
  - Given a follow-up native iOS task
  - When a developer reads the repository guidance
  - Then the preferred implementation path is unambiguous
- [ ] AC-04: [P1] The new native foundation can be validated locally with Swift tooling.

## Design

### ADR-001

- Status: Accepted
- Context: Native iOS code needs a durable home before we start porting the real pipeline.
- Decision: Start with local Swift packages for algorithm, media, and design system, plus a lightweight app source tree for future composition.

#### Alternatives

| Option                                                      | Pros                                                      | Cons                                                    | Conclusion |
| ----------------------------------------------------------- | --------------------------------------------------------- | ------------------------------------------------------- | ---------- |
| Put all Swift code under one future app target              | Fast to start                                             | Encourages tight coupling and harder parallel migration | Rejected   |
| Start with local Swift packages and a thin future app layer | Clear boundaries, better testing, easier staged migration | Slightly more setup up front                            | Accepted   |

#### Consequences

- Native work can begin before the final app project exists.
- Package tests can validate core modules independently.
- The future app target will act more like a composition layer than a dumping ground.

### Module map

```text
apps/ios-native/
  PicsewApp/
    App/
    Features/
      Upload/
      Processing/
      Preview/
      Feedback/
      Onboarding/
    Resources/
    Support/
  Packages/
    PicsewAlgorithm/
    PicsewMedia/
    PicsewDesignSystem/
```

### Package responsibilities

- `PicsewAlgorithm`
  - pipeline types
  - stitching stage interfaces
  - future Swift port of reference logic
- `PicsewMedia`
  - video metadata
  - frame extraction contracts
  - import/export helpers
- `PicsewDesignSystem`
  - colors, spacing, typography
  - reusable SwiftUI primitives
  - status and action components

### App-side responsibilities

- `App/`
  - app bootstrap
  - root navigation model
  - dependency assembly
- `Features/`
  - screen- or flow-specific view models and views
- `Resources/`
  - localization, assets, future app config
- `Support/`
  - app-only adapters, previews, and development helpers

## Planned Tests

- `swift test` inside each package:
  - `PicsewAlgorithm`
  - `PicsewMedia`
  - `PicsewDesignSystem`
- Existing repo validation to ensure the phase stays additive:
  - `npm run lint`
  - `npm run typecheck`
  - `npm run build`

## Risks

- Without a final app target yet, some native files will still be placeholders in this phase.
- Over-designing abstractions now would slow down the first real algorithm port, so the starter APIs should stay intentionally small.

## Rollback

- This phase is additive. The new native package skeleton can be reverted without affecting the live web app or the transitional Capacitor shell.

## Implementation Checklist

### Phase 2

- [ ] Add a phase-2 architecture document under `docs/architecture/`.
- [ ] Create compileable `Package.swift` manifests for `PicsewAlgorithm`, `PicsewMedia`, and `PicsewDesignSystem`.
- [ ] Add minimal source files and tests for each package.
- [ ] Replace placeholder-only app directories with feature-level starter files and READMEs where useful.
- [ ] Update `AGENTS.md` to direct new native work into the new packages and app source tree.
