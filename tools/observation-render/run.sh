#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${1:-$ROOT/build/observation-render}"
swiftc -module-cache-path /tmp/syll-observation-render-cache -o /tmp/syll-observation-render \
  "$ROOT/overlays/core/VoiceInk/Views/Recorder/SyllWaveformPill.swift" \
  "$ROOT/overlays/core/VoiceInk/Views/Recorder/SyllObservationOutcomeView.swift" \
  "$ROOT/tools/observation-render/RenderObservation.swift"
/tmp/syll-observation-render "$OUT"
swiftc -parse-as-library -module-cache-path /tmp/syll-observation-render-cache -o /tmp/syll-observation-view-render \
  "$ROOT/overlays/core/VoiceInk/Services/SyllObservationStore.swift" \
  "$ROOT/overlays/core/VoiceInk/Views/SyllObservationsView.swift" \
  "$ROOT/tools/observation-render/RenderObservationsView.swift"
/tmp/syll-observation-view-render "$OUT"

