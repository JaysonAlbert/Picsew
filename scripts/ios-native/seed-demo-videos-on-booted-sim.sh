#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE_ID="top.ibotcloud.picsew.native"
SIMULATOR_ID="${PICSEW_SIMULATOR_ID:-$(xcrun simctl list devices booted | rg -o '[A-F0-9-]{36}' -m1 || true)}"
VIDEO_PATH="${1:-$ROOT_DIR/fixtures/floating-overlay/glass.mp4}"
if [[ -z "$SIMULATOR_ID" || ! -f "$VIDEO_PATH" ]]; then
  echo "A booted simulator and an existing video fixture are required." >&2
  exit 1
fi
APP_CONTAINER="$(xcrun simctl get_app_container "$SIMULATOR_ID" "$BUNDLE_ID" data)"
DEST_DIR="$APP_CONTAINER/Library/Caches/ImportedVideos"
mkdir -p "$DEST_DIR"
cp "$VIDEO_PATH" "$DEST_DIR/test-video.mp4"
echo "Seeded the recording into the simulator cache."
