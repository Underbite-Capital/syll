# Capture reliability: real-use evidence and cleanup repair candidate

Date: 2026-09-29. Candidate branch `candidate/cleanup-first-word-repair`,
commit `9bfa8d7`. Installed app untouched (build 244, source `b602c74`).
Source base for evidence: installed build 244's operational corpus.

## Effective evidence storage (observed, supersedes historical description)

The 2026-09-26 investigation documented the ordinary corpus as capped at 100
sessions / 24 h / 512 MiB. The shipped code (`SyllFailureEvidenceStore`) actually
retains 3,000 sessions / 30 days / 4 GiB, and `SyllOperationalLog` 5,000
sessions / 30 days. Observed on disk: 448 ordinary evidence directories
(WAV + raw recognizer text + final text) and 450 timing JSON files spanning
2026-09-26 12:00 to 2026-09-29 11:47, 137 MiB total. No marked failures exist;
the `marked/` directory has never been used. No startup-cancellation events
were recorded. Retention policy was not changed.

## Observed facts (measured, not inferred)

From all 448 completed ordinary sessions unless noted:

- Startup is fast: app shortcut-handler time to first accepted audio buffer
  median 67 ms, p90 92 ms, max 106 ms. The shortcut-handler timestamp is when
  the app's handler ran; it is not a measured physical keypress time. Zero
  dropped buffers in the whole corpus.
- 51 of 447 analyzable WAVs (11%) contain speech-level energy (above -45 dBFS)
  in the first 20 ms; the other sessions show a median 180 ms of leading
  silence. Initial speech-level energy identifies possible truncated-onset
  recordings. It does not by itself prove missing words, and 11% is the share
  of sampled recordings with this onset shape, not a measured capture-failure
  rate. How much speech preceded the first buffer is not observable offline.
- 188 of 447 sessions had their text altered after recognition. Most are
  upstream TextNormalizer number conversions ("first" -> "1st") and intended
  hesitation removal. Syll's own deterministic cleaner deleted
  utterance-leading spoken words in 18 sessions: 5x "Yeah, so ..." openings
  (two words each) and 13x leading hesitation tokens. This repair changes
  only the 5 "Yeah, so ..." cases; the 13 Uh/Um removals are unchanged
  policy in this slice.
- One genuine short utterance was destroyed by cleanup: raw "Mm-hmm." (1.24 s)
  was delivered as "-." because the hesitation set consumed both syllables.
- Short-utterance recognition produced plausible raw transcripts on the 33
  sessions under 1.5 s ("Let's go.", "Commit and push."). Plausible is not
  verified accurate; no unmarked recording was labeled a failure.

## Hypotheses (not established)

- The 51 mid-speech starts are consistent with the early-start-cue lead (the
  start sound plays before capture is ready, so speech on the cue is lost),
  but offline data cannot prove why David was already speaking.
- Whether the 13 leading hesitation removals ("Uh", "Um") bother David is a
  product judgment; they were left intact.

## Repair (category C boundary: post-recognition deletion)

`DeterministicDictationCleaner` no longer deletes utterance-leading words:
the "yeah so" opening strip is removed, and if cleaning would leave no
letters or numbers the cleaner falls back to the recognized text. Hesitation
removal elsewhere, punctuation/casing, dictionary correction, and all other
behavior are unchanged.

Before/after over all 448 stored raw recognizer outputs (same input, old vs
new cleaner): exactly 6 sessions change — the five "Yeah, so ..." openings
keep their first two words, and "Mm-hmm." stays "Mm-hmm.". The other 442
outputs are byte-identical (successful controls unchanged). Six changed
outputs out of 448 is approximately 1.3% of the sampled corpus; it is not a
measured percentage of David's experienced failures.

End-to-end replay through the existing `tools/recognition-eval` harness
(pinned FluidAudio `c7b13a3`, int8 Parakeet TDT v3) on the two shortest
affected real WAVs reproduced the stored runtime raw text exactly and now
yields "Mm-hmm." and "Yeah, so now it's really small. ..." after cleanup.

## Mechanical checks

- Standalone cleaner suite (the CI gate) re-pinned and passing, with new
  regressions for the two real failure shapes.
- `verify_overlay.py --core-only` passes.
- Clean composed build in a disposable worktree at `9bfa8d7`:
  `prepare-app.sh --core-only` + `build-local-app.sh --core-only` succeeded;
  ad-hoc signature verified. Nothing installed or launched.

## Remaining uncertainty and next diagnostic boundary

This repair covers only the post-recognition deletions it changes: the 5
"Yeah, so ..." openings and the "Mm-hmm." collapse, 6 of 448 sampled sessions
(~1.3% of the sample, not a measured share of experienced failures). The 13
leading Uh/Um removals are deliberate policy and remain. The possible
truncated-onset recordings (51 of 447 sampled WAVs with speech-level energy
in the first 20 ms) are untouched: whether words were actually lost there is
unproven, and the candidate follow-up is gating the start cue on actual
capture readiness (first accepted buffer) rather than on the early
panel/sound path. That needs live timing evidence and David's QA — replay
cannot prove hardware capture, and delaying the start cue is not presumed to
fix it. Whether recognition quality on complete short clips meets
David's bar requires his corrections on real failures (the mark-latest-failure
menu flow), which the corpus does not yet contain.

## Human QA checkpoint

Candidate presented, not installed. Smallest meaningful QA journey: install
only on explicit approval, then (1) dictate "Mm-hmm." and confirm the delivered
text is not "-."; (2) dictate a sentence opening with "Yeah, so ..." and
confirm both words survive; (3) confirm ordinary dictation, dictionary terms,
clipboard behavior, and the indicator are unchanged.
