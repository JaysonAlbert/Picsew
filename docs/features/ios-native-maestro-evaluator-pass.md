---
title: Native iOS Maestro Coverage And Evaluator Pass
issue: ios-native-maestro-evaluator-pass
author: Codex
date: 2026-03-31
updated: 2026-03-31
version: 0.1.0
reviewers: [Jayson Albert]
tags: [ios, native, maestro, ui, validation, design]
source_code:
  - apps/ios-native/HostApp/App/PicsewHostApp.swift
  - apps/ios-native/PicsewApp/Core/PicsewAutomationSupport.swift
  - apps/ios-native/PicsewApp/Core/PicsewAppShell.swift
  - apps/ios-native/PicsewApp/Features/Upload/UploadFeature.swift
  - apps/ios-native/PicsewApp/Features/Processing/ProcessingFeature.swift
  - apps/ios-native/PicsewApp/Features/Preview/PreviewFeature.swift
  - apps/ios-native/PicsewApp/Features/Onboarding/OnboardingFeature.swift
  - apps/ios-native/PicsewApp/Features/Feedback/FeedbackFeature.swift
  - apps/ios-native/PicsewApp/Tests/PicsewAppTests/PicsewAppTests.swift
  - apps/ios-native/maestro/config.yaml
  - apps/ios-native/maestro/flows
  - scripts/ios-native/install-host-app-on-booted-sim.sh
status: approved
---

# Native iOS Maestro Coverage And Evaluator Pass

## Summary

- **Problem**: The native iOS shell already has route-level smoke coverage, but it does not yet prove the end-to-end demo flow, error states, or evaluator-required screenshot evidence for all key states.
- **Goal**: Add repository-owned Maestro coverage for the full native journey, use seeded demo videos from the repository root for real processing validation, and tighten the UI so upload, processing, preview, onboarding, and feedback pass the Picsew iOS design evaluator with no hard-gate failures.
- **Scope**:
  - add deterministic automation hooks for seeded demo videos and route/state setup
  - expand Maestro flows from static route snapshots to scenario coverage
  - refine native UI hierarchy so each route has one dominant stage and one clear action area
  - capture fresh screenshots from the current branch for affected routes and states
  - keep the native algorithm behavior and route order unchanged

## Problem

### Current issues

1. Maestro currently proves only one smoke preview flow and a small set of static capture routes.
2. The current automation setup does not cover the real upload -> processing -> preview path with repository demo videos.
3. Upload, preview, and feedback still carry secondary details that compete with the main stage or feel under-specified during review.
4. Evaluator-required evidence is incomplete because empty, loading, completed, and supporting route states are not all captured freshly from the current branch.
5. Functional confidence is weaker than it should be for handoff because the automated route coverage does not yet exercise save/share success messaging or failure surfaces in a deterministic way.

### Out of scope

- changing the algorithm behavior relative to the TypeScript baseline
- new product routes or new business features
- release metadata, signing, or store-prep work
- web maintenance-surface changes

## Design Choice

### ADR-001: Use launch-argument driven native automation with seeded demo assets

**Status**: Accepted

**Decision**:

- Keep the host app as the automation entry point.
- Extend the native automation configuration so Maestro can request:
  - fixture-backed static review states
  - seeded demo-video flows that exercise the real native pipeline
  - deterministic exporter behavior for save/share assertions
- Seed demo files from the repository root into the simulator app container before Maestro runs.

**Why**:

- This keeps functional validation repository-owned and repeatable.
- It avoids brittle Files or Photos picker automation for the main happy path.
- It lets us separate UI-review states from real processing validation without inventing parallel route logic.

### ADR-002: Optimize route hierarchy around evaluator hard gates rather than aesthetic-only tweaks

**Status**: Accepted

**Decision**:

- Review upload, processing, preview, onboarding, and feedback against the Picsew iOS design evaluator.
- Improve only the surfaces that affect stage dominance, action clarity, touch/readability, and route consistency.
- Prefer removing or compressing secondary helper UI instead of adding more decorative cards.

**Why**:

- The repository rule is artifact-based acceptance, not code-inspection-only approval.
- The evaluator gives a concrete bar for deciding when the UI is ready.
- A focused pass lowers risk compared with a broad redesign.

## Acceptance Criteria

- [ ] AC-01: [P0] Maestro covers all primary native routes and relevant states with current-branch artifacts.
  - **Given**: the booted simulator has the current Picsew host app installed
  - **When**: the repository-owned Maestro workspace runs
  - **Then**: onboarding, upload, processing, preview, feedback, and their required empty/loading/completed/supporting states execute without failures and save fresh screenshots
- [ ] AC-02: [P0] A seeded demo video from the repository root can complete the real native pipeline from upload to preview.
  - **Given**: a repository demo video has been copied into the simulator app container for automation
  - **When**: Maestro launches the app, starts processing, and waits for completion
  - **Then**: the app reaches preview without crashes, exposes the stitched preview, and keeps save/share actions usable
- [ ] AC-03: [P0] Upload, processing, preview, onboarding, and feedback have no evaluator hard-gate failures.
  - **Given**: fresh simulator screenshots from the current branch
  - **When**: each affected route is reviewed with the Picsew iOS design evaluator
  - **Then**: artifact, stage, action, fit, touch, type, recovery, contrast, and accessibility gates all pass
- [ ] AC-04: [P1] Shared shell and route layouts reduce competing helper surfaces and keep one dominant stage plus one primary action zone where applicable.
- [ ] AC-05: [P1] Native automation support and route-state helpers have automated Swift test coverage for the new seeded-demo and deterministic-export behaviors.

## Planned Tests

- `swift test --package-path apps/ios-native/PicsewApp`
- `xcodebuild -project apps/ios-native/HostApp/PicsewNativeApp.xcodeproj -scheme PicsewNativeApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `npm run ios:harness:smoke`
- `npm run ios:test:maestro:workspace`
- targeted Maestro flow for seeded demo processing success
- evaluator pass using fresh Maestro screenshots for onboarding, upload, processing, preview, and feedback

## Demo Asset Plan

- Use the repository-root demo clips as automation seed sources.
- Prefer the smallest clip that still exercises the real pipeline first, then keep one larger clip available for regression confidence.
- Copy seeded assets into the simulator app container before the Maestro run so route automation does not depend on system pickers.

## Risks

- Real pipeline processing on simulator hardware may make Maestro timeouts too aggressive if the demo clip is too large.
- Deterministic automation hooks can accidentally diverge from production behavior if they replace too much logic instead of only setup and export edges.
- UI polish changes can improve hierarchy but still regress compact-screen fit if bottom trays or helper text expand unexpectedly.

## Rollback

The work is limited to native automation wiring, Maestro flows, SwiftUI composition, and tests. Reverting these files returns the current baseline behavior without changing release metadata or the underlying algorithm packages.
