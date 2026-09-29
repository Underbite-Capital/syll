# Remember capture-to-response loop: completion receipt and QA install

Date: 2026-09-29. Status: installed for human QA as build 246. No human
acceptance yet. Builds on the build-245 cleanup repair.

## Plain language summary

Double-tap Fn, speak naturally (no prefix), tap Fn once to finish: the
observation is saved locally and never pasted. Esc once cancels a Remember
recording; ordinary dictation keeps its existing double-Esc. The menu-bar
Observations menu now opens a real window: every observation with its full
text, the reviewer's response, whether a decision is still outstanding,
correction that keeps the original wording, and explicit Mark Addressed and
Delete controls. At closeout, the existing generator collects outstanding
observations into the closeout document, the reviewing agent answers them,
and a validated import attaches each response to its original observation.
Proposals stay outstanding until David decides; only David can mark something
addressed. Nightly scheduling remains inactive.

## Exact revisions

- Syll product source: `bab5965` on branch `candidate/remember-observations`
  (product changes `ff8301e`, `90885e2`, `492d794`, `bab5965` on top of the
  build-245 cleanup repair `9bfa8d7`).
- Closeout integration: lighthouse-mac branch `closeout/remember-observations`
  at `5109c59` (off `closeout/daily-2026-09-18` `856fd16`), local only, in
  worktree `/tmp/lighthouse-closeout-remember`. The repo's `main` checkout
  with its unrelated uncommitted work was not touched.
- day-closeout skill: `~/.codex/skills/day-closeout/SKILL.md` gained a
  Remember observations section (collect via the generated closeout or
  `observations.py list`; respond via validated `import-responses`; an agent
  response never marks addressed).

## Installation receipt (build 246)

- Build/sign: established `scripts/build-apple-development-pilot.sh` route;
  build 246, `capital.underbite.syll`, Apple Development Team `A635S52367`;
  executable SHA-256
  `0e35eeb98b895435f9d963cd11bf56eff7d614723927ddf5fd3f320f5c5ffd42`.
- Runtime diff vs build 245: identical bundle file list; only recompiled
  Mach-O binaries, `Info.plist` (245 -> 246), and `CodeResources` differ.
- Rollback: `build/recovery-archives/Syll-build245-pre-246-working.zip`
  (SHA-256 `736c5b1b82e8ccd76857a2439d6ef4098e09ea620735e1b6c7c480ec41a4f601`;
  archived executable verified to hash `da48548a...` before cutover) plus
  exported preferences
  `build/recovery-archives/capital.underbite.syll-build245-pre-246.preferences.plist`.
  Prior bundle retained temporarily at `/Applications/.Syll-build245-pre246.app`
  (do not launch; single-copy rule). Cutover script:
  `build/remember-246-final/cutover-246.sh`.
- Cutover: no recording in flight (last session file stable, process idle);
  build 245 (PID 97139) terminated normally; build 246 launched as PID 48703.
- Post-install: bundle id, team, build number, executable hash verified;
  deep/strict signature passed; exactly one Syll process; Parakeet V3 model
  cache untouched; evidence stores intact (496 timing / 493 ordinary entries;
  retention unchanged). No permission resets, no data migration, no
  diagnostics cleared.

## What changed since the first Remember candidate

- Status model: `new` / `reviewed` / `awaitingDecision` / `unresolved` /
  `addressed`. Outstanding work for closeout = new + awaitingDecision +
  unresolved. A proposal response sets `awaitingDecision`, not `reviewed`;
  only David's explicit Mark Addressed resolves. Reviews record `basisText`
  (the wording reviewed); a later correction keeps the response visibly
  attached to the old wording.
- Closeout bridge: `observations.py` gained validated `import-responses`
  (unknown IDs, bad dispositions and empty responses rejected per entry;
  rejected items stay outstanding and retryable).
- The actual closeout entry point (lighthouse-mac `generate.py`) collects
  outstanding observations via a new read-only adapter and renders a
  Remember observations section with the reviewer instructions.
- Single Esc cancels an active Remember capture (including startup) and keeps
  nothing — no observation, no history record, no retained audio. Ordinary
  dictation's double-Esc is unchanged.
- The Observations menu opens a native window instead of a preview line.
- Failed captures keep audio bounded to the newest 20 under
  `Observations/Failed/`, visible in the window and explicitly deletable.
- Session routing is a single tested function (`SyllSessionRouting`): an
  observation session cannot reach ordinary delivery; cancellation always
  wins.

## Evidence

Mechanical: overlay verification; official composition; shortcut harness
(single tap, double-tap latch, fallback, hold unchanged); observation store
tests (save/move/perms, outstanding contract, proposal survival across
rereads, correction-after-review basis, explicit addressed, delete, bounded
failures, diagnostics separation, restart durability); bridge regression
tests (proposal survives 3 reruns, repeated import idempotent, malformed
entries rejected and retryable, correction staleness); routing boundary
tests; cleaner and diagnostics suites unchanged and passing; concurrency
check (15 captures during 5 repeated review imports: 33/33 records and WAVs
intact, 3 reviews persisted, no overwrites).

Real invoked loop (synthetic data, actual entry point): 3 synthetic
observations written through the real Swift store -> actual
`generate.py --syll-observations ...` collected all 3 into the closeout
document -> the reviewing agent (this Cursor runtime) wrote considered
responses -> validated import persisted all 3 against the original IDs ->
generator rerun showed the proposal and unresolved concern still outstanding
with prior-response context, answered item gone. Earlier manual
`respond`/`correct` calls are labelled storage-interface evidence only.

Render-only evidence (not live interaction QA):
`build/observation-render/` contains the actual `SyllObservationsView` with
synthetic data (all states: new, proposal outstanding, corrected-after-review
with stale-response notice, addressed, failed capture) and the actual
outcome views and Remember recording marker.

## Remaining uncertainty

- The double-tap gesture feel, the marker, and the window have not been used
  by David; renders are not live QA.
- Observation transcription inherits the open capture/short-utterance
  problems; nothing here claims those are fixed.
- The closeout integration ran against synthetic observations through the
  real generator; it has not yet run against David's real store in a real
  evening closeout.
- Nightly scheduling remains inactive by decision; the ordinary loop is the
  manually invoked closeout.

## Human QA journey

1. Double-tap Fn and say one natural operational observation, no prefix;
   tap Fn once to finish. Expect the "Remember" marker while recording, then
   "Saved to observations" with the text; nothing pasted, clipboard intact.
2. Open menu bar -> Observations -> Open Observations…: the observation is
   there with full text.
3. Run the closeout route (day-closeout / generator) and read the response
   attached to the observation; a proposal stays outstanding until you mark
   it addressed.
4. Double-tap Fn, speak, single Esc: nothing saved. One ordinary hold-Fn
   dictation works as before.
