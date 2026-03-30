---
title: Native iOS Agent Harness Foundation
issue: native-ios-agent-harness-foundation
author: Codex
date: 2026-03-30
updated: 2026-03-30
version: 0.1.0
reviewers: [Jayson Albert]
tags: [ios, automation, agent, harness]
source_code:
  - agent/ios-feature-ledger.json
  - scripts/agent/ios-ledger-lib.mjs
  - scripts/agent/check-ios-ledger.mjs
  - scripts/agent/init-ios.sh
  - scripts/agent/smoke-ios.sh
status: approved
---

# Native iOS Agent Harness Foundation

## Summary

- **Problem**: Picsew has native iOS automation building blocks, but no single agent-facing harness contract that defines what matters, how to initialize work, and how to validate a baseline repeatedly.
- **Goal**: Add an iOS-only harness foundation that gives agents and developers one machine-readable feature ledger and one repeatable command path for initialization and smoke validation.
- **Scope**:
  - add a machine-readable native iOS feature ledger
  - add a validation script for ledger structure and linked docs
  - add reusable iOS init and smoke scripts for agent sessions
  - ignore local derived data and Maestro artifacts that would otherwise pollute the working tree

## Design Choice

### ADR-001: Start with a single-surface iOS harness instead of a cross-surface harness

**Status**: Accepted

**Decision**:

- Limit the initial harness scope to `apps/ios-native/`.
- Treat the ledger as the authoritative iOS work index for agent sessions.
- Keep one init command and one smoke command as the default entry points.

**Why**:

- The web surface is closed for new feature investment.
- The native app already has deterministic launch scenarios and Maestro flows, so it is the best current surface for a long-running agent workflow.
- A small harness is easier to trust and maintain than a broad but noisy system.

### ADR-002: Use JSON for the feature ledger and small shell scripts for entry points

**Status**: Accepted

**Decision**:

- Store the ledger in `agent/ios-feature-ledger.json`.
- Validate it with a repository-owned Node script.
- Use shell wrappers for init and smoke flows so humans and agents run the same commands.

**Alternatives**

| Option                             | Pros                                         | Cons                                                         | Conclusion |
| ---------------------------------- | -------------------------------------------- | ------------------------------------------------------------ | ---------- |
| Markdown checklist only            | Easy to read                                 | Weak machine readability and hard to summarize automatically | Rejected   |
| Full database-backed harness state | Highly structured                            | Too heavy for the current repo stage                         | Rejected   |
| JSON ledger plus simple scripts    | Easy to diff, validate, and call from agents | Requires a small validation utility                          | Accepted   |

## Acceptance Criteria

- [ ] AC-01: [P0] The repository contains a machine-readable native iOS feature ledger that can be validated locally.
  - **Given**: the repository root on a developer or agent machine
  - **When**: `npm run ios:harness:check` is executed
  - **Then**: the ledger validates required fields, linked docs resolve, and a concise summary is printed
- [ ] AC-02: [P0] Native iOS work can be initialized through one repeatable init command.
  - **Given**: a new agent or developer session
  - **When**: `npm run ios:harness:init` is executed
  - **Then**: the command shows branch state, tool availability, simulator status, and ledger summary without requiring custom thread context
- [ ] AC-03: [P0] Native iOS baseline validation is exposed through one smoke command.
  - **Given**: the required local Apple toolchain is available
  - **When**: `npm run ios:harness:smoke` is executed
  - **Then**: the command validates the ledger, runs harness tests, runs Swift package tests, and runs a host app simulator build check
- [ ] AC-04: [P1] Machine-local build output and automation artifacts used by the harness stay out of version control.

## Planned Tests

- `npm run ios:harness:check`
- `npm run ios:harness:test`
- `swift test --package-path apps/ios-native/PicsewApp`
- `xcodebuild -project apps/ios-native/HostApp/PicsewNativeApp.xcodeproj -scheme PicsewNativeApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- optional local smoke when tooling is available:
  - `npm run ios:test:maestro:preview`

## Risks

- The ledger can go stale if feature status is not updated alongside product work.
- A shell-based harness is intentionally simple, so future multi-run history may still need a richer progress artifact.
- Maestro remains optional in the smoke script because it depends on a booted simulator and local CLI availability.

## Rollback

This change is additive. Rollback means removing the ledger, the validation scripts, and the harness npm commands while leaving product automation and app code intact.

## Implementation Checklist

> Phase 1: iOS harness contract

- [ ] Add `docs/features/native-ios-agent-harness-foundation.md`
- [ ] Add `agent/ios-feature-ledger.json`
- [ ] Add `scripts/agent/ios-ledger-lib.mjs`
- [ ] Add `scripts/agent/check-ios-ledger.mjs`

> Phase 2: entry points

- [ ] Add `scripts/agent/init-ios.sh`
- [ ] Add `scripts/agent/smoke-ios.sh`
- [ ] Add npm scripts for init, check, test, and smoke

> Phase 3: validation and cleanup

- [ ] Add harness validation tests under `scripts/agent/`
- [ ] Ignore local `.derived-data/` and Maestro artifact output
