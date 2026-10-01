#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <simulator-id> <output-directory> [route ...]" >&2
  exit 64
fi

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SIMULATOR_ID="$1"
OUTPUT_DIR="$2"
shift 2
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
cd "$ROOT_DIR/apps/ios-native/maestro"

if [[ $# -eq 0 ]]; then
  set -- upload upload-empty upload-error processing preview preview-details preview-empty onboarding feedback
fi

for route in "$@"; do
  case "$route" in
    upload-empty) flow="upload-selection-interaction" ;;
    upload|upload-error|processing|preview|preview-details|preview-empty|onboarding|feedback)
      flow="capture-$route" ;;
    *) echo "Unknown screenshot route: $route" >&2; exit 64 ;;
  esac

  # Finish the flow before capturing again: subsequent taps or launches can race
  # the in-flow capture and leave a modal transition in the evaluator artifact.
  maestro --device "$SIMULATOR_ID" test "flows/$flow.yaml"
  xcrun simctl io "$SIMULATOR_ID" screenshot "$OUTPUT_DIR/$route.png"
done
