#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT_PATH="$ROOT_DIR/apps/ios-native/HostApp/PicsewNativeApp.xcodeproj"
SCHEME="PicsewNativeApp"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/.derived-data/picsew-maestro}"
BUNDLE_ID="top.ibotcloud.picsew.native"

SIMULATOR_ID="$(xcrun simctl list devices booted | rg -o '[A-F0-9-]{36}' -m1 || true)"

if [[ -z "$SIMULATOR_ID" ]]; then
  echo "No booted iOS simulator found. Boot a simulator first, then rerun this script." >&2
  exit 1
fi

echo "Building $SCHEME for simulator $SIMULATOR_ID"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -destination "id=$SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build

APP_PATH="$(find "$DERIVED_DATA_PATH/Build/Products" -path "*-iphonesimulator/$SCHEME.app" -print -quit)"

if [[ -z "$APP_PATH" ]]; then
  echo "Unable to locate the built app under $DERIVED_DATA_PATH" >&2
  exit 1
fi

echo "Installing $APP_PATH"
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"

echo "Installed $BUNDLE_ID on simulator $SIMULATOR_ID"
