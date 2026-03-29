---
title: iOS Preview UI Refresh
issue: ios-preview-ui-refresh
author: Jayson Albert
date: 2026-03-29
updated: 2026-03-29
version: 0.1.0
reviewers: [Jayson Albert]
tags: [ios, ui, preview, design]
source_code:
  - src/App.tsx
  - src/components/PreviewView.tsx
  - src/components/PreviewView.test.tsx
  - src/index.css
  - src/locales/en.json
  - src/locales/zh.json
status: approved
---

# iOS Preview UI Refresh

## Summary

- **Problem**: The current preview page is functionally complete but still looks like a stacked web page, especially on iPhone.
- **Goal**: Make the final result screen feel cleaner and more native to modern iOS utility apps while keeping the current React structure.
- **Scope**:
  - redesign the preview result card hierarchy
  - introduce a calmer completion banner
  - move primary actions into a sticky bottom action tray
  - keep the screen simple and focused on the generated long screenshot

## Current Issues

1. The preview screen is visually fragmented into too many similar cards.
2. The result image lacks a clear “stage” or focal area.
3. The primary actions do not feel anchored to the bottom of the experience.
4. The current blue tips card adds noise after the task is already complete.

## Design Choice

### ADR-001: Use a result-stage layout with a sticky bottom action tray

**Status**: Accepted

**Decision**:

- Keep the existing app shell, header, and stepper.
- Redesign only the preview page into three layers:
  - a lightweight completion banner
  - a prominent result stage with a framed preview surface
  - a sticky bottom action tray for save/share/restart
- Replace the extra tips card with a tighter inline hint inside the result stage.

**Why**:

- This matches current iOS tool design patterns better than a long stack of equal cards.
- It keeps the screenshot preview as the visual hero.
- It improves thumb reach by anchoring primary actions near the bottom safe area.

## Acceptance Criteria

- [ ] AC-01: The preview screen has a clearer visual hierarchy than the current stacked-card layout.
- [ ] AC-02: The generated image sits inside a dedicated preview stage that is scrollable without dominating the whole screen.
- [ ] AC-03: Save/share actions are grouped in a sticky bottom tray that respects the iPhone bottom safe area.
- [ ] AC-04: The preview page removes the separate tips card and keeps guidance concise.

## Test Plan

- `npm run test:unit`
- `npm run typecheck`
- `npm run build`
- `npm run lint`
- `npm run test:e2e:smoke -- --grep "home page shows upload flow|feedback dialog opens from header trigger|feedback dialog stays inside the viewport on mobile"`
