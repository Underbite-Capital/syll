#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${1:-$ROOT/build/observation-render}"
swiftc -module-cache-path /tmp/syll-observation-render-cache -o /tmp/syll-observation-render \
  "$ROOT/overlays/core/VoiceInk/Views/Recorder/SyllObservationOutcomeView.swift" \
  "$ROOT/tools/observation-render/RenderObservation.swift"
/tmp/syll-observation-render "$OUT"
