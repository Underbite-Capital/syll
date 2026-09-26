#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
output="$(mktemp -d)"
trap 'rm -rf "$output"' EXIT
swiftc -parse-as-library -module-cache-path "$output/module-cache" \
  "$root/overlays/core/VoiceInk/Services/SyllFailureEvidenceStore.swift" \
  "$root/overlays/core/VoiceInk/Services/SyllOperationalLog.swift" \
  "$root/overlays/core/VoiceInk/Paste/SyllClipboardResetPolicy.swift" \
  "$root/tools/diagnostics-tests/DiagnosticsTests.swift" \
  -o "$output/diagnostics-tests"
"$output/diagnostics-tests"
