# Native TestFlight 1.0 (4)

## Problem and scope

The installed TestFlight build 1.0 (3) predates the native overlap fixes,
processing performance improvements, content-first viewer, and shared technology
theme. Publish the current native app as internal TestFlight build 1.0 (4).

The source baseline is main commit `75da3bf` and includes PRs #47–#50. This
release changes only the committed build number and release documentation.
Keep the marketing version, bundle identifier, and app display name unchanged.
Use the native HostApp target and existing internal testing group; do not submit
an App Store release or create new testing groups.

## Design and release choices

- Increment `PICSEW_BUILD_NUMBER` from 3 to 4 in shared `app-config.xcconfig`.
- Keep local team configuration and API credentials outside Git.
- Archive the Release configuration for generic iOS, export and upload through
  the repository's system-PATH release wrapper with internal-only distribution.
- Preserve the existing app's export-compliance classification. Verify the
  candidate's encryption use before resolving any Apple compliance prompt.
- Confirm Apple processing and existing internal-group availability before
  reporting that the build can be installed.

## Acceptance criteria and planned verification

- Lint/type checks and web build pass; native harness initialization and required
  Maestro smoke pass, including package tests and simulator build validation.
- Reuse PR #50's current-change screenshot evaluation for the unchanged UI;
  capture and inspect the release candidate's fresh Maestro preview artifact.
- Signed archive and exported IPA identify `top.ibotcloud.picsew.native`,
  marketing version 1.0, build 4, and contain no private keys or fixture videos.
- Export and upload succeed, and App Store Connect reports a valid build
  available to the existing `Picsew Internal` group.
- Release metadata and validation evidence are committed through a focused PR.

## Release evidence

- `npm run ios:harness:init`, `npm run check`, and `npm run build` passed.
  Lint has zero errors and ten existing warnings; the existing Web bundle-size
  warning remains.
- Required native smoke passed: ledger/release tests, 39 active Swift tests,
  two simulator builds, and Maestro `flows/smoke-preview.yaml` on iPhone 17 Pro
  / iOS 26.4. The separate DesignSystem test also passed. The private-recording
  test is skipped by the standard harness and was verified in PRs #47/#48.
- A fresh release-candidate preview screenshot was captured and explicitly
  inspected: **GO**. It shows the blue toolbar, dominant image area, and compact
  Save/Share actions. Generated artifacts stay in ignored
  `.derived-data/release-build-4/`; PR #50 records the unchanged UI's full route,
  appearance, compact-screen, enlarged-text, and interaction evaluation.
- Generic-device Release archive and API-authenticated export passed. Both
  archive and IPA verify as native version 1.0 (4), minimum iOS 18.0, arm64.
  The IPA signature verifies with `get-task-allow=false` and
  `beta-reports-active=true`. Neither app bundle contains private-key or video
  resources. Signing and export settings remain local and ignored.
- Upload completed on 2026-10-03 with exit status 0 and `Upload succeeded`.
  App Store Connect subsequently reported build 1.0 (4) as `VALID` and
  `INTERNAL_ONLY`. The candidate's native source and shared release metadata
  match the release preparation merged in PR #51.
- After checking the native target/packages have no custom encryption,
  retained the prior builds' `usesNonExemptEncryption=false` classification.
  Saved Chinese test notes and assigned build 4 to the existing
  `Picsew Internal` group without changing its tester membership.
- A fresh Apple API read confirms `internalBuildState=IN_BETA_TESTING`, group
  assignment present, and `expired=false`. The beta is available for internal
  testers to install; its expiry is 2027-01-01. Physical-device installation,
  processing timings, Photos permissions, and share-sheet behavior remain for
  the tester and are not implied by simulator or upload validation.
