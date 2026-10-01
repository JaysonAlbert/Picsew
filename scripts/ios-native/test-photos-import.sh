#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

"$ROOT_DIR/scripts/ios-native/install-host-app-on-booted-sim.sh"
SIMULATOR_ID="$(xcrun simctl list devices booted | rg -o '[A-F0-9-]{36}' -m1)"
xcrun simctl addmedia "$SIMULATOR_ID" "$ROOT_DIR/fixtures/floating-overlay/white.mp4"

cd "$ROOT_DIR/apps/ios-native/maestro"
maestro test integration/photos-import-interaction.yaml
