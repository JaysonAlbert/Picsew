---
status: approved
---

# Native iOS Automation Validation Phase 9

## TL;DR

The native iOS app now needs a stable automation surface, not just working product code. Phase 9 adds deterministic launch scenarios, accessibility identifiers for key controls, and a repository-owned Maestro workspace so agents and developers can drive the app, capture screenshots, and verify screen structure without depending on fragile system pickers. This phase is intentionally focused on automation foundations rather than expanding product scope.

## Problem

The native app can already import, process, preview, save, and share, and the shell UI has entered a polish pass. What it still lacks is a reliable way for an agent or a CI job to:

- launch the app into a known visual state
- inspect and tap stable UI targets
- capture screenshots for upload, processing, preview, feedback, and onboarding
- verify shell structure without manually stepping through Photos or Files pickers

Today the app has package-level logic tests, but no deterministic automation entry points and no mobile test workspace for visual validation. That leaves a gap between "the feature works on my simulator" and "the app can be verified automatically and repeatedly."

## Scope

### In scope

- add launch-time automation scenarios for stable screenshot and smoke-test states
- provide reusable fixture data for upload, processing, preview, feedback, and onboarding automation
- add accessibility identifiers to shell-level and feature-level UI controls used by automation
- add a repository-owned Maestro workspace with initial smoke and screenshot flows
- add a helper script for building and installing the host app on a booted simulator
- add package tests that cover automation scenario parsing and fixture state wiring

### Out of scope

- full XCUITest target implementation
- App Store screenshot framing and localization matrices
- real Files or Photos picker automation
- visual baseline approval workflow in CI
- algorithm changes

## Design

### ADR-001

- Status: Accepted
- Context: Maestro and future XCUITest coverage need a deterministic way to reach key screens, but the current app flow depends on user-driven import and asynchronous processing.
- Decision: Add launch-time automation scenarios that bootstrap the app into stable fixture-backed states while leaving the normal product flow unchanged.

#### Alternatives

| Option                                                  | Pros                                            | Cons                                                                          | Conclusion              |
| ------------------------------------------------------- | ----------------------------------------------- | ----------------------------------------------------------------------------- | ----------------------- |
| Drive real Photos and Files pickers in every smoke test | Exercises true system integration               | Slow, fragile, permission-heavy, and hard for agent-driven screenshot capture | Rejected                |
| Build only XCUITest first                               | Strong Apple-native foundation                  | Slower to author and less convenient for agent-driven visual exploration      | Rejected for this phase |
| Add deterministic launch scenarios plus Maestro flows   | Fast, stable, and easy for agents and CI to use | Requires explicit automation-only wiring                                      | Accepted                |

### Automation scenario model

The host app will inspect launch arguments and support these scenarios:

- `onboarding`
- `upload`
- `processing`
- `preview`
- `feedback`

Each scenario will:

- disable onboarding unless the scenario is explicitly `onboarding`
- inject a fixed shell state without depending on user input
- use fixture-backed URLs, progress values, and stitched-image results

This keeps the automation surface deterministic while preserving the real user flow for normal launches.

### Accessibility contract

Phase 9 establishes the first stable native automation selector contract. The following areas must expose identifiers:

- shell route container
- shell utility action
- onboarding screen and continue CTA
- upload source buttons and primary CTA
- processing stage container
- preview image, save CTA, share CTA, and restart CTA
- feedback placeholder route

Identifiers should be static, English, and independent from localized copy so Maestro and future XCUITest selectors remain stable during UI wording changes.

### Maestro workspace

The repository will add a dedicated workspace under `apps/ios-native/maestro/` containing:

- a shared `config.yaml`
- one smoke flow for the preview route
- one screenshot flow per major shell state
- lightweight README or command guidance for local execution

This workspace becomes the first-class home for agent-driven mobile validation.

### Helper script

A helper script will build the host app for a booted simulator, install it, and prepare the app for Maestro flows. This avoids forcing every developer or agent to remember the `xcodebuild` + `simctl install` sequence.

## Acceptance Criteria

- [ ] AC-01: [P0] The native host app can launch directly into deterministic automation states for onboarding, upload, processing, preview, and feedback.
  - **Given**: the host app is launched with a supported automation scenario argument
  - **When**: the app finishes launch
  - **Then**: the shell opens in the matching fixture-backed state without requiring manual import or processing
- [ ] AC-02: [P0] Maestro can locate and assert the key controls on the preview route using stable accessibility identifiers.
  - **Given**: the preview automation scenario is launched
  - **When**: a Maestro smoke flow runs against the app
  - **Then**: it can verify the route, stitched preview, and export actions without relying on localized text selectors
- [ ] AC-03: [P0] The repository contains a repeatable command path for installing the host app on a booted simulator and running initial Maestro flows.
  - **Given**: a booted iOS simulator and the required local tooling are available
  - **When**: the documented build/install command is run
  - **Then**: the app is installed and ready for Maestro execution
- [ ] AC-04: [P1] Automation scenario parsing and fixture wiring are covered by package tests so later UI polish does not silently break the automation entry points.

## Planned Tests

- `swift test` in `apps/ios-native/PicsewApp`
  - automation scenario parsing from launch arguments
  - automation model fixtures for preview and onboarding behavior
- `xcodebuild -project apps/ios-native/HostApp/PicsewNativeApp.xcodeproj -scheme PicsewNativeApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- optional local smoke when tooling is available:
  - build/install helper script against a booted simulator
  - `maestro test apps/ios-native/maestro/flows/smoke-preview.yaml`

## Risks

- Automation-only state wiring can leak into production behavior if not clearly isolated to launch arguments.
- Visual validation becomes brittle if selectors depend on localized copy instead of identifiers.
- A booted simulator is required for Maestro execution, so CI and local developer workflows need clear setup expectations.

## Rollback

This phase is additive. The app can fall back to normal launch behavior by removing the automation scenario parsing, deleting the Maestro workspace, and keeping the core shell UI untouched.

## Implementation Checklist

> Phase 1: Documentation and launch scaffolding

- [ ] Add `docs/architecture/native-ios-automation-validation-phase-9.md`
- [ ] Add automation scenario parsing and fixture-backed launch support in the native app

> Phase 2: Automation selectors

- [ ] Update shell and feature views with stable accessibility identifiers for smoke and screenshot flows

> Phase 3: Maestro workspace

- [ ] Add `apps/ios-native/maestro/config.yaml`
- [ ] Add initial smoke and screenshot flows under `apps/ios-native/maestro/flows/`
- [ ] Add a helper install script for a booted simulator

> Phase 4: Validation

- [ ] Add or update `PicsewApp` package tests for automation parsing and fixture state
- [ ] Run Swift package validation and simulator build validation
