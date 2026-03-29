---
status: approved
---

# Native iOS Migration Phase 1

## TL;DR

Picsew will move to a dual-surface structure: the existing web app remains online in maintenance mode, while iOS becomes a fully native product. Phase 1 sets the repository shape, migration rules, and algorithm parity baseline without breaking the current web deploy path. The stitching algorithm stays logically identical during migration and must be validated against the existing TypeScript implementation.

## Terms

- Native iOS app: The new Swift-based iPhone app that becomes the primary mobile product.
- Reference algorithm: The current TypeScript implementation used as the migration baseline.
- Parity fixture: A sample video and expected intermediate/final outputs used to confirm the native port matches the reference behavior.

## Problem

The current repository grew around a web-first architecture and a Capacitor-based iOS shell. That made it fast to validate product ideas, but it now blocks the long-term iOS goals:

- UI and interaction patterns are still shaped by the web shell.
- Performance and memory tuning remain constrained by the web stack.
- The repository does not clearly separate the long-lived web surface from the future native iOS product.
- The core algorithm exists only in the TypeScript codebase, so there is no explicit migration contract for preserving behavior.

## Scope

### In scope

- Define the target dual-platform repository structure.
- Scaffold the new top-level directories needed for the migration.
- Document how the current web app, current Capacitor shell, and future native iOS app relate to each other.
- Define algorithm migration guardrails and parity expectations.
- Update repository rules so future work follows the new structure.

### Out of scope

- Rewriting the algorithm in Swift in this phase.
- Moving the live web app out of the repository root in this phase.
- Deleting the existing Capacitor `ios/` shell in this phase.
- Changing the production deployment workflow in this phase.

## Acceptance Criteria

- [ ] AC-01: [P0] The repository contains an approved migration design that defines the target dual-platform structure and the staged rollout plan.
  - Given the current repo layout still powers the live web deploy
  - When a developer starts native iOS migration work
  - Then they can see which directories are target-state, which paths remain transitional, and what not to move yet
- [ ] AC-02: [P0] The repository includes scaffolding for `apps/`, `reference/`, `fixtures/`, and `infra/`.
  - Given a fresh clone of the repo
  - When a developer inspects the new directories
  - Then each directory clearly states its responsibility and relationship to the current root-based layout
- [ ] AC-03: [P0] Algorithm migration rules explicitly require logical parity with the current TypeScript implementation until a replacement is intentionally approved.
  - Given a future native implementation change
  - When the algorithm pipeline is ported from TypeScript to Swift
  - Then the migration documentation requires fixture-based comparison before behavior changes are accepted
- [ ] AC-04: [P1] Repository governance documents reflect the new web-maintenance plus native-iOS-primary strategy.

## Design

### ADR-001

- Status: Accepted
- Context: Picsew must support a stable public web surface while evolving into a high-quality native iOS product.
- Decision: Keep a single repository, preserve the current root-based web app temporarily, and introduce target-state directories for native iOS, reference algorithm code, fixtures, and infrastructure.

#### Alternatives

| Option                                                         | Pros                                                          | Cons                                                        | Conclusion           |
| -------------------------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------------- | -------------------- |
| Immediate full repo move to `apps/web` and `apps/ios-native`   | Clean end state quickly                                       | High risk to current build, deploy, and docs                | Rejected for phase 1 |
| Separate web and iOS repositories now                          | Strong isolation                                              | Splits context during migration and duplicates product docs | Rejected             |
| Single repo with staged migration and target-state scaffolding | Low risk, keeps current product running, prepares native path | Transitional duplication for a period                       | Accepted             |

#### Consequences

- The repository will temporarily contain both the current root-based web app and the target-state directories.
- Documentation must clearly mark transitional vs target-state paths.
- Future phases can move code incrementally without forcing a big-bang migration.

### ADR-002

- Status: Accepted
- Context: The user wants the iOS product rebuilt natively, but the current algorithm is already working and must not drift during migration.
- Decision: Treat the current TypeScript algorithm as the reference implementation and require parity fixtures before changing algorithm behavior in Swift.

#### Alternatives

| Option                                                | Pros                                         | Cons                                  | Conclusion |
| ----------------------------------------------------- | -------------------------------------------- | ------------------------------------- | ---------- |
| Rewrite algorithm freely for Swift ergonomics         | Faster initial coding                        | High risk of silent behavior drift    | Rejected   |
| Port algorithm step-by-step against reference outputs | Preserves behavior and lowers migration risk | Requires fixtures and more discipline | Accepted   |

#### Consequences

- The reference algorithm must remain readable and stable enough to compare against.
- Sample videos and expected outputs become first-class repository assets.
- Future performance improvements must be clearly separated from baseline parity work.

## Target Repository Shape

```text
Picsew/
  apps/
    web/
    ios-native/
  reference/
    web-algorithm/
  fixtures/
    videos/
    expected/
  infra/
  docs/
    architecture/
    features/
```

## Phase Plan

### Phase 1: Structure and rules

- Keep the existing live web app in the repository root.
- Add target-state directories and ownership docs.
- Keep the current Capacitor `ios/` directory as a transitional shell and native-integration reference.
- Define algorithm parity rules and fixture expectations.

### Phase 2: Native iOS foundation

- Create the new native iOS app under `apps/ios-native/`.
- Establish app modules: `App`, `Features`, `Core`, `Resources`, `Support`.
- Introduce local Swift packages for `PicsewAlgorithm`, `PicsewMedia`, and `PicsewDesignSystem`.

### Phase 3: Algorithm migration

- Port the algorithm pipeline to Swift in staged steps:
  - metadata and video reading
  - low-resolution frame extraction
  - scrolling window detection
  - keyframe selection
  - offset calculation
  - stitching output
- Compare each stage against parity fixtures before moving on.

### Phase 4: Web relocation

- Move the current root-based web app into `apps/web/`.
- Update build, deploy, and test tooling to use the new path.
- Retire transitional root-level web paths only after deployment is proven stable.

## Planned Tests

- Phase 1 does not change runtime behavior, so validation focuses on repo integrity:
  - `npm run lint`
  - `npm run typecheck`
  - `npm run build`
- Future algorithm migration phases must add fixture-based tests for parity.

## Risks

- A premature directory move could break the current production deploy workflow.
- A native rewrite without a parity baseline could silently change stitching behavior.
- Mixed ownership between the root web app and the future `apps/ios-native` tree could create confusion unless docs stay explicit.

## Rollback

- This phase is additive. If needed, the new scaffolding directories and docs can be reverted without affecting the live web app.

## Implementation Checklist

### Phase 1

- [ ] Add a migration architecture document under `docs/architecture/`.
- [ ] Create `apps/web/` and document that the root web app remains the live implementation for now.
- [ ] Create `apps/ios-native/` and document the target native module layout.
- [ ] Create `reference/web-algorithm/` and document the current reference files.
- [ ] Create `fixtures/` and document parity-fixture intent.
- [ ] Create `infra/` and document future placement of Supabase-related assets.
- [ ] Update `AGENTS.md` with the new dual-platform structure and algorithm-parity rules.
