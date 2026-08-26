# Manual QA — VoiceInk personal dictionary

Run core-only first. David performs these checks in the actual apps he dictates into; an agent should not substitute browser automation for this acceptance step.

## Build and baseline

- [ ] `python3 scripts/verify_overlay.py` passes.
- [ ] `./scripts/prepare-app.sh --core-only --reset` completes.
- [ ] VoiceInk builds and launches.
- [ ] Existing microphone, shortcut, model selection, and cursor insertion still work unchanged.

## Dictionary

- [ ] Legacy vocabulary appears on the single Personal Dictionary screen.
- [ ] Add `Underbite` with aliases `under bite, underbyte`.
- [ ] Dictating “I spoke to under bite” inserts `I spoke to Underbite`.
- [ ] `Stu` does not alter the word `student`.
- [ ] Punctuation around an alias is preserved.
- [ ] Two occurrences are both corrected.
- [ ] Disabling an entry stops its deterministic correction.
- [ ] Editing preferred spelling and aliases works.
- [ ] Deleting a term does not recreate it on the next visit.

## Cleanup

Use the prompt title `David cleanup` or `Clean Dictation` so the validator is active.

- [ ] Filler speech and accidental repetition are removed without changing the ask.
- [ ] Profanity, uncertainty, negation, filenames, dates, and numbers survive.
- [ ] Exact preferred spellings survive cleanup.
- [ ] A provider error inserts the deterministic transcript.
- [ ] A timeout inserts the deterministic transcript.
- [ ] A deliberately bad response such as “Sure, here is the cleaned text…” is rejected.
- [ ] A response that drops a number is rejected.

## Recognition boosting

Only after core acceptance, prepare the full overlay.

- [ ] With boosting off, transcription matches the core baseline.
- [ ] Enabling boosting handles the first-use CTC model download clearly.
- [ ] Difficult terms improve on repeated clips rather than merely changing once.
- [ ] Ordinary words do not start becoming dictionary terms.
- [ ] A forced boosting failure still returns ordinary transcription.
- [ ] Felt release-to-cursor latency remains acceptable.

## Five-day acceptance

- [ ] Use the fork as ordinary dictation for five working days.
- [ ] Log every manual correction that still recurs.
- [ ] Log every semantic cleanup error.
- [ ] Keep the fork only if it is preferable to the current setup in normal work.
