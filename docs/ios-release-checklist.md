---
title: iOS Release Checklist
author: Jayson Albert
date: 2026-03-29
updated: 2026-03-29
version: 0.1.0
reviewers: [Jayson Albert]
tags: [ios, release, checklist]
status: approved
---

# iOS Release Checklist

## Before Bumping A Release

- Confirm the intended app display name and bundle identifier in `ios/app-config.xcconfig`.
- Confirm the release branch contains only the intended scope.
- Confirm App Store assets or store metadata changes are tracked outside the code diff if needed.

## Versioning

- Update `PICSEW_MARKETING_VERSION` in `ios/app-config.xcconfig` for a user-visible release.
- Update `PICSEW_BUILD_NUMBER` in `ios/app-config.xcconfig` for every new archive or TestFlight upload.
- Keep the version bump in the same PR as the release prep when practical.

## Validation

- Run `npm run typecheck`.
- Run `npm run build`.
- Run `xcodebuild -project ios/App/App.xcodeproj -scheme App -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`.
- Sanity-check the upload, processing, and preview screens if the release changes shared app UI.

## Signing And Packaging

- Make sure `ios/local-signing.xcconfig` exists locally and is not staged.
- Confirm the correct Apple Developer team is selected through the local signing config.
- Open Xcode and verify the expected bundle identifier, version, and display name before archiving.

## Final Review

- Confirm `AGENTS.md` and relevant docs are updated if the release process changed.
- Confirm no machine-local files, signing metadata, or generated artifacts are staged.
- Confirm the release PR description lists the shipped scope and any known limitations.
