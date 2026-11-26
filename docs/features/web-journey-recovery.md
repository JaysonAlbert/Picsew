# Web journey recovery

The Web pilot found that an unreadable recording could enter processing,
OpenCV initialization failure left Create disabled indefinitely, and an
interrupted generation discarded the selection. The preview gave no feedback
when sharing failed. The first-run dialog let keyboard focus reach the page
behind it.

## Design

- Import reports whether the selected recording is readable before enabling
  Create. A failed selection stays visible with instructions to choose another
  recording. Selecting or clearing a file resets the previous media status.
- When OpenCV initialization rejects, explain the failure and offer Reload page
  in the upload action area. A reload starts a fresh browser module instance,
  and users will need to select the recording again. Load the stitching module
  on demand so a failed engine import does not prevent the upload screen from rendering.
- When generation fails, return to import with the recording and an actionable
  localized message. Retry uses the same recording. It starts a new analytics
  attempt because generation failures are terminal in the existing funnel.
- Report share failure near the export actions. Keep Save image available and
  dismiss the feedback when the user tries either export again. A dismissed
  share sheet does not display an error.
- Keep focus inside the first-run dialog, start it on the title, and return it
  to the video picker on dismissal. Escape follows Skip. Shorten the English
  format, keep-open, and onboarding export hints while retaining their meaning.

Scope is the Web journey in the root React app. Reuse the current stage,
action hierarchy, colors, and three-screen structure.

## Acceptance and tests

Add browser cases for invalid media and replacement, initialization failure and
reload, a localized generation failure and retry, share failure and cancellation,
and keyboard focus when opening and dismissing the first-run dialog. Use the
existing Chromium and mobile WebKit projects and inject failure at the media,
OpenCV, processing, or share boundary. Run the existing Web and analytics
regressions, real-video smoke, unit suite, lint, typecheck, and build. Inspect
fresh browser captures for the three stages and the affected error layouts.

## Validation

- The five focused Chromium checks reproduced the missing recovery or focus
  behavior before the fix. The Web smoke suite then passed all 70 cases in
  Chromium and mobile WebKit. Eight focused cases passed again after the final
  change to the onboarding copy.
- Lint (no errors), typecheck, 62 unit tests, and the production build passed.
  The existing Playwright lint warnings and OpenCV chunk warning remain.
- A production-build Chrome run blocked the OpenCV asset, reloaded, rejected
  a corrupt MP4, and stitched and saved the repository's real recording. The
  separate repository real-video smoke passed too.
- Reviewed fresh captures of import, processing, preview, onboarding focus, and
  recovery. Share failure and cancellation were exercised at the browser API
  boundary. A physical device's system share sheet was outside this check.
