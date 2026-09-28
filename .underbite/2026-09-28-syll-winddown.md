# Syll wind-down decision and release scope

Status: build 244 installed and machine verified. Normal-use evidence remains
pending; no further scripted human QA is requested.

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

## Exact release receipt

- Product source: `b602c7439b1d8c8804a2b2337d9e264592cddae4`.
- Final signed app: build 244, `capital.underbite.syll`, Apple Development
  Team `A635S52367`; executable SHA-256
  `37defb6f8987c88a8a855febd31ea855f1dec0bbea4f56725c86d7086582c4fc`.
- Candidate archive SHA-256:
  `bfa92ddf76d1f9a983b6111420fa3fd855bccf1e789c24ecd0ea67c111cc9f46`.
- Build 243 rollback archive:
  `build/recovery-archives/Syll-build243-pre-244-working.zip`, SHA-256
  `514b0cfdb5dd1828c9032f15148b2c70b151e3e19a79cbec50315b8bfc80acef`.
  Its executable SHA-256 is
  `36e7e69d9422fb74ceddc696e7f3afbcc89b61b16718f37a5b624015269c8008`.
- Clean core composition, overlay verification, focused shortcut and diagnostic
  tests, focused Xcode recovery/dictionary/cleanup tests, signed build, and
  deep/strict signature verification passed. One pre-existing dictionary test
  fixture initially failed because it used a forbidden duplicate alias; the
  fixture was corrected without product logic changes and the rerun passed.
- Post-install: exactly one intended Syll process from `/Applications/Syll.app`;
  Parakeet V3 prewarm completed in 0.21 seconds. App support evidence file
  count was 56 before and after cutover. No data or permission reset occurred.

Installation and machine checks do not constitute new human acceptance. The
next product review starts from ordinary-use evidence accumulated this week.
