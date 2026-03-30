---
name: picsew-ios-design-evaluator
description: Review or plan Picsew native iOS UI work with a quantified, artifact-based rubric derived from Apple design guidance, Apple design videos and resources, Apple Design Awards examples, and NN/g mobile usability heuristics. Use when evaluating Picsew iPhone screens, writing UI acceptance criteria, reviewing fresh Maestro screenshots, or deciding whether a native iOS route is ready for handoff.
---

# Picsew iOS Design Evaluator

Use this skill for native iOS UI work under `apps/ios-native/`.

The goal is to turn subjective design feedback into a repeatable review gate that matches Picsew's product rules:

- one dominant stage surface per primary route
- one primary action area per screen
- artifact-based acceptance for native UI work
- shared layout consistency across upload, processing, and preview when the shell changes

## Required Inputs

- target route or routes
- the current design doc in `docs/`
- the latest route implementation or diff
- fresh screenshot artifacts from the current branch for each affected route
- error, loading, empty, and completed states when relevant

If a change affects native iOS UI, prefer repository-owned Maestro screenshot flows and the current simulator build artifacts. Do not rely on code inspection alone.

## Hard Gates

If any hard gate fails, the route is not ready for handoff even if the score is high.

1. Artifact gate: Each affected route has a fresh screenshot artifact from the current branch.
2. Stage gate: The route has one visually dominant primary stage surface.
3. Action gate: The route has one clear primary action zone when a primary action exists.
4. Fit gate: Primary content is visible without zooming or horizontal scrolling.
5. Touch gate: All tappable controls meet the `44 x 44 pt` minimum.
6. Type gate: Legible text is at least `11 pt`.
7. Recovery gate: Modal, destructive, or high-risk flows have a clear cancel, dismiss, back, confirmation, or undo path.
8. Contrast gate: Critical text and controls meet WCAG AA contrast, and critical meaning is not conveyed by color alone.
9. Accessibility gate: Custom controls and important status changes remain understandable with Dynamic Type and accessibility metadata.

## Scoring Rubric

Score each route out of `100`.

### 1. Structure And Hierarchy: 25 points

- `10`: One dominant stage surface is obvious within the first viewport.
- `5`: There is no more than one equal-weight supporting group competing with the stage.
- `5`: The primary action is visually strongest and placed in a comfortable reach zone when present.
- `5`: Secondary help is compressed into captions, chips, inline guidance, or compact rows instead of extra full cards.

### 2. Navigation And Flow: 15 points

- `5`: The route hierarchy is understandable within 3 seconds.
- `5`: Current state and progress are visible, especially in multi-step flows.
- `5`: Back, dismiss, and modal behavior are familiar and reversible.

### 3. Touch And Readability: 20 points

- `8`: Every tappable target is at least `44 x 44 pt`.
- `4`: Body or supporting text is at least `11 pt`.
- `4`: Users can see primary content without horizontal scrolling or zoom.
- `4`: Labels are plain language and positioned close to the content or control they affect.

### 4. Accessibility And Inclusion: 20 points

- `8`: Text and critical controls meet WCAG AA contrast and avoid color-only meaning.
- `4`: Dynamic Type does not break the primary route structure or primary actions.
- `4`: Important states use more than one sensory channel when practical, such as text plus icon, progress, haptic, or motion.
- `4`: Custom controls expose correct accessibility labels, values, and traits.

### 5. Error Prevention And Recovery: 10 points

- `4`: High-cost actions use confirmation, undo, or safe defaults.
- `3`: Invalid or unavailable states are constrained before failure.
- `3`: Error messages explain the problem and the next action in plain language.

### 6. Platform Fit And Polish: 10 points

- `4`: The route uses familiar iOS navigation, sheet, and control patterns instead of inventing custom behavior.
- `3`: Shell chrome, stage surfaces, and action areas use a consistent spacing and alignment system.
- `3`: Motion, materials, gradients, or haptics support the task instead of distracting from it.

## Decision Thresholds

- `90-100`: Ready. Only minor polish feedback remains.
- `85-89`: Ready with small follow-ups. No hard-gate failures allowed.
- `75-84`: Needs one more implementation pass before handoff.
- `<75`: Not ready. Rework the route structure or accessibility baseline first.

For a multi-route shell change, the overall result is the lowest route score, not the average score.

## Picsew-Specific Review Rules

1. If the shell or shared mobile structure changes, review upload, processing, and preview together.
2. Prefer one main stage card and one primary action area per screen.
3. Remove redundant helper cards before adding new ones.
4. Keep copy concise and let hierarchy do the work.
5. Treat fresh screenshots as required evidence for native UI acceptance.

## Recommended Workflow

1. Read the relevant design doc in `docs/`.
2. Gather the latest screenshots for each affected route from the current branch.
3. Run the hard gates first.
4. Score each route with the rubric.
5. List findings as `P0`, `P1`, or `P2`.
6. Decide `Ready`, `Ready with follow-ups`, or `Iterate`.
7. If this is a shared UI change, do one final consistency pass across upload, processing, and preview.

## Severity Guide

- `P0`: Hard-gate failure or a problem that blocks release confidence.
- `P1`: High-value fix that materially improves comprehension, usability, or accessibility.
- `P2`: Polish or consistency improvement that can land in a follow-up.

## Output Template

```md
Route: <name>
Artifacts:

- <screenshot path or flow name>

Hard gates:

- Pass | Fail: Artifact
- Pass | Fail: Stage
- Pass | Fail: Action
- Pass | Fail: Fit
- Pass | Fail: Touch
- Pass | Fail: Type
- Pass | Fail: Recovery
- Pass | Fail: Contrast
- Pass | Fail: Accessibility

Score:

- Structure and hierarchy: <x>/25
- Navigation and flow: <x>/15
- Touch and readability: <x>/20
- Accessibility and inclusion: <x>/20
- Error prevention and recovery: <x>/10
- Platform fit and polish: <x>/10
- Total: <x>/100

Findings:

- P0: ...
- P1: ...
- P2: ...

Decision:

- Ready | Ready with follow-ups | Iterate
```

## Reference Notes

Read [references/source-notes.md](references/source-notes.md) when you need the rationale behind the rubric or the source-to-rule mapping.
