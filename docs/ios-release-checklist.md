---
title: iOS Release Checklist
author: Jayson Albert
date: 2026-03-29
updated: 2026-10-01
version: 0.2.0
reviewers: [Jayson Albert]
tags: [ios, release, checklist]
status: approved
---

# iOS Release Checklist

The active native target is `apps/ios-native/HostApp/PicsewNativeApp.xcodeproj`,
scheme `PicsewNativeApp`. Root `ios/` is the transitional Capacitor shell; use its
paths only when explicitly releasing that shell.

## Release environment and regression

Xcode packaging can start `/usr/bin/rsync`, then resolve its child `rsync` through
the inherited PATH. If Homebrew 3.4.1 takes precedence, Apple's extended-attribute
arguments cause `Copy failed` / `--extended-attributes: unknown option`. The fix
belongs to the release process environment, not the app or installed Homebrew
software.

Use the repository release commands below. Every child receives
`PATH=/usr/bin:/bin:/usr/sbin:/sbin`, preserving other environment values. The GUI
launcher passes this PATH to a fresh Xcode via `open --env`; it refuses to reuse
an already running Xcode because an existing process keeps its old environment.
Quit Xcode normally before using that launcher. These commands never close
windows, change global PATH or unlink Homebrew tools.

Acceptance criteria: reproduce native rsync copying failure under a contaminated
PATH, then verify the same copy through the release wrapper; preserve unrelated
caller environment and child exit status. Add the focused regression to the
native harness. Verify the GUI launch environment with a disposable local probe
and check the running-Xcode refusal. Real Apple signing/upload remains a separate
check; a CLI `No Accounts` error does not establish that Xcode's GUI is logged out.

```sh
npm run ios:release:doctor
# Quit Xcode first. The optional argument may be a project or an existing archive.
npm run ios:release:xcode -- /absolute/path/PicsewNativeApp.xcarchive

# Arguments: archive, output directory, local export-options plist.
npm run ios:release:export -- /absolute/path/PicsewNativeApp.xcarchive \
  /absolute/path/export /absolute/path/ExportOptions.plist
npm run ios:release:upload -- /absolute/path/PicsewNativeApp.xcarchive \
  /absolute/path/upload /absolute/path/UploadOptions.plist
```

The export-options file must explicitly set `destination` to `export` or `upload`
to match the command. Use `method=app-store-connect`, `signingStyle=automatic`,
`manageAppVersionAndBuildNumber=false` and, for internal betas,
`testFlightInternalTestingOnly=true`. Keep `teamID` and account-specific settings
in ignored local files. API keys, if separately configured for automation, stay
outside source and command output. The wrapper uses Xcode's existing authentication.

For GUI distribution, launch through `ios:release:xcode`, then select the archive
in Organizer and choose TestFlight Internal Only. `doctor` proves packaging copy
compatibility; it does not prove that an account is authenticated or a beta is
installable. If CLI authentication fails while GUI login is visible, use the clean
GUI entry rather than repeatedly asking the user to log in again.

### Release-environment verification (2026-10-01)

- The native copy regression failed before PATH isolation and passed after it.
  All five release tests pass locally, including CLI doctor and rejection of
  export-only options passed to upload. The native harness runs these tests;
  changes under `scripts/ios-native/` also trigger its CI workflow.
- `ios:release:doctor` passes with the installed Xcode and Apple's rsync.
  A disposable background app launched by real `open --env` received the exact
  system-only PATH. The launcher correctly refuses the currently running Xcode.
  A fresh Xcode Organizer distribution has not yet been verified with this entry.
- `npm run check` passes (zero errors, ten existing lint warnings) and
  `npm run build` passes. The required native smoke passes: 29 Swift tests,
  simulator builds, and Maestro `flows/smoke-preview.yaml` with a fresh screenshot.
  Screenshot self-review confirms that preview content and actions are visible.
- A real archive export through the new wrapper exits with Xcode status 70:
  `No Accounts` and no `iOS Distribution` signing certificate. This failure occurs
  before packaging and does not verify the full archive/export/upload pipeline.
  The authenticated App Store Connect page still lists only build 2; build 3 is
  not confirmed uploaded. Keep this Apple authentication/signing check separate
  from the passing rsync compatibility regression.
- The Homebrew rsync link is restored. No installed tool or global PATH change
  is part of this implementation.

## Before Bumping A Release

- Confirm display name and bundle identifier in `apps/ios-native/HostApp/app-config.xcconfig`.
- Confirm the release branch contains only the intended scope.
- Confirm App Store assets or store metadata changes are tracked outside the code diff if needed.

## Versioning

- Update `PICSEW_MARKETING_VERSION` in the native shared `app-config.xcconfig` for a user-visible release.
- Update `PICSEW_BUILD_NUMBER` there intentionally for every new TestFlight candidate.
- Keep the version bump in the same PR as the release prep when practical.

## Validation

- Run `npm run typecheck`.
- Run `npm run build`.
- Run `npm run ios:harness:init` and `npm run ios:harness:smoke` (includes native tests and simulator build).
- For native UI changes, run the affected Maestro screenshot flows and review fresh artifacts.
- Sanity-check the upload, processing, and preview screens if the release changes shared app UI.

## Signing And Packaging

- Make sure `apps/ios-native/HostApp/local-signing.xcconfig` exists locally and is not staged.
- Confirm the correct Apple Developer team is selected through the local signing config.
- Open Xcode and verify the expected bundle identifier, version, and display name before archiving.
- Use the clean release entry above for export/upload or Organizer. Confirm Apple processing and internal-group availability before reporting TestFlight as ready.

## Final Review

- Confirm `AGENTS.md` and relevant docs are updated if the release process changed.
- Confirm no machine-local files, signing metadata, or generated artifacts are staged.
- Confirm the release PR description lists the shipped scope and any known limitations.
