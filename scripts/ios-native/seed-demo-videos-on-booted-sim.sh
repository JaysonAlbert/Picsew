#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE_ID="top.ibotcloud.picsew.native"
SIMULATOR_ID="$(xcrun simctl list devices booted | rg -o '[A-F0-9-]{36}' -m1 || true)"

if [[ -z "$SIMULATOR_ID" ]]; then
  echo "No booted iOS simulator found. Boot a simulator first, then rerun this script." >&2
  exit 1
fi

APP_CONTAINER="$(xcrun simctl get_app_container "$SIMULATOR_ID" "$BUNDLE_ID" data 2>/dev/null || true)"

if [[ -z "$APP_CONTAINER" ]]; then
  echo "Unable to find the app container for $BUNDLE_ID on simulator $SIMULATOR_ID." >&2
  echo "Install the host app first with ./scripts/ios-native/install-host-app-on-booted-sim.sh." >&2
  exit 1
fi

DEST_DIR="$APP_CONTAINER/Library/Caches/ImportedVideos"
mkdir -p "$DEST_DIR"

shopt -s nullglob
DEMO_FILES=("$ROOT_DIR"/demo*.mp4 "$ROOT_DIR"/test-video.mp4)

if [[ "${#DEMO_FILES[@]}" -eq 0 ]]; then
  echo "No repository demo videos were found to seed into the simulator." >&2
  exit 1
fi

echo "Seeding demo videos into $DEST_DIR"

for demo_file in "${DEMO_FILES[@]}"; do
  target_file="$DEST_DIR/$(basename "$demo_file")"
  cp "$demo_file" "$target_file"
  echo "Seeded $(basename "$demo_file")"
done
