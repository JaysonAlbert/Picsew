---
title: iOS Feedback Page
issue: ios-feedback-page
author: Jayson Albert
date: 2026-03-29
updated: 2026-03-29
version: 0.1.0
reviewers: [Jayson Albert]
tags: [ios, feedback, ui, ux]
source_code:
  - src/App.tsx
  - src/components/AppUtilityMenu.tsx
  - src/components/FeedbackDialog.tsx
  - src/components/FeedbackPage.tsx
  - src/index.css
status: approved
---

# iOS Feedback Page

## Summary

- **Problem**: After moving support actions into the utility menu, the feedback experience is still presented as a dialog. On iPhone, a long multi-field form feels cramped inside a modal and competes with keyboard and safe-area constraints.
- **Goal**: Convert feedback from a modal interaction into a dedicated page reached from the utility menu, while keeping the existing submission behavior and feedback categories.
- **Scope**:
  - replace the menu-triggered feedback dialog with a feedback page
  - keep the same feedback categories and payload structure
  - reuse one shared form implementation so validation and submission logic stay in one place
  - update smoke tests to cover the new page flow

## Design Choice

### ADR-001: Use a dedicated feedback page instead of a dialog

**Status**: Accepted

**Decision**:

- Tapping `Feedback` in the utility menu should navigate to a dedicated in-app feedback page.
- The feedback page should use the same app shell family, but with a simpler top bar:
  - back button on the left
  - page title in the center/leading area
- The existing feedback submission logic should move into a reusable form component so the product has one feedback implementation.

**Why**:

- A full page is a better fit for a long-form input flow on iPhone.
- The feedback page can breathe, scroll naturally, and feel closer to native app expectations.
- Reusing the form logic avoids drift between page and modal variants.

## Proposed UX

### Entry

- user opens the utility menu
- user taps `Feedback`
- app closes the menu and opens the feedback page

### Feedback Page Structure

- compact top bar with back affordance
- page title: `Feedback`
- short intro text
- one main feedback card containing the full form
- sticky or bottom-aligned primary submit button only if it improves mobile ergonomics

### Data And Behavior

- keep current categories:
  - bug report
  - feature request
  - processing failure
- keep diagnostic context attached automatically
- keep current success and error states

## Acceptance Criteria

- [ ] AC-01: Feedback is opened as a page from the utility menu instead of a dialog.
- [ ] AC-02: The feedback form logic remains shared and does not fork into multiple implementations.
- [ ] AC-03: The feedback page supports scrolling and keyboard-safe usage on mobile.
- [ ] AC-04: Existing submission behavior and payload shape remain unchanged.
- [ ] AC-05: Smoke coverage validates the menu -> feedback page flow.

## Planned Tests

- update smoke test to assert feedback opens as a page and not a dialog
- add the smallest useful unit test covering the feedback page shell
- run `npm run typecheck`
- run `npm run test:unit`
- run `npm run build`
- run `npm run lint`
- run `npm run test:e2e:smoke`
