# Picsew Product Roadmap v1

Last updated: 2026-03-29

## Product Direction

Picsew will evolve as a dual-surface product:

- `Web`: public entry point for discovery, sharing, SEO, and lightweight one-off use.
- `iOS`: installable experience for repeat users who want speed, convenience, and deeper device integration.

Early-stage strategy:

- Keep the product fully free to maximize adoption.
- Prioritize output quality, success rate, and clear recovery paths.
- Build structured user feedback and product analytics before monetization.
- Delay ads and subscriptions until repeat usage patterns are clear.

## 12-Month Roadmap

### Phase 1: Stability and Feedback Foundation

Target window: Month 0 to Month 2

Goals:

- Improve processing success rate on common videos.
- Make failures understandable and actionable.
- Add a structured path for bug reports and feature requests.
- Establish a minimal but consistent analytics vocabulary.

Scope:

- Processing funnel analytics for upload, processing, preview, and export.
- Structured feedback schemas for web and future iOS forms.
- FAQ, example videos, and self-serve diagnostics.
- Error reporting pipeline with relevant processing metadata.

Success metrics:

- Upload-to-processing conversion is measurable.
- Processing success rate is measurable.
- Failure reports contain enough context to reproduce major issues.

### Phase 2: iOS v1 Launch

Target window: Month 2 to Month 4

Goals:

- Ship an installable iOS app that feels meaningfully more convenient than the mobile web experience.
- Reuse the existing web UI where it accelerates delivery.
- Add the native capabilities users expect from a repeat-use tool.

P0 capabilities:

- Import a video from Photos or Files.
- Run processing locally.
- Save the result to Photos.
- Share the generated screenshot.
- Show processing progress and basic diagnostics.
- Provide feedback and support entry points from inside the app.

P1 capabilities:

- Keep a local history of recent outputs.
- Remember the last-used options.
- Add a first-run guide and retry path after a failure.

Success metrics:

- App Store-ready release with clear native value.
- First cohort of repeat users returning to the app.

### Phase 3: Retention and Product Learning

Target window: Month 4 to Month 8

Goals:

- Turn free users into repeat users.
- Improve the quality of product decisions by using structured feedback and analytics.
- Identify the top failure modes and top requested improvements.

Scope:

- Shared feedback inbox for web and iOS.
- Triage workflow for bug reports, feature requests, and processing failures.
- Release notes cadence and improvement visibility.
- Better history, retry, and common export presets.

Success metrics:

- Top 3 failure reasons are known and tracked.
- Top 3 requested features are known and ranked.
- Retention and repeat export patterns are measurable.

### Phase 4: Foundation for Future Monetization

Target window: Month 8 to Month 12

Goals:

- Decide whether Picsew should evolve toward a pro tool, a convenience tool, or both.
- Prepare for future monetization without shipping monetization too early.

Possible next steps:

- Accounts and sync, if users need cross-device continuity.
- Advanced export modes, if quality and control drive demand.
- Paid tiers only after clear usage signals emerge.

## Feedback System Design

Picsew should support three structured feedback flows:

1. `bug_report`
2. `feature_request`
3. `processing_failure`

Suggested storage fields:

| Field          | Type            | Notes                                                 |
| -------------- | --------------- | ----------------------------------------------------- |
| `id`           | UUID            | Primary key                                           |
| `created_at`   | ISO timestamp   | Submission time                                       |
| `status`       | enum            | `new`, `triaged`, `closed`                            |
| `source`       | enum            | `web_form`, `ios_form`, `manual_import`               |
| `category`     | enum            | `bug_report`, `feature_request`, `processing_failure` |
| `platform`     | enum            | `web`, `ios`                                          |
| `app_version`  | string          | Web build or iOS version                              |
| `locale`       | string          | User locale                                           |
| `email`        | string nullable | Optional contact                                      |
| `message`      | text            | User-written summary                                  |
| `triage_notes` | text nullable   | Internal notes                                        |

Category-specific fields:

### Bug report

- `stage`
- `severity`
- `device_model`
- `os_version`
- `browser_or_app_version`
- `video_duration_seconds`
- `video_width`
- `video_height`
- `log_excerpt`
- `screenshot_url`
- `sample_video_consent`

### Feature request

- `use_case`
- `requested_feature`
- `frequency`
- `willing_to_test_beta`

### Processing failure

- `stage`
- `error_code`
- `error_message`
- `pipeline_step`
- `memory_mode`
- `video_duration_seconds`
- `video_width`
- `video_height`
- `device_model`
- `os_version`
- `browser_or_app_version`
- `log_excerpt`
- `sample_video_consent`

## Analytics Event Vocabulary

Picsew should keep event naming stable across web and iOS:

| Event                  | Meaning                           |
| ---------------------- | --------------------------------- |
| `upload_started`       | User selected or dropped a video  |
| `upload_completed`     | Video metadata became available   |
| `processing_started`   | Processing pipeline began         |
| `processing_completed` | Processing finished successfully  |
| `processing_failed`    | Processing ended in a failure     |
| `preview_shown`        | User saw the result preview       |
| `export_started`       | User initiated a download or save |
| `export_completed`     | Export action completed           |
| `feedback_opened`      | User opened the feedback flow     |
| `feedback_submitted`   | User submitted feedback           |

Recommended shared properties:

- `platform`
- `video_mime`
- `video_extension`
- `video_size_mb_bucket`
- `video_duration_bucket`
- `video_width`
- `video_height`
- `video_resolution_bucket`
- `processing_time_ms`
- `error_message`
- `upload_source`

## Capacitor iOS Adoption Checklist

### App shell

- Add Capacitor to the existing Vite app.
- Create an iOS target and verify local dev builds.
- Confirm routing, static asset loading, and local file handling.

### Native device capabilities

- Photo library import
- Files import
- Save to Photos
- Share sheet
- Basic app settings and diagnostics surface

### Feedback and diagnostics

- Feedback screen in the app
- One-tap copy of diagnostic information
- Structured failure report payloads matching the shared schemas

### Product polish

- Recent history
- Last-used settings
- First-run guidance
- FAQ / support entry point

### Future native upgrades

- Optional Swift-based processing helpers
- Optional native export pipeline for heavier jobs
- Optional move of selected performance-critical steps out of the web layer

## Immediate Next Tasks

1. Add a feedback data model and validation schemas to the web codebase.
2. Standardize analytics event constants and start using them in the current web funnel.
3. Build a simple feedback UI that writes to the chosen backend.
4. Prepare the Capacitor iOS shell once feedback and analytics are in place.
