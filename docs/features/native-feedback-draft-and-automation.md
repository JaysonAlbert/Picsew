# Native feedback drafts and automation coverage

Date: 2026-10-14

## Problem and scope

PR #36 predates the published technology theme and content-first viewer. The user
chooses to preserve the published UI and deliver only its remaining feedback
local-draft and automation improvements. Rebuild this personal review branch from
latest main; leave the original working copy and a complete local backup intact.

Do not change upload/processing/preview layouts, shared design tokens, pipeline
algorithms, release metadata or signing. Keep the existing GitHub feedback action.
Use current design-system roles for the feedback form; no screen-specific colors.

## Design and acceptance

- Feedback offers a text editor and Save draft. Trim whitespace and require at
  least ten characters, matching the existing work's validation. Save on device,
  show honest local confirmation, and restore the saved draft when reopening the
  route or restarting the app. Saving does not send feedback to a server.
- Provide a native Done action for the multiline keyboard so feedback actions
  remain reachable on compact screens.
- Preserve Send feedback on GitHub. Saving a draft must not disable that existing
  action or falsely report network submission.
- Automation retains the current readable preview fixture and existing scenario
  spellings. Add the old branch's empty-upload/seeded-real-pipeline scenarios,
  real fixture PNG share files, and explicit export-failure injection. Real app
  launches without an automation scenario continue using the real system client.
- Seeded videos stay in simulator cache, never in the app bundle. Reject nested
  or traversing filenames; an absent seed reports an error rather than silently
  claiming a real recording was processed.
- Keep the missing-selection guard and cover it with a regression test. This
  guard already exists on main, so its added test is characterization, not RED.

## Planned verification

Before implementation, run a feedback draft/persistence Maestro interaction and
an export-failure flow against main: both must fail on the missing behavior.
Then run focused app tests for the automation factory and existing empty-start
behavior, required native harness smoke, and simulator build. Run fresh route
screenshots and feedback interactions in light/dark, compact screen and enlarged
text. Capture the three primary routes and verify the published UI is preserved.
A dedicated evaluator inspects fresh artifacts before handoff. Run lint/type
checks, Web build, and confirm the PR has no unrelated changes or machine-local
Apple identifiers. Record actual results here before updating PR #36.

The seeded-real-pipeline flow lives under `maestro/manual/` so ordinary workspace
flows do not depend on a prepared recording. Install the host app, run
`scripts/ios-native/seed-demo-videos-on-booted-sim.sh` (defaults to the public glass
fixture; accepts a recording path), then explicitly run
`manual/seeded-demo-processing.yaml`. `PICSEW_SIMULATOR_ID` selects the device.

## Verification evidence

- Both new interaction flows failed on the unchanged main baseline: the feedback
  Save draft control was absent, and injected export failure still reported a
  successful save. After implementation, both flows pass. The feedback interaction
  also covers short-note rejection, keyboard Done, saved confirmation, and
  restoration after restarting the app.
- `swift test --package-path apps/ios-native/PicsewApp`: 15 tests pass, including
  actual PNG sharing, export failures, missing/traversing seed rejection, legacy
  empty-upload compatibility, and the existing missing-selection guard.
- `PICSEW_IOS_SMOKE_REQUIRE_MAESTRO=1 npm run ios:harness:smoke`: passed with
  ledger/release checks, 44 active Swift tests, two simulator builds and
  `flows/smoke-preview.yaml`. The private-recording test is skipped by the
  standard harness; algorithm source is unchanged.
- `manual/seeded-demo-processing.yaml`: passed on the public glass recording.
  It used the real native processing pipeline and reached preview with a valid
  share file. Its Photos save is an automation client acknowledgment, not a
  physical-device photo-library permission test.
- Fresh `capture-upload.yaml`, `capture-processing.yaml`, `capture-preview.yaml`
  and `capture-feedback.yaml` ran in Pro light/dark. Feedback draft interactions
  also passed in SE3 light/dark. `feedback-accessibility.yaml` passed on Pro and
  SE3 at maximum accessibility text; `preview-interaction.yaml` passed for zoom,
  save, scroll and return-to-import at maximum text.
- The 22 route/interaction PNGs in the valid screenshot matrix were checked for
  device dimensions: Pro 1206 x 2622; SE3 750 x 1334. A dedicated read-only
  post-automation evaluator concluded **GO** for hierarchy, legibility, scrolling
  and preservation of the published UI. Logs also prove the transient saved
  confirmation and keyboard Done interaction; those transient states are not
  separately preserved as screenshots. GitHub destination opening, VoiceOver
  and physical-device behavior were not manually tested.
- Run multi-device Maestro flows serially. Concurrent runs mixed driver targets;
  the affected results were discarded and rerun with one booted device at a time.
  Current valid artifacts are under `.derived-data/pr36-validation/`; only the
  normal Pro light/dark and explicitly named `*-serial` matrix is accepted.
- Lint/type checks and Web build passed: zero lint errors, ten existing warnings
  and the existing OpenCV chunk-size warning. The seed helper passes `bash -n`;
  ledger checks/tests and `git diff --check` pass.
- Scope comparison confirms unchanged algorithm/media/app-core/design-system
  packages, three primary screen layouts, release identity, and signing config.
  Original working-copy changes and cleared-worktree artifacts are retained in
  the primary checkout's ignored cleanup backup directory.
