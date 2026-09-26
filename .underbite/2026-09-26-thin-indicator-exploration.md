# Thin recording indicator exploration

Status: visual evidence for human review. No product acceptance, build-243 package, push, or installation is implied. `origin/main@008f23a5b8033ba3b47f3dfc321b5de7d0d67ea2` remains the reviewed build-241 source; installed build 241 remains untouched.

David rejected `2977da034a1f1f5c5c71693ab992ca68257c6664`: the 56 × 19 pt capsule still looked chunky, and the unfilled bars needed to be a very light blue. The earlier 64 × 22 pt build-242 treatment at `daa3c48e56c6fbdb50a9887a7e10375d362b1706` was also rejected.

## Visual-only implementation

The new ordinary recording pill is 48 × 15 pt with a fully rounded, lighter translucent dark-material capsule. The orange status dot is 4.1 pt with a 1 pt, low-opacity glow. Eight rounded bars are 1.25 pt wide with 1.1 pt gaps and capacity heights of 3.2–10.5 pt in a smooth wave. The persistent capacity layer is icy blue (`red 0.79, green 0.93, blue 1.0`, 82% opacity). The existing recorder average/peak meter blend controls centre-out orange fill height and opacity continuously. Orange fill is capped at 86% of capacity so pale-blue tips remain visible at strong levels. The capsule dark overlay is 52% opacity, with no border and an 8%-black, 2 pt shadow. The existing 50 ms meter poll and 120 ms visual interpolation remain.

No source for meter acquisition, recording state, placement, transcription, diagnostics, clipboard, dictionary, menus, icons, recognition or Command Mode is changed.

## Reproducible visual evidence

`bash tools/indicator-render/run.sh build/indicator-thin-exploration` compiles the actual current SwiftUI view. For the true-size comparison only, it also compiles exact prior view source from `daa3c48` and `2977da0` after renaming the Swift type. It renders all three at their own point dimensions with the same ordinary-speech meter value; there is no approximate redraw. The tool renders the current view at four representative synthetic meter levels over light and dark content, with separate true-size and 3.5× detail sheets, plus one busy-background frame. Its output stays local under ignored `build/indicator-thin-exploration/`.

These stills prove the source's static visual mapping, not live animation quality or David's visual acceptance. Stop for human review before another QA build.
