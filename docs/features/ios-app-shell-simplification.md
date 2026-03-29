---
title: iOS App Shell Simplification
issue: ios-app-shell-simplification
author: Jayson Albert
date: 2026-03-29
updated: 2026-03-29
version: 0.1.0
reviewers: [Jayson Albert]
tags: [ios, ui, ux, mobile, design]
source_code:
  - src/App.tsx
  - src/components/VideoUpload.tsx
  - src/components/ProcessingView.tsx
  - src/components/PreviewView.tsx
  - src/index.css
status: approved
---

# iOS App Shell Simplification

## Summary

- **Problem**: The current iOS app shell still feels like a compressed web landing page. The header repeats the product title and subtitle, the persistent three-step navigation consumes prime screen space, and multiple helper blocks repeat the same message.
- **Goal**: Redesign the iOS app around a calmer native-tool pattern: one-time onboarding, one primary task per screen, and a lighter shell that gives the content room to breathe.
- **Scope**:
  - simplify the persistent iOS header
  - remove the always-visible three-step navigation from the main shell
  - define a one-time onboarding flow
  - reduce duplicated information across upload, processing, and preview
  - keep the current core actions intact: import, process, save, share, restart

## Current Information Audit

### Upload Screen

**Currently shown**:

- app header card
- app name
- app subtitle
- feedback button
- language switcher
- three-step persistent navigation
- stage kicker
- stage title
- stage description
- upload drop zone
- photos/files buttons
- three instruction chips
- selected video card
- start button

**Redundancy and issues**:

- The app name and subtitle appear in both the top shell and the stage card.
- The three-step navigation behaves like tabs, but the flow is linear and not user-driven.
- The instruction chips restate the same promise already implied by the product.
- The upload screen is doing branding, onboarding, and action guidance all at once.

### Processing Screen

**Currently shown**:

- same header card
- same three-step persistent navigation
- stage kicker
- stage title
- stage description
- large spinner orb
- progress bar
- milestone list
- inline helper note

**Redundancy and issues**:

- The header and navigation remain visible even though the user cannot meaningfully navigate during processing.
- The current stage is repeated in the kicker, progress line, and helper note.
- Too many elements compete with the actual progress state.

### Preview Screen

**Currently shown**:

- same header card
- same three-step persistent navigation
- completion badges
- stage kicker
- stage title
- stage description
- preview image surface
- helper hint
- save/download button
- share button
- restart button

**Redundancy and issues**:

- The screen uses multiple status labels to communicate a single fact: processing is complete.
- The persistent shell still takes vertical space away from the preview.
- The helper hint under the preview is non-essential on every run.

## Design Direction

### Core Product Principle

Picsew on iPhone should feel like a focused utility, not a mini marketing page. The UI should prioritize:

- one primary task per screen
- minimal persistent chrome
- generous vertical space for content
- actions near the thumb zone
- short, calm copy

### Shell Strategy

Replace the current large branded header and persistent three-step navigation with a **compact utility bar**.

**Utility bar contents**:

- left: app glyph only, or glyph plus a very small wordmark
- right: a single utility button that opens a sheet

**Utility sheet contents**:

- feedback
- language
- future settings/about entry

This removes two always-visible buttons and avoids turning support actions into primary UI.

### Onboarding Strategy

The three-step explanation should not live in the shell forever. Convert it into a **first-launch onboarding flow** shown only once.

**Recommended onboarding structure**:

1. Import a screen recording
2. We stitch it locally on your device
3. Save or share the long screenshot

**Rules**:

- show only on first launch
- allow skip
- provide a final primary CTA: `Start`
- persist completion locally

## Proposed Screen Architecture

### 1. Upload Screen

**Purpose**: choose a video and start processing

**Keep**:

- compact utility bar
- one main stage card
- upload drop zone or selected video preview
- Photos / Files entry points
- primary CTA when a video is selected

**Remove**:

- large branded header card
- persistent three-step navigation
- repeated app title/subtitle inside the stage card
- three separate instruction chips

**New copy hierarchy**:

- title: `Select a screen recording`
- support line: one short sentence only, for example `Import a scrolling screen recording to generate one long image.`

**Layout**:

- top utility bar
- main stage card
- sticky bottom primary CTA only when a video is selected

### 2. Processing Screen

**Purpose**: reassure progress with minimal distraction

**Keep**:

- compact utility bar
- one centered progress stage
- current processing label
- progress percentage or bar

**Simplify**:

- reduce milestones to either a small `Step 2 of 3` label or a tiny three-dot indicator
- remove extra helper note if it repeats the same stage text

**Layout**:

- top utility bar
- vertically centered processing card
- one secondary line like `Keep this screen open`

### 3. Preview Screen

**Purpose**: review the result and export it

**Keep**:

- compact utility bar
- one compact success state
- large preview surface
- sticky export actions

**Remove**:

- multiple completion badges
- helper note under the preview unless it communicates something truly new

**Layout**:

- top utility bar
- compact success row: icon + `Long screenshot ready`
- main preview surface
- sticky bottom action bar:
  - primary: Save
  - secondary: Share
  - tertiary text action: New capture

## Visual Direction

### Look And Feel

- native iOS utility feel
- white and soft-gray surfaces
- subtle blue accent for active actions
- less gradient-heavy branding in the persistent shell
- rounded cards, but fewer of them
- stronger whitespace and vertical rhythm

### Typography

- product name should not dominate every screen
- use one strong task title per screen
- use smaller secondary copy
- remove all-caps marketing-style eyebrow text when it does not add meaning

### Motion

- onboarding can use a soft page transition
- processing can keep one restrained animated focal element
- avoid decorative motion in the shell

## Proposed Final Decision

### Approve This As The Target iOS Structure

**Persistent shell**:

- safe-area aware compact utility bar
- no persistent progress navigation

**First launch only**:

- three-step onboarding walkthrough

**Upload**:

- one main task title
- one upload stage card
- native import options
- one primary CTA

**Processing**:

- one centered progress experience
- compact contextual status only

**Preview**:

- one compact success line
- one large preview
- one sticky action bar

## Acceptance Criteria

- [ ] AC-01: The iOS app no longer uses a large always-visible marketing header.
- [ ] AC-02: The persistent three-step navigation is removed from the main shell.
- [ ] AC-03: The app introduces a first-launch onboarding flow for the three-step explanation.
- [ ] AC-04: Each screen keeps one primary title and avoids repeating the app title/subtitle unnecessarily.
- [ ] AC-05: Upload, processing, and preview each have a clearer single-focus layout.

## Planned Tests

- add or update the smallest interaction test that proves the first-launch onboarding appears once and can be dismissed
- update the main smoke test to validate the simplified upload shell
- verify the compact shell and sticky actions on iPhone viewport
