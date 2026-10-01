# Native iOS TestFlight beta

Date: 2026-10-01

## Goal and scope

Continue the user's authorized TestFlight setup after signing into their paid
Apple Developer account, so the optimized native app can be installed remotely on
an iPhone. Release the validated native UI candidate on `codex/ios-minimal-redesign`
(PR #37). Preserve unrelated changes in the main checkout. This is release
packaging of the existing candidate, not a new Swift UI or algorithm rewrite.

The native host is `apps/ios-native/HostApp/PicsewNativeApp.xcodeproj`, scheme
`PicsewNativeApp`. Shared metadata remains in its `app-config.xcconfig`; the
initial beta is version 1.0, build 2. The root `ios/` Capacitor shell is not the
release target. Actual Apple team/certificates/profiles stay in ignored local
signing configuration and generated output, never in committed project metadata.

## Included behavior and limitation

The beta includes the minimal import, processing, preview and onboarding redesign
already documented and evaluated in `ios-minimal-redesign.md`. The newer Web-only
floating-overlay fixes have not been ported to Swift; do not advertise them as part
of this beta. The prior fresh UI artifacts remain valid for unchanged Swift source.

## Packaging and acceptance

1. Verify the paid team and signing environment; use Xcode's authenticated account
   for automatic provisioning. Do not create app-specific passwords or API keys
   unnecessarily, and never put credentials into repository files or logs.
2. Run the native harness init, app/package tests, a simulator build and Maestro
   preview smoke for the release candidate. Inspect the fresh smoke screenshot.
   No new test code is justified by a declarative build-number change alone.
3. Produce a Release archive for generic iOS, inspect its bundle identifier,
   version/build and signing, then validate/export/upload for App Store Connect.
4. Confirm App Store Connect accepts the upload, wait for build processing, and
   make it accessible for the account's TestFlight testing. Do not call an archive
   or a successful transfer an installable TestFlight beta before processing.
5. Report the actual build and installation path, or the exact account/Apple-side
   blocker if activation, authentication or processing prevents completion.

At the time of this first beta, the shared checklist still referred to the
transitional Capacitor shell. The subsequent release-environment fix updated
`docs/ios-release-checklist.md` to the native paths and added clean CLI/GUI
release entry points. Follow that checklist for future releases.

## Verification and current distribution state

- `npm run ios:harness:init`: passed with the required local tools available.
- `PICSEW_IOS_SMOKE_REQUIRE_MAESTRO=1 npm run ios:harness:smoke`: passed,
  including the ledger checks, 11 Swift app tests, simulator builds and
  `apps/ios-native/maestro/flows/smoke-preview.yaml` on iPhone 17 Pro / iOS 26.4.
- Fresh preview screenshots were captured and inspected for this build. The
  preview stage, result disclosure, Save / Share actions and restart action match
  the existing design. Generated screenshots remain outside committed source.
- `npm run check`, `npm run typecheck` and `npm run build`: passed. ESLint reports
  eight existing test warnings; the Web build reports the existing chunk-size
  warning.
- Generic-device Release archive: passed. Archive inspection confirms the native
  bundle, version 1.0 (2), minimum iOS 18.0 and a valid development signature.
  The archived app contains no MP4/MOV resources or the private test recording.
- App Store Connect export: passed after the user authenticated the paid account
  in Xcode. The exported IPA's distribution signature verifies, with
  `get-task-allow=false` and `beta-reports-active=true`.
- The local export initially hit `Copy failed`: Xcode's system rsync subprocess
  resolved an incompatible Homebrew rsync. Running export/upload with
  `PATH=/usr/bin:/bin:/usr/sbin:/sbin` fixed packaging without changing global
  system configuration or shared source.
- Created the native app record with bundle `top.ibotcloud.picsew.native`, name
  Picsew, primary language Simplified Chinese and SKU `picsew-native-ios`.
- Upload of version 1.0 (2) succeeded at 17:50 CST. Apple accepted the package
  for processing. The export uses TestFlight Internal Only.
- Created `Picsew Internal` with manual build distribution and added only the
  account holder as an internal tester. Saved Chinese beta information with the
  native/Web algorithm limitation; tester contact details stay in Apple/local
  state rather than committed documentation.
- Completed the build's encryption questionnaire after checking that the native
  target and local Swift packages do not implement their own encryption. Chose
  “None of the algorithms mentioned above,” following Apple's
  [encryption documentation guidance](https://developer.apple.com/help/app-store-connect/reference/export-compliance-documentation-for-encryption/).
- App Store Connect changed build 2 from Missing Compliance to Ready to Test.
  After adding it to `Picsew Internal`, the build status is **Testing** with a
  90-day expiry. This beta is available to the internal testing account; the
  actual iPhone installation and real-device Photos/share/video checks remain
  for the tester.
- Integrated the already delivered Web changes from `main` and resolved the
  shared UI contract conflict by retaining its newer Web adoption and reference
  library sections. Native source and release configuration are byte-identical
  to the uploaded candidate. Post-integration `npm run check`, 39 Web unit tests
  and `npm run build` passed; the current main-based lint has ten warnings and
  zero errors. This synchronization does not port the Web algorithm to Swift.
