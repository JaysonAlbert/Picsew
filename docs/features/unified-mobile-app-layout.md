---
title: Unified Mobile App Layout
issue: unified-mobile-app-layout
author: Jayson Albert
date: 2026-03-29
updated: 2026-03-29
version: 0.1.0
reviewers: [Jayson Albert]
tags: [ios, mobile, ui, redesign]
source_code:
  - src/App.tsx
  - src/components/VideoUpload.tsx
  - src/components/ProcessingView.tsx
  - src/components/PreviewView.tsx
  - src/components/VideoUpload.test.tsx
  - src/components/ProcessingView.test.tsx
  - src/components/PreviewView.test.tsx
  - src/index.css
status: approved
---

# Unified Mobile App Layout

## Summary

- **Problem**: The current upload, processing, and preview screens were iterated independently, so the app now feels visually inconsistent and too busy on mobile.
- **Goal**: Redesign all three screens around one shared mobile layout language that feels concise, calm, and app-first.
- **Scope**:
  - unify header and stepper styling
  - redesign upload, processing, and preview around a shared stage-card layout
  - remove redundant helper cards while keeping the core actions obvious
  - add small regression tests for the three primary screens

## Current Issues

1. The header, stepper, and screen bodies feel like separate systems instead of one app shell.
2. Each screen uses different card density and action placement.
3. Guidance text is repeated in several places and competes with the primary actions.
4. The final UI feels heavier and more web-like than a modern iOS utility app should.

## Design Choice

### ADR-001: One shell, one stage card, one action tray language

**Status**: Accepted

**Decision**:

- Use one shared visual language across all three pages:
  - glassy shell card for brand and stepper
  - single primary stage card per screen
  - sticky bottom action tray only when a primary action exists
- Reduce copy and secondary decorations.
- Keep the feature flow identical, but make the interaction hierarchy simpler.

**Why**:

- This creates a coherent mobile experience without rewriting business logic.
- A single stage-card pattern is easier to maintain than styling each screen separately.
- The design better matches current iOS utility app conventions: focused content, soft surfaces, restrained color, and stronger thumb-zone actions.

## Acceptance Criteria

- [ ] AC-01: Upload, processing, and preview screens visibly share the same shell and stage-card structure.
- [ ] AC-02: Redundant helper sections are removed or compressed into lighter inline guidance.
- [ ] AC-03: Core actions stay obvious, especially on iPhone-sized screens.
- [ ] AC-04: The upload, processing, and preview components each have a lightweight automated regression test.

## Test Plan

- `npm run test:unit`
- `npm run typecheck`
- `npm run build`
- `npm run lint`
- `npm run test:e2e:smoke -- --grep "home page shows upload flow|feedback dialog opens from header trigger|feedback dialog stays inside the viewport on mobile"`
