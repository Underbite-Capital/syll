#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${1:-$ROOT/build/indicator-render}"
HISTORICAL_VIEWS="$(mktemp -d /tmp/syll-indicator-history.XXXXXX)"
trap 'rm -rf "$HISTORICAL_VIEWS"' EXIT

git -C "$ROOT" show daa3c48e56c6fbdb50a9887a7e10375d362b1706:overlays/core/VoiceInk/Views/Recorder/SyllWaveformPill.swift \
  | sed 's/SyllWaveformPill/SyllWaveformPill242/g' > "$HISTORICAL_VIEWS/SyllWaveformPill242.swift"
git -C "$ROOT" show 2977da034a1f1f5c5c71693ab992ca68257c6664:overlays/core/VoiceInk/Views/Recorder/SyllWaveformPill.swift \
  | sed 's/SyllWaveformPill/SyllWaveformPill2977/g' > "$HISTORICAL_VIEWS/SyllWaveformPill2977.swift"

swiftc -module-cache-path /tmp/syll-indicator-module-cache -o /tmp/syll-indicator-render \
  "$ROOT/overlays/core/VoiceInk/Views/Recorder/SyllWaveformPill.swift" \
  "$HISTORICAL_VIEWS/SyllWaveformPill242.swift" \
  "$HISTORICAL_VIEWS/SyllWaveformPill2977.swift" \
  "$ROOT/tools/indicator-render/RenderIndicator.swift"
/tmp/syll-indicator-render "$OUT"
