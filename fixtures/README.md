# Parity Fixtures

This directory is reserved for migration fixtures that prove the native iOS algorithm matches the current web reference behavior.

## Layout

- `videos/`: source sample videos
- `expected/`: expected metadata, windows, keyframes, offsets, and output summaries

## Phase 1 note

The repository still keeps several sample videos at the root for current web testing. Future migration work should gradually consolidate shared algorithm fixtures here.

## Current Web regression inputs

- `floating-overlay/`: committed synthetic video/document fixtures with automatic
  pixel-level assertions for stationary controls and genuine document arrows.
- `recordings/`: local original recordings supplied for real-clip investigations,
  including the [2026-10-01 repeated-arrow recording](recordings/README.md).
  See each sample's publication status and known limitations before using it.
