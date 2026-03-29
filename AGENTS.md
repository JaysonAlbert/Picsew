# AGENTS

## Development Workflow

All feature work, bug fixes, and meaningful product changes in this repository should follow this order:

1. Document first.
2. Implement second.
3. Test before handoff.

## Documentation First

- Create or update a document in `docs/` before changing production code.
- The document should describe the problem, scope, design choice, acceptance criteria, and planned tests.
- If the scope changes during development, update the document before or alongside the code change.

## Testing Is Required

- Every completed feature or bug fix must be tested before it is considered done.
- Prefer the smallest useful automated test that proves the user-facing behavior.
- When the change affects UI flows, add or update an end-to-end or interaction test.
- When the change affects core logic, add or update unit tests.
- If a test cannot be run, call that out clearly in the final handoff.

## Definition Of Done

- Documentation is updated.
- Code is implemented.
- Relevant tests are added or updated.
- Relevant tests are run locally.
- Any known limitations or follow-up risks are stated explicitly.

## Git Delivery Workflow

- For follow-up feature work and bug fixes, if the relevant local validation passes, Codex should proactively finish the delivery flow without waiting for an extra prompt.
- The default validation gate is:
  - `lint` has no errors.
  - Relevant tests pass.
  - Any required type checks or builds pass.
- After the validation gate is satisfied, Codex should:
  1. Commit the changes.
  2. Push the working branch.
  3. Open a PR/MR.
  4. Enable auto-merge when the repository settings allow it.
- If validation is not clean, Codex should stop before delivery and report the blocker clearly.

## Branch Scope

- Start new work from the latest `main`.
- Keep each branch focused on one concern only:
  - one feature
  - one bug fix
  - one infra or config cleanup
- Do not mix unrelated UI, native config, analytics, and processing changes in the same delivery branch unless they are directly coupled.

## Web And iOS Product Rule

- Treat Picsew as one product with two surfaces: Web and iOS.
- Shared product decisions should consider the full upload -> processing -> preview journey, not just one screen in isolation.
- When changing shared mobile UI structure, review all three primary screens for consistency before handoff.

## iOS Project Rules

- The `ios/` directory is source code and should remain in git.
- Build output, generated artifacts, and machine-local state should stay ignored.
- Do not remove the iOS project from version control just because Capacitor generated the initial shell.
- When changing iOS project configuration or native code, run a simulator build validation before handoff.

## Local Config And Secrets

- Never commit machine-local Apple signing data or other account-specific identifiers directly into shared project settings when a local config override can be used.
- Prefer committed shared config plus ignored local override files.
- Every ignored local config should have a committed example template when practical.
- If Xcode writes local signing metadata back into `project.pbxproj`, move it into local config or revert it before merge.

## Release And App Identity Rules

- Keep iOS app display name, bundle identifier, marketing version, and build number in committed shared `xcconfig`, not as ad hoc Xcode-only edits.
- Keep local signing overrides separate from shared release metadata.
- When preparing an iOS release, update the committed release metadata intentionally and review it as part of the PR diff.
- Follow `docs/ios-release-checklist.md` for iOS release prep and validation.

## UI Design Rules

- Prefer one main stage card and one primary action area per screen.
- Remove redundant helper cards before adding new ones.
- Keep copy concise and let hierarchy do the work.
- UI redesign work should document the intended shell, stage, and action structure before implementation.

## Validation Additions

- Shared UI changes should include the smallest useful regression test for the affected screen structure.
- iOS project or signing changes should include an `xcodebuild` simulator verification when feasible.
- If validation is skipped because a tool is unavailable, call that out explicitly in the handoff.
