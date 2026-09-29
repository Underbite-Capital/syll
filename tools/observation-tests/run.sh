#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
output="$(mktemp -d)"
trap 'rm -rf "$output"' EXIT
swiftc -parse-as-library -module-cache-path "$output/module-cache" \
  "$root/overlays/core/VoiceInk/Services/SyllObservationStore.swift" \
  "$root/overlays/core/VoiceInk/Services/SyllFailureEvidenceStore.swift" \
  "$root/tools/observation-tests/ObservationStoreTests.swift" \
  -o "$output/observation-tests"
"$output/observation-tests"
