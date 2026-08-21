# PRD handoff — local-first voice dictation

## Purpose of this handoff

The spike established that a private, local-first macOS dictation experience can be assembled quickly from the open-source VoiceInk shell. It did not establish product-market fit, model superiority, or Wispr Flow parity. The next step is to turn the evidence and David's intent into a proper product requirements document rather than continuing to patch the spike opportunistically.

## What is implemented

### Runnable application

- VoiceInk 2.11 is pinned at upstream commit `fda316996d87bc0c7b68d11a741b5c5aec8d8617`.
- An arm64 macOS Debug build was produced, ad-hoc signed, signature-verified, and launched successfully.
- VoiceInk supplies the existing macOS product shell: onboarding, permissions, global push-to-talk, audio-device selection, local/cloud model management, recording feedback, history, modes, dictionary plumbing, AI enhancement, cursor insertion, and auto-send controls.
- Parakeet V3 runs locally through FluidAudio. Whisper Large V3 Turbo is the prepared local comparator.
- Groq and OpenRouter are already supported by VoiceInk for optional cloud enhancement. David found enhancement through OpenRouter too slow and intends to try Groq.

### David-specific additions

- A small two-file Swift patch adds a global, default-on **Dictionary corrections** toggle and bypasses deterministic replacements when disabled. The patch is stored at `patches/voiceink-dictionary-toggle.patch`.
- `dictionary.yaml` contains 26 canonical terms and 18 deterministic alias groups for Underbite and David's working vocabulary.
- `cleanup-prompt.txt` preserves meaning, instructions, uncertainty, examples, profanity, and tone while allowing only filler/repetition cleanup, explicit self-correction resolution, punctuation, and paragraph breaks.
- `prototype/VoiceInk_David_Settings.json` imports the dictionary and cleanup prompt into VoiceInk.
- `evidence/test-corpus.md` contains 20 diagnostic utterances.
- `evidence/benchmark.csv` and `evidence/20-prompt-trial.csv` are ready to capture model, latency, correction-burden, and adoption evidence.
- `TRY-IT.md` documents the setup and bounded human trial.
- Commercial and technical diligence, claim/source ledgers, a decision log, and the original brief are preserved in the repository.

### What has actually been observed

- The locally built app launches and completes enough onboarding to download Parakeet V3 and reach normal VoiceInk operation.
- David has dictated successfully through the application and sees the spike as evidence that the core experience is feasible.
- The current VoiceInk interface is substantially broader than the desired focused experience.
- Enhancement latency matters immediately; an otherwise capable cleanup path can damage the interactive experience when it is too slow.
- The repository is private under `Underbite-Capital`.

### What is not yet established

- No local ASR model has formally won on David's BOYA corpus.
- Typical release-to-text latency has not been measured.
- Dictionary performance has not been scored on the prepared corpus.
- Cross-app reliability and never-submit behavior have not been recorded systematically across ChatGPT, Claude, and Cursor.
- No 20-prompt adoption result or direct preference against Wispr Flow has been recorded.
- The spike is evidence of technical feasibility, not evidence that the current build is ready for wider users.

## What is known about David's intent

- David is not the only Wispr Flow user in his orbit; this may be a product opportunity rather than a one-person utility.
- The intended experience is private and local-first, with cloud use explicit and optional.
- The interaction should feel immediate: hold a hotkey, speak, release, and receive corrected text at the cursor without automatic submission.
- The meaningful benchmark is Wispr Flow on real agent prompts, especially correction burden and latency—not generic word-error rate.
- Domain vocabulary is a first-class product capability, not a settings afterthought.
- Cleanup must preserve intent and voice. It must never answer, summarize, professionalize, soften, or invent.
- The main product should be much simpler than VoiceInk's full dashboard. Once configured, it should behave primarily as an invisible menu-bar utility.
- David does not want a broad provider framework or speculative architecture. He wants the smallest experience that users are genuinely happy to keep using.
- David is comfortable building on VoiceInk and likes the GPLv3 constraint. Any derivative distribution must be planned as an open-source product rather than treated as proprietary code.
- David is confident the experience can become something he is happy with and wants to continue product definition rather than stop at the spike.

## Product ideas worth evaluating in the PRD

These are proposals, not settled requirements.

### 1. Define the wedge before broadening the user

Start with macOS users who dictate long, instruction-heavy AI prompts and repeatedly use project-specific terminology. Do not begin as a general voice assistant or meeting transcription product.

### 2. Make the daily surface nearly invisible

Keep VoiceInk's mature engine and settings behind the product, but explore a **Lite** presentation:

- menu-bar status;
- selected microphone;
- selected transcription model;
- push-to-talk shortcut;
- dictionary on/off;
- cleanup on/off and local/cloud disclosure;
- a direct path to advanced settings when needed.

Hide rather than delete dashboard, history, provider, licensing, and advanced configuration surfaces so the fork remains maintainable.

### 3. Treat latency as a product budget

Define separate budgets for capture finalization, ASR, deterministic correction, optional cleanup, and cursor insertion. Cleanup should be automatically skippable or disabled when it cannot stay inside the interaction budget.

### 4. Make dictionaries portable and collaborative

Evolve the YAML/import experiment into versioned vocabulary packs with canonical terms, aliases, optional descriptions, conflict handling, and clear scope. Evaluate personal, project, and team dictionaries without adding contextual repair until deterministic evidence shows a need.

### 5. Prove the engine choice with correction burden

Run Parakeet V3 and Whisper Large V3 Turbo against identical BOYA recordings. Choose the default using edits required per prompt and perceived delay. Investigate another ASR engine only if neither is within striking distance.

### 6. Separate private transcription from optional enhancement

The UI should state where each stage runs. Local ASR and deterministic correction should remain the baseline. Groq or another cloud model may be an explicitly enabled cleanup option, with a local cleanup path assessed separately.

### 7. Validate beyond David without prematurely productising

Recruit a small cohort of existing Wispr Flow users who dictate into AI tools. Observe setup, first successful prompt, correction burden, latency tolerance, terminology needs, and whether they keep using it after the novelty wears off.

### 8. Decide the VoiceInk relationship explicitly

The PRD should record whether the product is:

- a maintained GPLv3 VoiceInk distribution with a focused default experience;
- a thin downstream patch set intended to stay close to upstream; or
- a set of upstream contributions plus Underbite vocabulary/experience tooling.

Prefer the smallest maintenance burden compatible with the intended experience.

## Decisions the PRD must force

1. Who is the first user segment beyond David?
2. What exact job are they hiring the product to do?
3. Which parts of the pipeline must remain local, and what cloud behavior is acceptable?
4. What latency and correction-burden thresholds define a usable experience?
5. What is the minimum daily UI versus advanced configuration?
6. Is vocabulary personal, project-scoped, team-scoped, or some staged combination?
7. What evidence graduates the spike into an MVP?
8. What evidence stops the product?
9. How will the GPLv3 VoiceInk relationship, attribution, source distribution, and upstream maintenance be handled?
10. What is deliberately outside the first release?

## Suggested next sequence

1. Write and freeze the PRD around the user/job, experience contract, privacy boundary, success metrics, licence strategy, and explicit non-goals.
2. Complete David's 20-prompt trial and fill the existing evidence tables.
3. Interview and observe a small set of real Wispr Flow users using the same prompt-oriented workflow.
4. Convert the strongest evidence into acceptance tests and latency budgets.
5. Prototype the reversible Lite presentation while preserving VoiceInk's underlying settings and engine.
6. Decide whether to maintain a downstream distribution or propose compatible changes upstream.
7. Only then define an MVP build and distribution plan, including signing, updates, privacy disclosure, source availability, and support boundaries.

## Repository reading order

1. `reference/spike-brief.txt`
2. `README.md`
3. `SPIKE-REPORT.md`
4. `TRY-IT.md`
5. `dictionary.yaml`
6. `cleanup-prompt.txt`
7. `decisions/DECISION-LOG.md`
8. `research/SYNTHESIS.md`
9. `research/TECHNICAL-LITERATURE-REVIEW.md`
10. `research/COMMERCIAL-DILIGENCE.md`
11. `evidence/test-corpus.md`
12. `patches/voiceink-dictionary-toggle.patch`

Treat the original brief as the spike contract, this handoff as current intent and product framing, and the empty evidence fields as unknowns—not as permission to invent results.
