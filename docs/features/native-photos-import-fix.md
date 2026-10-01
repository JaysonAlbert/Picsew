# Native Photos video selection

Date: 2026-10-01

## Problem and scope

The user selected a video through Photos in iPhone TestFlight 1.0 (2), but the
import stage remained empty and Create screenshot stayed disabled. The upload
view keys its loading task to `PhotosPickerItem.itemIdentifier`. Its PhotosPicker
does not specify a photo library, and Apple documents that the identifier can be
nil in that configuration. A selection therefore does not change the task ID
from the initial nil value, so the actual import never starts.

This is a picker-to-import wiring fix. Preserve the current native UI design,
Files import and stitching algorithms. Keep the private user recording local.

## Design

- Observe the selected picker item itself rather than its optional asset ID.
  Continue using the permission-free system picker; do not request full photo
  library access merely to obtain an identifier.
- Load and copy the selected video through the existing transfer/system-client
  path. A successful import must populate the stage and enable Create screenshot.
- Report an unsupported/empty transfer as an actionable import error. Discard
  cancelled or outdated picker loads rather than replacing a newer selection.
- Clearing selection also clears the picker binding, so the same video can be
  selected again.
- Package the verified fix as native version 1.0 (3) and update TestFlight.

## Acceptance and tests

1. A repository-owned Maestro regression uses the actual system Photos picker,
   seeded with a committed synthetic video, and normal app composition (no fake
   upload scenario). It must fail on the old wiring and pass on the fix.
2. Selecting a video changes the stage to Ready to stitch and enables Create
   screenshot. Clearing and selecting the same video again must also succeed.
   Start processing the imported synthetic video and verify a real preview image
   is produced; this is a pipeline smoke check, not an algorithm-quality oracle.
3. Capture fresh screenshots of the affected import states and explicitly
   inspect them against the existing shell/stage/action design. Do not accept
   synthetic selection alone as proof that the real picker works.
4. Run native harness init/smoke, applicable Swift tests, simulator build and
   focused Maestro interaction flows before delivery. Keep existing app flows
   green; run lint/typecheck/build gates for repository delivery.
5. Archive/export/upload the new native build with local-only signing settings,
   confirm Apple processing and add build 3 to the existing internal test group.

## Reference

[Apple: PhotosPickerItem.itemIdentifier](https://developer.apple.com/documentation/photosui/photospickeritem/itemidentifier)
documents the nil identifier behavior. The same type conforms to Equatable and
can be used directly as the SwiftUI task ID.

## Baseline reproduction

Before production edits, the real Photos integration flow ran against the build
2 simulator app. The seeded synthetic video was visible in the system picker;
selecting it dismissed the picker, but the stage stayed empty. Waiting up to
20 seconds for `upload.startProcessing` to become enabled failed. A fresh
screenshot reproduces the user's reported empty import screen.

The final regression is invoked by `npm run ios:test:maestro:photos`. Its runner
owns simulator installation and public-fixture seeding. The Photos integration
flow remains separate from the default fixture-backed Maestro workspace.

## Verification results

- The same real-picker regression passed after the wiring fix, including clear,
  same-video reselection and real processing through to the preview image.
- `npm run ios:harness:smoke` passed with Maestro required: Swift app tests,
  simulator builds and preview smoke. Upload-selection and onboarding interaction
  flows also passed (2/2).
- `npm run check` passed with zero errors and ten existing warnings; the web
  production build passed with its existing chunk-size warning.
- Fresh picker, selected and reselected screenshots were reviewed. The selected
  stage and enabled primary action match the existing native design; text and
  actions are not clipped. This is an explicit self-review of current artifacts.
- The real preview exposed a separate, pre-existing vertical raster inversion.
  That media conversion defect requires a separate focused fix before publishing
  the next combined TestFlight candidate. Preview existence alone does not prove
  correct stitching or media orientation.
