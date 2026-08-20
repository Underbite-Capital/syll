# Research plan

## Decision contract

- **Decision:** Whether a configuration-first VoiceInk spike is sufficient to test private local dictation against Wispr Flow in David's real agent workflow.
- **Why now:** The supplied brief asks for a same-day try-it build and explicitly forbids beginning a product build.
- **Review test:** David completes a BOYA corpus comparison and 20 real prompts across ChatGPT, Claude and Cursor.
- **Research cutoff:** 2026-08-20
- **Time/effort bound:** Stop shell work at roughly 90 minutes; do not add an ASR provider abstraction or redesign VoiceInk.
- **Evidence that would reverse the current direction:** VoiceInk cannot build or paste reliably, Parakeet/Whisper quality is clearly below Flow, dictionary corrections are brittle, or release-to-text latency is unacceptable.

## Intensity

Selected intensity: **Light**.

This is a private, internal, low-risk, reversible experiment with one named user, direct source code, official documentation and an explicit human trial. Commercialisation, sensitive-data processing and long-lived architecture are out of scope.

## Commercial questions

1. Is David willing to replace or reduce Wispr Flow usage after 20 prompts?
2. Is the remaining pain attributable to ASR, vocabulary, cleanup, latency or macOS interaction?
3. Is there any justified next investment beyond one small, fixable cause?

## Technical questions

1. Does current VoiceInk already supply the macOS shell and preferred Parakeet V3 path?
2. Can the Underbite dictionary be imported without creating new persistence or provider layers?
3. Does deterministic replacement satisfy case, boundary and punctuation requirements?
4. Is a second local Whisper model available in the same shell for a fair corpus comparison?
5. Is Voxtral via MLX easy enough to add during this spike?

## Search and source plan

| Question | Source class | Search system or corpus | Query family | Inclusion / exclusion rule | Completion criterion |
| --- | --- | --- | --- | --- | --- |
| VoiceInk shell/build | official repository and docs | GitHub, VoiceInk docs, local clone | build, shortcuts, audio, output | Current official sources only | Build path and exact upstream commit recorded |
| ASR candidates | official repository/model docs | FluidAudio, WhisperKit, Mistral model card | Parakeet V3, Whisper, Voxtral local runtime | Primary maintainer sources; generic WER is orientation only | Candidate set and exclusions are explicit |
| Dictionary | local source plus official docs | VoiceInk source/docs | word replacement, vocabulary, import | Verify code path, not marketing claims | Import artifact and boundary behavior verified |

## Synthesis rule

Keep the internal adoption question separate from technical capability. A successful compile is not evidence that David prefers the workflow; only the BOYA corpus and 20-prompt trial can answer that.
