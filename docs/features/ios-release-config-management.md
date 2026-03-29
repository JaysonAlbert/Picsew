---
title: iOS Release Config Management
issue: ios-release-config-management
author: Jayson Albert
date: 2026-03-29
updated: 2026-03-29
version: 0.1.0
reviewers: [Jayson Albert]
tags: [ios, release, config, governance]
source_code:
  - ios/App/App.xcodeproj/project.pbxproj
  - ios/App/App/Info.plist
  - ios/debug.xcconfig
  - ios/release.xcconfig
  - ios/app-config.xcconfig
  - docs/ios-release-checklist.md
  - AGENTS.md
status: approved
---

# iOS Release Config Management

## Summary

- **Problem**: iOS app identity and release metadata are still split across `project.pbxproj`, `Info.plist`, and Xcode UI defaults, which makes version bumps and app identity changes easy to miss and hard to review.
- **Goal**: Establish one committed configuration layer for app display name, bundle identifier, marketing version, and build number, then pair it with a repeatable release checklist.
- **Scope**:
  - move shared iOS app identity values into committed `xcconfig`
  - keep local signing overrides separate from release metadata
  - update shared project rules in `AGENTS.md`
  - add a checked-in iOS release checklist for future releases

## Design Choice

### ADR-001: Keep release metadata in committed shared xcconfig

**Status**: Accepted

**Decision**:

- Create one committed `ios/app-config.xcconfig` as the shared source of truth for:
  - display name
  - bundle identifier
  - marketing version
  - build number
- Make `debug.xcconfig` and `release.xcconfig` include the shared config and apply those values to build settings.
- Keep `local-signing.xcconfig` focused on machine-local signing only.
- Update `Info.plist` to reference shared config variables instead of hardcoded app identity strings.

**Why**:

- Shared release metadata should be easy to diff, review, and update in one place.
- `project.pbxproj` should describe project structure, not accumulate ad hoc release edits.
- Local signing and shared app identity are different concerns and should not be mixed.

## Acceptance Criteria

- [ ] AC-01: The iOS app display name, bundle identifier, marketing version, and build number are defined in committed shared config.
- [ ] AC-02: `Info.plist` no longer hardcodes the app display name.
- [ ] AC-03: The Xcode project no longer duplicates release metadata inline when a shared config variable can own it.
- [ ] AC-04: A committed iOS release checklist exists and is suitable for future release prep.
- [ ] AC-05: `AGENTS.md` documents the repository rule for app identity and release management.

## Test Plan

- `npm run typecheck`
- `npm run build`
- `xcodebuild -project ios/App/App.xcodeproj -scheme App -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
