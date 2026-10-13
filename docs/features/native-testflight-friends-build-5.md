# Native TestFlight 1.0 (5): Friends external testing

Date: 2026-10-13

## Problem and scope

The user requests adding the current app to the existing external TestFlight group
Friends. Builds 2–4 are INTERNAL_ONLY and Apple does not permit external testing
of those uploads. Publish a new build 1.0 (5) using ordinary App Store Connect
distribution, then add it to Friends and submit TestFlight beta review if needed.

This release preserves build 4's native app behavior. Change only the shared
build number, release documentation, and local export/upload options. Preserve
existing groups, tester membership, invitation links, signing credentials, and
unrelated uncommitted work. No App Store production release is requested.

## Design and acceptance

- Start from latest main and confirm native sources remain identical to build 4.
- Increment PICSEW_BUILD_NUMBER to 5. Keep version 1.0 and the native bundle ID.
- Use method=app-store-connect, automatic signing, and
  testFlightInternalTestingOnly=false in ignored local distribution options.
- Reuse the existing team API key and local signing override without logging
  private values. Keep the prior encryption-exemption classification after
  checking that native source is unchanged.
- Preserve existing beta metadata and review contact information. Resolve only
  required missing app/testing fields from verified facts; ask for missing
  personal contact details rather than inventing them.
- Verify Apple reports a valid externally eligible candidate, Friends contains
  that candidate, and TestFlight review is submitted or approved. Report review
  pending separately from an installable beta.

## Planned verification

Run lint/type checks, Web build, release auth/doctor and required native harness
smoke, including Swift tests, simulator builds and a fresh Maestro preview
screenshot. Explicitly inspect the screenshot. No new constant-mirroring tests
are justified by a metadata-only change. Check archive/IPA identity, signatures,
TestFlight entitlements, and absence of private keys/video fixtures before upload.
Confirm Friends assignment and actual beta-review state with fresh Apple API reads.

Apple reference: [Internal-only build restriction and external beta review](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/).

## Verification evidence

- Native source compared with build 4's baseline `75da3bf`: unchanged.
- `npm run ios:harness:init`, `npm run check`, `npm run build`, release
  auth and doctor passed. Lint has zero errors and ten existing warnings;
  the existing Web chunk-size warning remains.
- Required native harness smoke passed: ledger/release tests, 40 active Swift
  tests (the private-recording test is skipped), two simulator builds and
  Maestro `flows/smoke-preview.yaml` on iPhone 17 Pro / iOS 26.4.
- Fresh preview screenshot captured and explicitly self-reviewed: GO. The
  original image dominates the viewport and compact blue Save/Share controls
  remain visible. The unchanged UI's wider route/appearance evaluation remains
  recorded in PR #50. Generated artifacts are ignored.
- Signed generic-device Release archive and API-authenticated export passed.
  Archive and IPA are native bundle `top.ibotcloud.picsew.native`, version
  1.0 (5), arm64, minimum iOS 18.0. Signature and TestFlight entitlements verify;
  `get-task-allow=false` and `beta-reports-active=true`. Neither app bundle
  includes private keys or video fixtures. Local upload options were verified
  to have `testFlightInternalTestingOnly=false`.
- The user's supplied beta-review contact was saved only in App Store Connect;
  the existing feedback email was reused. No demo account is required, and
  review notes describe actual video import, creation and export steps. Personal
  contact details are excluded from source and delivery documentation.
- Upload succeeded on 2026-10-13 with exit status 0. A fresh Apple API read
  confirms 1.0 (5) is VALID, APP_STORE_ELIGIBLE, unexpired, and classified
  usesNonExemptEncryption=false, matching the unchanged native implementation.
- Existing What to Test localizations were copied from build 4. The candidate
  is now associated with the existing external Friends group. Tester membership
  and public invitation settings were not modified.
- TestFlight beta review was submitted successfully. Fresh API reads confirm
  externalBuildState=WAITING_FOR_BETA_REVIEW and betaReviewState=WAITING_FOR_REVIEW,
  with Friends assignment present and autoNotifyEnabled=true. External testers
  must wait for Apple approval before installing this build; submission and
  group assignment do not imply approval. No App Store production submission
  was created.
