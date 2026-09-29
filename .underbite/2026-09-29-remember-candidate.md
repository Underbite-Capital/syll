# Remember observation capture: implementation candidate

Date: 2026-09-29. Status: implementation candidate, built and uninstalled;
no human acceptance. Builds on the build-245 cleanup repair (branch
`candidate/remember-observations`, off `candidate/cleanup-first-word-repair`).
Installed build 245 is unchanged by this candidate.

## Plain language summary

Double-tap Fn now means "Remember this": David speaks an observation, taps Fn
again to finish, and the words are saved to a durable local observations
folder instead of being pasted anywhere. While an observation is recording,
the pill is replaced by a panel marked "Remember" with a book icon, and after
saving it briefly shows "Saved to observations" with the text — or a visible
failure that keeps the audio. The menu bar gains an Observations section with
a count awaiting review, a manual copy, and a folder reveal. At closeout, an
agent reads new/unresolved observations from the store and records a response
against each one; nothing becomes a task or a process change by itself.

## Interaction (from composed source)

- Hold Fn: ordinary dictation, unchanged (single-tap and hold regression
  tests re-pinned and passing).
- Double-tap Fn (second press within 0.5 s): latches observation capture onto
  the recording the first tap started; the session continues hands-free.
  If no eligible ordinary session is in flight, the double tap falls back to
  previous ordinary handling.
- Later tap: finishes the observation. Double-Esc (the existing cancel
  gesture): cancels; nothing is saved or pasted.
- While recording: the bare pill is replaced by the control bar carrying a
  book icon + "Remember" label — a shape/text distinction, not colour-only.
- On finish: the same local Parakeet V3 path transcribes; the observation is
  persisted; the panel shows "Saved to observations" + text (3 s) or, on
  failure, "Not saved" + reason (7 s) with audio kept in
  `Observations/Failed/`.
- Never pastes, never touches the clipboard, never executes a command, never
  enters ordinary transcription history; Copy Last and dictionary behavior
  are untouched. `verify_overlay.py` asserts the patch contains no paste or
  clipboard path.

## Durable store and closeout contract

Store: `~/Library/Application Support/Syll/Observations/<id>.json` +
`<id>.wav` (owner-only permissions). No automatic expiry; diagnostic deletion
(`SyllFailureEvidenceStore`/`SyllOperationalLog`) operates on different roots
and cannot remove observations (covered by a store test).

Record: `schemaVersion`, `id`, `createdAt`, `originalText` (recognized text,
immutable), `text` (cleanup + dictionary form), optional `correctedText` /
`correctedAt` (additive correction), `audioFile`, `audioDurationSeconds`,
`model`, `status` (`new` / `reviewed` / `unresolved`), optional `review`
(`respondedAt`, `responder`, `response`, `disposition` =
`answered` / `proposal` / `unresolved`).

Closeout bridge: `tools/observation-closeout/observations.py`
- `list` — new and unresolved observations, oldest first (the retrieval
  contract: no manual copying).
- `respond --id ... --response ... --disposition ...` — records the review
  against the original observation; `answered`/`proposal` mark it reviewed,
  `unresolved` keeps it in the queue.
- `correct --id ... --text ...` — additive correction; original preserved.

## Review-integration proof (synthetic observations)

Three synthetic observations were written through the real
`SyllObservationStore` into a sandbox root (`/tmp/syll-obs-proof/store`,
not the live store). The bridge listed all 3 as awaiting review; recorded
`answered`, `proposal`, and `unresolved` responses; applied one correction;
and re-listed exactly the 1 unresolved observation. Verified record contents:
`originalText` intact, review linked by id, status transitions correct.

## Existing closeout route and the reviewable proposal

The existing local closeout route is the day-closeout skill plus the
lighthouse-mac closeout generator (branch `closeout/daily-2026-09-18`), whose
`scripts/closeout/syll.py` adapter already loads Syll session metadata via a
read-only allow-listed query (`--syll-store` seam). The credible integration
is a sibling observations adapter in that generator plus a closeout step that
runs `observations.py list` and records responses with `respond`.

Per the delivery loop, this is a proposal, not an applied change:
1. lighthouse-mac closeout branch: add an observations adapter reading
   `~/Library/Application Support/Syll/Observations/` (schemaVersion 1),
   listing new/unresolved observations into the closeout document.
2. day-closeout skill: after "Open loops", add an observations section;
   the agent records a response per observation via
   `tools/observation-closeout/observations.py respond`.
Neither was applied here. No nightly scheduling was enabled.

## Checks performed

- `verify_overlay.py --core-only` passes with new Remember markers and a
  guard that the patch adds no paste/clipboard path.
- Official composition flow (`prepare-app.sh --core-only`) applies
  `patches/syll-remember.patch` cleanly after the double-tap disable patch.
- Shortcut harness (real composed handler): single tap unchanged, double-tap
  latches a hands-free observation session, later tap finishes it, latch
  unavailable falls back to ordinary handling, hold unchanged.
- Observation store tests: save moves audio and persists owner-only records;
  awaiting-review contract; failure keeps audio in `Failed/` without entering
  the review queue; diagnostic deletion cannot touch observations; correction
  preserves the original text.
- Cleaner suite and diagnostics tests still pass (unchanged behavior).
- `build-local-app.sh --core-only` succeeded; the built bundle's dylib
  contains the Remember code paths. The candidate was not signed with the
  Apple Development identity, not installed, and not launched (a second copy
  against live data is forbidden).
- Rendered UI evidence (no app launched): `build/observation-render/` shows
  the actual `SyllObservationOutcomeView` for saved/failed and the exact
  "Remember" control-bar marker snippet; surrounding control-bar chrome in
  the render is a stand-in for upstream components.
- `validate_project.py` reports pre-existing unrendered placeholders;
  identical failure on `main`, not introduced here.

## Remaining uncertainty

- The double-tap gesture timing (0.5 s window) and the visible marker have
  not been felt by David; the historical Command Mode double-tap QA failed
  on a different action, and this latch reuses that gesture shape.
- Transcription quality for observations inherits the open capture/short-
  utterance problems; nothing here claims otherwise.
- The closeout integration is proven as a bridge contract with synthetic
  data, not yet wired into the actual day-closeout run.
- The candidate is ad-hoc signed; QA installation needs the established
  Apple Development route and a fresh build number, as a separate
  authorization.

## Human QA journey (after an approved install)

1. Double-tap Fn, say "Remember: the deploy pipeline feels fragile", tap Fn
   once more. Expect the "Remember" marker while recording, then "Saved to
   observations" with the text. Nothing should appear in the current app or
   on the clipboard.
2. Double-tap Fn, speak, then double-Esc: nothing saved.
3. Menu bar → Observations: count awaiting review, latest preview, reveal
   folder, manual copy.
4. Ordinary hold-Fn dictation, Copy Last, dictionary, and clipboard behavior
   unchanged.
5. At closeout: run `tools/observation-closeout/observations.py list` and
   respond to each observation; unresolved ones must resurface next time.
