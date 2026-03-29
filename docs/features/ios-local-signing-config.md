---
title: iOS Local Signing Config
issue: ios-local-signing-config
author: Jayson Albert
date: 2026-03-29
updated: 2026-03-29
version: 0.1.0
reviewers: [Jayson Albert]
tags: [ios, signing, xcode, config]
source_code:
  - ios/App/App.xcodeproj/project.pbxproj
  - ios/debug.xcconfig
  - ios/release.xcconfig
  - ios/local-signing.example.xcconfig
  - ios/.gitignore
status: approved
---

# iOS Local Signing Config

## Summary

- **Problem**: Xcode writes `DEVELOPMENT_TEAM` directly into `project.pbxproj`, which creates local git noise and risks accidentally committing Apple Developer team identifiers.
- **Goal**: Keep iOS signing usable on the local machine without requiring the team identifier to live in committed project settings.
- **Scope**:
  - remove hardcoded `DEVELOPMENT_TEAM` values from the Xcode project
  - load the team identifier from a local ignored `xcconfig`
  - provide a checked-in example config for new machines

## Design Choice

### ADR-001: Keep signing local through ignored xcconfig overrides

**Status**: Accepted

**Decision**:

- Keep project structure committed in git.
- Move the actual team identifier into `ios/local-signing.xcconfig`, which is ignored by git.
- Commit `ios/local-signing.example.xcconfig` as a template.
- Reference `$(PICSEW_DEVELOPMENT_TEAM)` from the Xcode project so local builds still resolve correctly.

**Why**:

- The iOS project should remain versioned because it is real app source, not disposable generated output.
- Team identifiers are not high-risk secrets, but they are still user-specific account metadata.
- An ignored local config reduces accidental commits and keeps the shared project clean.

## Acceptance Criteria

- [ ] AC-01: `project.pbxproj` no longer contains a hardcoded `DEVELOPMENT_TEAM` value.
- [ ] AC-02: The current machine can still build after putting the team ID in an ignored local config file.
- [ ] AC-03: New collaborators have a checked-in example showing how to configure local signing.

## Test Plan

- `xcodebuild -project ios/App/App.xcodeproj -scheme App -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
