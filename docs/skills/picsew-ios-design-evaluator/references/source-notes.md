---
title: Picsew iOS Design Evaluator Source Notes
issue: picsew-ios-design-evaluator
author: Codex
date: 2026-03-31
updated: 2026-03-31
version: 0.1.0
reviewers: [Jayson Albert]
tags: [ios, ui, design, accessibility, heuristics, skill]
source_code:
  - docs/skills/picsew-ios-design-evaluator/SKILL.md
status: approved
---

# Picsew iOS Design Evaluator Source Notes

## Summary

- **Problem**: Picsew's native iOS UI work needs a shared review language that is less subjective than "looks better" or "feels more native".
- **Goal**: Compress Apple and NN/g guidance into a project-local review skill with measurable checks, clear pass gates, and a repeatable scoring model.
- **Scope**:
  - translate platform guidance into route-level evaluation criteria
  - prefer checks that can be validated from code, screenshots, simulator state, or accessibility inspection
  - align the rubric with Picsew's existing UI and handoff rules

## Design Choice

### ADR-001: Use hard gates plus weighted scoring

**Status**: Accepted

**Decision**:

- Use a two-layer review model:
  - `hard gates` for baseline correctness and accessibility
  - `weighted scoring` for hierarchy, flow, polish, and consistency
- Make the lowest affected route score the release score for shared shell changes.

**Why**:

- Apple and NN/g guidance includes both non-negotiable basics and softer quality signals.
- A pure checklist is too coarse; a pure score is too easy to game.
- Picsew's artifact-based iOS workflow benefits from route-by-route evidence.

## Source Extraction

### Apple: UI Design Dos and Don'ts

Source: [UI Design Dos and Don’ts](https://developer.apple.com/design/tips/)

Key takeaways used in the rubric:

- primary content should fit the device screen without zooming or horizontal scrolling
- touch controls should be designed for touch gestures
- hit targets should be at least `44 x 44 pt`
- text should be at least `11 pt`
- content and controls should be organized and aligned so relationships are obvious

Mapped rules:

- hard gates `Fit`, `Touch`, `Type`
- scoring sections `Touch and Readability` and part of `Structure and Hierarchy`

### Apple: Human Interface Guidelines

Source: [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

Key takeaways used in the rubric:

- clear hierarchy helps people distinguish controls from content
- harmony means aligning interface elements with system expectations instead of fighting them

Mapped rules:

- hard gate `Stage`
- scoring sections `Structure and Hierarchy` and `Platform Fit and Polish`

### Apple: Navigation Design

Source: [Explore navigation design for iOS](https://developer.apple.com/videos/play/wwdc2022/10001/)

Key takeaways used in the rubric:

- familiar navigation patterns reduce confusion
- navigation should reflect content hierarchy and task structure
- tabs, stacks, and modality should be used intentionally, not mixed carelessly

Mapped rules:

- hard gate `Recovery`
- scoring section `Navigation and Flow`

### Apple: Inclusive Design And Accessibility

Sources:

- [Principles of inclusive app design](https://developer.apple.com/videos/play/wwdc2025/316/)
- [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

Key takeaways used in the rubric:

- support multiple senses instead of relying on a single channel
- provide customization and avoid assumption-driven design
- adopt accessibility APIs and keep track of inclusion debt
- accessible interfaces should be intuitive, perceivable, and adaptable

Mapped rules:

- hard gates `Contrast` and `Accessibility`
- scoring section `Accessibility and Inclusion`

### Apple: Official Resources And Exemplars

Sources:

- [Apple Design Resources](https://developer.apple.com/design/resources/)
- [Apple Design Awards 2025](https://developer.apple.com/design/awards/)

Key takeaways used in the rubric:

- use official UI kits to reduce layout drift from platform conventions
- high-quality apps consistently show strong hierarchy, inclusivity, delightful interaction, and visual restraint

Mapped rules:

- scoring section `Platform Fit and Polish`
- supporting guidance for route consistency and shell reviews

### NN/g: General Heuristics

Source: [10 Usability Heuristics for User Interface Design](https://www.nngroup.com/articles/ten-usability-heuristics/)

Key takeaways used in the rubric:

- visibility of system status
- match between system and the real world
- user control and freedom
- consistency and standards
- error prevention
- recognition rather than recall
- aesthetic and minimalist design
- help users recover from errors

Mapped rules:

- hard gate `Recovery`
- scoring sections `Navigation and Flow`, `Error Prevention and Recovery`, and `Structure and Hierarchy`

### NN/g: Mobile UX

Source: [Mobile UX: Study Guide](https://www.nngroup.com/articles/mobile-ux-study-guide/)

Key takeaways used in the rubric:

- mobile navigation should stay simple and legible
- secondary content should be deferred or compressed
- mobile input and list patterns should minimize cognitive load
- touch-target sizing, input clarity, and content prioritization matter more on mobile than desktop

Mapped rules:

- hard gate `Stage`
- scoring sections `Structure and Hierarchy`, `Navigation and Flow`, and `Touch and Readability`

## Picsew-Specific Adaptation

The generic guidance above was tightened to match Picsew's repository rules:

1. One dominant stage surface per route became a hard gate.
2. One primary action area per screen became a hard gate when a route has a primary action.
3. Native UI acceptance requires fresh current-branch artifacts.
4. Shared shell changes must be judged across upload, processing, and preview together.
5. Redundant helper cards are treated as a hierarchy smell, not harmless decoration.

## Acceptance Criteria

- [ ] AC-01: The skill defines pass or fail hard gates for baseline iOS usability and accessibility.
- [ ] AC-02: The skill defines a `100` point scoring system with named sections and explicit thresholds.
- [ ] AC-03: The skill maps each major rule back to an Apple or NN/g source family.
- [ ] AC-04: The skill includes Picsew-specific evaluation rules for stage, action area, and screenshot-based acceptance.
- [ ] AC-05: The skill can be used directly as a review prompt or evaluator checklist without extra rewriting.

## Planned Validation

- verify the skill reads cleanly as a standalone prompt
- run markdown formatting validation with Prettier if available in the repository

## Known Limits

- Aesthetic judgment is still partly qualitative; the score reduces subjectivity but does not eliminate it.
- Some accessibility checks need simulator or inspector support and cannot be proven from screenshots alone.
- The rubric intentionally favors iPhone route reviews; iPad or macOS adaptations should extend rather than replace it.
