#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$ROOT_DIR"

echo "Picsew native iOS agent init"
echo
git status --short --branch
echo
node scripts/agent/check-ios-ledger.mjs
echo

for tool in node swift xcodebuild xcrun; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "tool:$tool available"
  else
    echo "tool:$tool missing"
  fi
done

if command -v maestro >/dev/null 2>&1; then
  echo "tool:maestro available"
else
  echo "tool:maestro missing"
fi

SIMULATOR_ID="$(xcrun simctl list devices booted 2>/dev/null | rg -o '[A-F0-9-]{36}' -m1 || true)"
if [[ -n "$SIMULATOR_ID" ]]; then
  echo "booted-simulator:$SIMULATOR_ID"
else
  echo "booted-simulator:none"
fi

echo
echo "recommended-next-commands:"
echo "  npm run ios:harness:smoke"
echo "  npm run ios:test:maestro:preview"
