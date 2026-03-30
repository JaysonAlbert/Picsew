#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT_PATH="$ROOT_DIR/apps/ios-native/HostApp/PicsewNativeApp.xcodeproj"
SCHEME="PicsewNativeApp"
REQUIRE_MAESTRO="${PICSEW_IOS_SMOKE_REQUIRE_MAESTRO:-0}"

run_step() {
  echo
  echo "==> $*"
  "$@"
}

cd "$ROOT_DIR"

run_step node scripts/agent/check-ios-ledger.mjs
run_step node --test scripts/agent/check-ios-ledger.test.mjs
run_step swift test --package-path apps/ios-native/PicsewApp
run_step xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO \
  build

SIMULATOR_ID=""
if command -v xcrun >/dev/null 2>&1; then
  SIMULATOR_ID="$(xcrun simctl list devices booted 2>/dev/null | rg -o '[A-F0-9-]{36}' -m1 || true)"
fi

if command -v maestro >/dev/null 2>&1 && [[ -n "$SIMULATOR_ID" ]]; then
  run_step npm run ios:test:maestro:preview
elif [[ "$REQUIRE_MAESTRO" == "1" ]]; then
  echo "Maestro smoke was required but Maestro or a booted simulator was unavailable." >&2
  exit 1
else
  echo
  echo "==> Skipping Maestro smoke: missing Maestro CLI or booted simulator"
fi
