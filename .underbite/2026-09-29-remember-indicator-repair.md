# Remember indicator repair: violet pill, build 247

Date: 2026-09-29. Status: installed for human QA as build 247. No human
acceptance yet. Supersedes the build-246 Remember recording presentation,
which David rejected as oversized.

## Plain language summary

While a Remember observation is recording, the indicator is now the exact
same little pill as ordinary dictation — same size, shape, position, waveform
and microphone dot — with the orange accent changed to a soft violet. The
large control bar, "Remember" text label, book icon and extra stop button are
gone. Save and failure messages still appear in the ordinary outcome panel
afterwards. Everything else about build 246 (capture, storage, Observations
window, closeout) is unchanged.

## Change

- `SyllWaveformPill` (the actual ordinary component) gained an `accent`
  parameter defaulting to the ordinary orange; Remember passes
  `rememberViolet` (soft violet) and the accessible name
  "Recording observation". Dimensions, padding, shape, background, waveform
  geometry/animation, microphone treatment and shadows are shared code.
- `MiniRecorderView`: an observation recording now takes the identical view
  branch as ordinary dictation (the pill alone in the same window), so the
  containing panel, hit area and appearance/disappearance behaviour are the
  ordinary ones by construction. The Remember control-bar marker branch is
  removed. Observation save/failure outcomes keep their existing panel
  presentation.

## Verification

- Render-only evidence (actual product component, both accents, four meter
  levels, light and dark backgrounds; not live interaction QA):
  `build/observation-render/pill-ordinary-vs-remember-dark.png` and
  `-light.png`. The only visual difference is the accent colour; no clipping
  or panel enlargement — both pills render at the shared 54 × 17 pt.
- Containing-layout check is by construction: the observation recording path
  returns the same view branch as ordinary dictation, so no control-bar
  window, background, padding or hit area can remain around the pill.
- Overlay verification with updated markers; shortcut harness (double-tap
  latch, later-tap finish, fallback, single tap, hold unchanged); observation
  store, bridge, routing, cleaner and diagnostics suites all pass.
- Behaviour preserved: double-tap starts, later tap finishes, single Esc
  cancels Remember, ordinary hold-Fn and double-Esc unchanged, no
  paste/clipboard/history from observations, build-245 cleanup fixes intact.

## Installation receipt (build 247)

- Product source: `365dbce` on `candidate/remember-observations`.
- Established Apple Development route: build 247, `capital.underbite.syll`,
  Team `A635S52367`; executable SHA-256
  `d929b73855c8da6719b78c009d158430859b19478acd5127a9340ed514193273`.
- Runtime diff vs build 246: identical file list; only recompiled binaries,
  `Info.plist` (246 -> 247) and `CodeResources` differ.
- Rollback: `build/recovery-archives/Syll-build246-pre-247-working.zip`
  (SHA-256 `cff2f9bf1155b3e2a25247ee1fee0297a2f9b338e385dacccc8a3e691b5bdc9c`;
  archived executable verified to hash `0e35eeb9...` before cutover) plus
  exported preferences
  `capital.underbite.syll-build246-pre-247.preferences.plist`; prior bundle
  retained temporarily at `/Applications/.Syll-build246-pre247.app`
  (do not launch). Cutover script: `build/remember-247-final/cutover-247.sh`.
- Cutover: no recording in flight; build 246 (PID 48703) terminated normally;
  build 247 launched as PID 55571. Post-install identity, signature, hash,
  single process, model cache and evidence stores verified. No permission
  resets, no data migration, no diagnostics cleared.

## Human visual check

Ordinary dictation still looks the same; Remember is the same little pill in
violet. That check is David's; renders are not live QA.
