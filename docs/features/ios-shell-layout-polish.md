---
title: iOS Shell Layout Polish
issue: ios-shell-layout-polish
author: Jayson Albert
date: 2026-03-29
updated: 2026-03-29
version: 0.1.0
reviewers: [Jayson Albert]
tags: [ios, capacitor, ui, safe-area]
source_code:
  - src/App.tsx
  - src/components/FeedbackDialog.tsx
  - src/index.css
  - index.html
status: approved
---

# iOS Shell Layout Polish

## Summary

- **Problem**: The current Capacitor shell keeps the web header layout unchanged, which causes poor wrapping in English and leaves the content visually too close to the Dynamic Island / safe area on modern iPhones.
- **Goal**: Make the iOS app shell feel intentionally adapted to iPhone devices without rewriting the whole screen in SwiftUI.
- **Scope**:
  - add iOS-safe top spacing
  - tighten the header layout for narrow screens
  - use a compact app-brand presentation on iOS
  - document how to import local videos into the iOS Simulator for testing

## Current Issues

1. Long English titles wrap awkwardly in the header.
2. Header content visually collides with the iPhone top safe area.
3. The feedback trigger consumes too much horizontal space for a native app shell.
4. The simulator does not include test videos by default, which slows down verification.

## Design Choice

### ADR-001: Keep the shared web UI, but add iOS-shell-specific framing

**Status**: Accepted

**Decision**:

- Keep the shared React screen and existing business flow.
- On iOS native builds, switch the header to a compact brand presentation:
  - title becomes `Picsew`
  - subtitle remains descriptive
  - action buttons become tighter
- Add CSS safe-area support through `env(safe-area-inset-top)` and `viewport-fit=cover`.

**Why**:

- This solves the immediate iPhone shell problems without splitting the UI into separate web/native implementations.

## Acceptance Criteria

- [ ] AC-01: iOS header respects the top safe area on devices with a Dynamic Island or notch.
- [ ] AC-02: The iOS header no longer shows awkward English wrapping for the app title.
- [ ] AC-03: The feedback trigger fits cleanly beside the language switcher on narrow screens.
- [ ] AC-04: There is a documented simulator workflow for importing local macOS videos.

## Test Plan

- `npm run typecheck`
- `npm run test:unit`
- `npm run build`
- `npm run lint`
- `npm run test:e2e:smoke -- --grep "feedback dialog opens from header trigger|feedback dialog stays inside the viewport on mobile|home page shows upload flow"`
- `npm run cap:sync:ios`
- `xcodebuild -project ios/App/App.xcodeproj -scheme App -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`

## Simulator Media Import Notes

Recommended simulator import command:

```bash
xcrun simctl addmedia booted /absolute/path/to/video.mov
```

Alternative manual flow:

1. Open the `Photos` app inside the iOS Simulator.
2. Drag a local macOS video file into the simulator window.
3. The file will be imported into the simulator photo library.
