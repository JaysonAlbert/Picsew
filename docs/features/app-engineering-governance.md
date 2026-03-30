---
title: App Engineering Governance
issue: app-engineering-governance
author: Jayson Albert
date: 2026-03-29
updated: 2026-03-30
version: 0.1.0
reviewers: [Jayson Albert]
tags: [governance, process, ios, web, engineering]
source_code:
  - AGENTS.md
status: approved
---

# App Engineering Governance

## Summary

- **Problem**: Picsew is now a real dual-surface product with shared web logic and a native iOS shell, but the repository rules still mostly describe generic coding workflow.
- **Goal**: Add clearer engineering governance so future work stays consistent, avoids local-config leakage, and keeps the mobile app maintainable.
- **Scope**:
  - define how iOS project files should be managed
  - define how local-only config should be handled
  - define branch and PR scope rules
  - define extra validation rules for native and shared UI changes
  - require an artifact-backed evaluator loop for native iOS UI work

## Design Choice

### ADR-001: Treat Picsew as one product with two surfaces

**Status**: Accepted

**Decision**:

- Keep shared product logic and copy aligned across web and iOS.
- Keep the iOS project committed as source, not as disposable generated output.
- Keep local machine and account-specific settings out of committed project files.
- Require stronger validation when a change touches native app configuration or shared mobile UI.

**Why**:

- The iOS app is now part of the product, not a temporary wrapper.
- Without stricter rules, it is easy for local signing settings, Xcode noise, or inconsistent UI changes to accumulate.
- A small set of explicit repository rules will reduce accidental regressions and messy PRs.

## Recommended Governance Rules

### 1. Branch and PR Scope

- Start each task from the latest `main`.
- Keep each branch focused on one concern:
  - one feature
  - one bug fix
  - one infra/config cleanup
- Do not mix UI redesign work with unrelated native config or analytics work unless they are directly coupled.

### 2. iOS Project Management

- The `ios/` project remains in git because it contains real app source and project structure.
- Generated assets and build output stay ignored.
- Account-specific signing data must not live permanently in committed project settings.
- Prefer committed shared `xcconfig` plus ignored local override files for machine-specific values.

### 3. Local Config Management

- Every ignored local config should have a committed example template.
- Shared code should reference stable variables, not personal values.
- If Xcode writes account-specific values back into `project.pbxproj`, move them into local config or revert them before merge.

### 4. Validation Requirements

- If a change touches `ios/`, run a simulator build check.
- If a change touches shared UI structure, validate all three product states:
  - upload
  - processing
  - preview
- If a change affects shared flows, update or add the smallest regression test that proves the new structure.

### 5. Native iOS Evaluator Loop

- Treat `xcodebuild` and Swift tests as necessary but not sufficient for native iOS UI work.
- If a native iOS change affects screen structure, layout, styling, copy hierarchy, or primary actions, run repository-owned Maestro flows for the affected routes and capture fresh screenshot artifacts from the current change.
- Review those fresh artifacts in a dedicated evaluator pass that is separate from implementation.
- Prefer a dedicated evaluator prompt or sub-agent when available; otherwise perform an explicit self-review pass after automation finishes.
- If the evaluator finds a design or UX mismatch, continue the implement -> validate -> review loop until the evaluator passes or a concrete blocker is reported.

### 6. UI Acceptance Rules

- Do not claim a native iOS UI change is complete based only on code inspection.
- The actual simulator output must match the intended shell, stage, and action hierarchy described in docs.
- Final handoff for native iOS UI work should name the automation flows that ran, whether screenshots were captured, and whether the evaluator passed.

### 7. UI Consistency Rules

- Treat upload, processing, and preview as one continuous product journey.
- Avoid adding one-off decorative cards or helper panels to only one screen.
- Prefer one main stage card and one primary action area per screen.
- Reduce copy before adding new UI containers.

## Acceptance Criteria

- [ ] AC-01: `AGENTS.md` documents the repository-level governance rules for app work.
- [ ] AC-02: The new rules cover iOS project handling, local config handling, validation, and PR scope.
- [ ] AC-03: Future contributors can follow the rules without relying on thread history.
- [ ] AC-04: Native iOS UI work requires artifact-backed evaluator review, not just code-level validation.
