# Syll wind-down decision and release scope

Status: authorized final local release candidate; installation and normal-use
evidence must be recorded separately.

## Human product authority

- David provisionally accepted the build-243 thin recording indicator for
  continued use and requested a modest increase from 48 × 15 to 54 × 17 pt.
  Its icy-blue capacity waveform, orange microphone fill, thin geometry,
  recording gate, and low-centred placement remain the same.
- David now prefers the existing build-243 monochrome menu-bar mark. Keep it.
  The local orange status-item exploration at `cf3b3f3` was unaccepted and was
  removed from the successor's product source. The preserved build-221
  application artwork remains historical identity evidence, not current
  status-item implementation authority.
- Hold Fn remains ordinary dictation. Rapid double-tap has no special action.
  Command Mode code/history remains dormant and unaccepted; no replacement
  action is assigned.

## Learning state and boundaries

The existing local operational evidence path remains active: bounded ordinary
WAV retention, raw recognizer and final text, model/path and timing data,
recording-start and first-buffer observations, marked failures, and explicit
deletion. This release does not clear user evidence or alter retention policy.

The reported first-word loss in short recordings is an observed historical
issue under measurement, not a claimed fixed bug. Parakeet V3 recognition is
unchanged; no CTC path is added. The next product review should begin with
accumulated real-use evidence rather than a speculative recognition change.

## Mechanical scope

- `SyllWaveformPill`: proportional 54 × 17 pt geometry only.
- Effective hybrid shortcut: a second quick press cancels the pending tap
  timer and continues through ordinary shortcut handling. It no longer calls
  `latchCommandMode` or sets hands-free recording as a double-tap action.
- Dictation-shortcut explanatory copy no longer promises a double-tap action.
- A dictionary integration-test fixture now uses two valid, non-conflicting
  aliases; no dictionary product logic changed.
- No intentional changes to capture, ASR, dictionary, clipboard, menu
  structure, diagnostics, application icon, or menu-bar identity.

Build, signing, installation, and normal-use observations are separate from
this source decision.
