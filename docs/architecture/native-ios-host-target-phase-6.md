---
status: approved
---

# Native iOS Host Target Phase 6

## TL;DR

The native algorithm, app-core orchestration, and SwiftUI shell are now all compileable, but the repository still lacks a real native iOS host target that can launch the shell as an app. Phase 6 adds an independent Xcode project under `apps/ios-native/HostApp/` and wires it to the `PicsewApp` package so the native app can be built and run without the transitional Capacitor shell.

## Problem

The native migration now has:

- media extraction
- algorithm parity through stitching
- one app-facing native pipeline package
- one compileable SwiftUI shell package

What it still does not have is an executable iOS host project. Without that:

- the native app cannot be launched from Xcode
- package-level work remains disconnected from a real iOS runtime
- the migration is still missing the first true replacement for the Capacitor shell

## Scope

### In scope

- add a new Xcode iOS app project under `apps/ios-native/HostApp/`
- host the `PicsewRootView` SwiftUI shell from the `PicsewApp` package
- use local package references instead of Capacitor dependencies
- keep committed shared app identity config and ignored local signing config
- validate the host project with an `xcodebuild` simulator build

### Out of scope

- Photos picker integration
- save/share/export integration
- replacing the existing root `ios/` shell in deployment or release flows
- app-store release polish

## Design

### ADR-001

- Status: Accepted
- Context: The native app needs a real executable host, but the current root `ios/` project is still tied to Capacitor infrastructure.
- Decision: Create a new independent host project under `apps/ios-native/HostApp/` and keep the old root `ios/` project untouched as transitional infrastructure.

#### Alternatives

| Option                                                                         | Pros                                                                       | Cons                                                       | Conclusion |
| ------------------------------------------------------------------------------ | -------------------------------------------------------------------------- | ---------------------------------------------------------- | ---------- |
| Rework the existing root `ios/` project in place                               | Faster initial edits                                                       | Mixes transitional Capacitor cleanup with native host work | Rejected   |
| Wait until all native feature integration is done before adding a host project | Less project-file work now                                                 | Delays real iOS runtime validation too long                | Rejected   |
| Add a new host project under `apps/ios-native/HostApp/`                        | Clean ownership, keeps migration explicit, enables real runtime validation | Requires a second project during transition                | Accepted   |

### Host structure

```text
apps/ios-native/HostApp/
  PicsewNativeApp.xcodeproj
  App/
    PicsewHostApp.swift
    Info.plist
    Assets.xcassets/
    Base.lproj/
      LaunchScreen.storyboard
  app-config.xcconfig
  local-signing.example.xcconfig
  .gitignore
```

### Host responsibility

The host project will:

- provide the executable app bundle target
- depend on `PicsewApp`
- render `PicsewRootView`
- own app identity, launch screen, and build configuration

It will not:

- own the native processing logic
- own SwiftUI feature state
- depend on Capacitor

## Acceptance Criteria

- [ ] AC-01: [P0] `apps/ios-native/HostApp/` contains a buildable iOS app project that depends on the `PicsewApp` package.
- [ ] AC-02: [P0] The host target launches the native SwiftUI shell rather than a web view or storyboard-driven root screen.
- [ ] AC-03: [P0] Shared app identity config is committed and local signing remains ignored.
- [ ] AC-04: [P0] `xcodebuild -project apps/ios-native/HostApp/PicsewNativeApp.xcodeproj -scheme PicsewNativeApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` passes.

## Planned Tests

- package-level validation:
  - `swift test` in `apps/ios-native/PicsewApp`
  - `swift test` in `apps/ios-native/Packages/PicsewMedia`
  - `swift test` in `apps/ios-native/Packages/PicsewAlgorithm`
  - `swift test` in `apps/ios-native/Packages/PicsewAppCore`
- host-project validation:
  - `xcodebuild` simulator build for `PicsewNativeApp`
- repository validation:
  - `npm run lint`
  - `npm run typecheck`
  - `npm run build`

## Risks

- Manual Xcode project edits can be noisy, so this phase should keep the host project minimal.
- The host app may expose platform-only SwiftUI APIs that do not appear in package-only macOS builds.

## Rollback

This phase is additive. The new host project can be reverted without affecting the web app, the transitional Capacitor shell, or the native package layers.
