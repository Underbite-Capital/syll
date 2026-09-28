#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
source_file="$root/app/VoiceInk/Shortcuts/RecordingShortcutManager.swift"
output="$root/build/shortcut-tests"
mkdir -p "$output"
python3 - "$source_file" "$output/EffectiveShortcutHandler.swift" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text()
marker = '@MainActor\nfinal class RecordingShortcutModeHandler {'
assert source.count(marker) == 1, 'effective shortcut handler was not found exactly once'
Path(sys.argv[2]).write_text('import Foundation\n' + source[source.index(marker):])
PY
swiftc -module-cache-path /tmp/syll-shortcut-test-module-cache \
  "$output/EffectiveShortcutHandler.swift" \
  "$root/tools/shortcut-tests/ShortcutTests.swift" \
  -o "$output/shortcut-tests"
"$output/shortcut-tests"
