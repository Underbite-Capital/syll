# Manual QA — VoiceInk personal dictionary

Run core-only first. David performs these checks in the actual apps he dictates into; an agent should not substitute browser automation for this acceptance step.

## Build and baseline

- [ ] `python3 scripts/verify_overlay.py` passes.
- [ ] `./scripts/prepare-app.sh --core-only --reset` completes.
- [ ] CORE retains FluidAudio `c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7` and contains no boosting adapter/control.
- [ ] `./scripts/build-local-app.sh --core-only` produces a verified ad-hoc-signed app with no CloudKit, push, or keychain-group entitlement.
- [ ] With VoiceInk quit, `backup-voiceink.sh` creates a new verified backup outside Git.
- [ ] Focused corrector and cleanup-validator XCTest suites pass without a bootstrap crash.
- [ ] VoiceInk launches from the verified build output; do not replace the known-good app.
- [ ] Existing microphone, shortcut, model selection, and cursor insertion still work unchanged.

## Dictionary

- [ ] Legacy vocabulary appears on the single Personal Dictionary screen.
- [ ] One vocabulary-only probe and one replacement-only probe migrate once without data loss or duplication.
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
- [ ] A response that drops one occurrence of a repeated number is rejected.
- [ ] A response that adds or duplicates a number is rejected.

For deterministic fallback checks, first record the current Local CLI command and timeout. Use output mode **Paste** and auto-send **None**, then restore the saved settings afterward.

| Check | Local CLI command | Expected result |
| --- | --- | --- |
| Provider failure | `/usr/bin/false` | Corrected transcript is inserted. |
| Timeout | `/bin/sleep 10` with timeout `5` | Corrected transcript is inserted after the timeout. |
| Assistant preamble | `/bin/echo 'Sure, here is the cleaned text.'` | Candidate is rejected; corrected transcript is inserted. |
| Dropped repetition | `/bin/echo 'Send 5 now.'` for source “Send 5 and 5 now.” | Candidate is rejected. |
| Invented number | `/bin/echo 'Send it on 6 September.'` for source “Send it in September.” | Candidate is rejected. |

David performs the actual dictation and semantic cleanup checks. These fixed commands exercise failure paths only; they do not replace human acceptance.

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
