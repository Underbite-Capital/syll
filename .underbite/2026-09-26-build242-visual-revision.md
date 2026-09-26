# Recording indicator visual revision after rejected build 242

Status: local, unaccepted visual exploration for Supervisor and David review. Do not publish to `origin/main`, package another QA build, or install it on the strength of these renders. The reviewed build-241 source remains `origin/main@008f23a5b8033ba3b47f3dfc321b5de7d0d67ea2`; build 241 remains installed.

## Human authority

David rejected the actual build-242 render from `daa3c48e56c6fbdb50a9887a7e10375d362b1706`. At 64 × 22 pt it remained too large and visually heavy. Its predominantly orange waveform lost the pale inactive bars that mattered in the approved reference. This is a visual verdict, not a finding about microphone or transcription behavior.

## Revision

The ordinary recording view is 56 × 19 pt. It has a 5.5 pt orange dot with restrained 2 pt glow, eight 1.6 pt rounded bars separated by 1.4 pt, 11 pt side padding, a lighter dark-material fill, no outline, and a 3 pt soft shadow. The visible neutral bar heights form a quiet waveform. The existing average/peak meter blend continuously controls the orange overlay's height and opacity across successive bars. Near silence leaves all bars pale; stronger input fills progressively more of their height in orange. The view still polls `Recorder.audioMeterSnapshot()` at the existing 50 ms interval, appears only under the existing `.recording` gate, and stays in the same low-centred panel. No recording, delivery, recognition, diagnostic, menu, icon, or Command Mode source is changed.

## Actual-view render evidence

`tools/indicator-render/run.sh` compiles the maintained `SyllWaveformPill.swift` with only the microphone meter values substituted. It renders four representative levels (near-silent, quiet, ordinary, louder) over light and dark content at @2x. Each `states-*.png` sheet presents the pill at its intended 56 × 19 pt size and a labelled 3× detail view of the same implementation. Individual true-size renders and an ordinary-speech busy-background render are also emitted. Output is local under ignored `build/indicator-visual-revision/`; these static frames do not prove the on-device feel of live animation or constitute human acceptance.

This exploration stops at actual-view renders. There is no build-243 package or installation.
