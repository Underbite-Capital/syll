#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${1:-$ROOT/build/indicator-render}"
swiftc -module-cache-path /tmp/syll-indicator-module-cache -o /tmp/syll-indicator-render \
  "$ROOT/overlays/core/VoiceInk/Views/Recorder/SyllWaveformPill.swift" \
  "$ROOT/tools/indicator-render/RenderIndicator.swift"
/tmp/syll-indicator-render "$OUT"
