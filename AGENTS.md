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
