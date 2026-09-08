# Syll — Dictation Quality & Control

Date: 2026-09-08
Status: accepted product direction; implementation and human experiential QA pending

## Product authority

The product is called **Syll**.

Preserve the existing product concept and interaction model. David likes Syll overall, including its small footprint, simplicity, icon, and basic recording interaction. This work is a quality-and-control improvement, not a rewrite or expansion into a transcription workstation.

## Observed product feedback

Recognition is useful but not good enough, especially for names and domain terminology. Known examples include Shukuru, Kean, and Supabase. Microphone distance can contribute to recognition errors, so failures must be diagnosed across recognition and post-processing rather than assumed to be deterministic cleanup failures.

A normal user must be able to teach Syll terminology from the product UI. The minimum semantics are:

- preferred vocabulary: a word/name the user wants Syll to recognise and preserve, e.g. `Shukuru`;
- alias/reassignment: a form the recogniser may produce mapped to the preferred spelling, e.g. `Super Base` -> `Supabase`.

These should remain one simple Personal Dictionary concept unless implementation evidence proves that separating them is necessary. A dictionary entry is only effective when subsequent real dictation benefits from it.

Cleanup for this slice must not depend on an LLM. Improve deterministic/local cleanup conservatively: remove only high-confidence dictation debris/fillers; improve punctuation, casing, and terminology; preserve intended meaning; do not paraphrase, creatively rewrite, or silently delete meaningful hesitation/qualification. Behaviour must be inspectable and predictable.

The bottom recording indicator is too wide. Preserve the red stop control and waveform, but remove excessive horizontal empty space so the HUD hugs meaningful content while remaining balanced and easy to hit.

## Grounded repository state before implementation

- GitHub `main` and `codex/voiceink-personal-dictionary` both point to `3984c4598e9baeb60aba3937e3188490dc262416` at the start of this supervision cycle.
- The repository is a thin reproducible overlay over `Beingpax/VoiceInk@3c211dab63454f18cf3f8b58750ec6bf3f5b4d17`.
- Existing source already contains a unified Personal Dictionary model with preferred spelling + aliases, deterministic non-cascading correction, persistence in existing VoiceInk models, a recognition cache, and an optional fail-open FluidAudio vocabulary-boosting path.
- Historical handoff evidence explicitly leaves real speech improvement, microphone/hotkey/insertion behaviour, cleanup quality, and human acceptance unverified. The candidate was built historically but not established as David's current installed accepted Syll.
- GitHub-only supervision cannot truthfully establish local worktree dirtiness or the identity of the currently installed app bundle; the local executor must record those facts before mutation.

## Smallest coherent implementation slice

Implement **Syll Dictation Quality & Control** as one bounded slice:

1. Personal Dictionary effectiveness
   - Keep one simple user-facing dictionary surface.
   - Preferred spelling with no alias must persist and feed every supported recognition-vocabulary path.
   - Aliases must map deterministically to the preferred spelling in a single non-cascading pass.
   - Saving/editing/enabling/disabling/deleting entries must refresh effective recognition/correction state without restart where practical.
   - Do not rely on repository `dictionary.yaml` for normal user operation.

2. Recognition integration
   - First diagnose which recogniser/path David's installed Syll actually uses.
   - Reuse existing provider/native vocabulary hooks where supported.
   - Do not enable experimental FluidAudio boosting globally by default merely to satisfy this Feature.
   - Fail open: unsupported boosting must not break transcription; deterministic correction remains available.

3. Deterministic/local cleanup
   - Add a local deterministic cleanup stage after recognition/dictionary correction and before delivery.
   - At minimum handle conservative conversational filler removal, whitespace/punctuation normalization, sentence-start casing, sentence-final punctuation, and terminology preservation.
   - High-confidence removable debris may include standalone discourse fillers such as `um`/`uh` and narrowly-scoped sentence-leading `yeah so` / `so` patterns when removal does not change qualification.
   - Preserve meaningful hedges/qualifiers such as `probably`, `maybe`, `I think`, `sort of`, and repetitions where semantic intent is ambiguous.
   - Do not call an LLM, enhancement provider, hosted cleanup service, or hidden second model for this stage.
   - Keep the transform deterministic and directly unit-testable.

4. Recording indicator
   - Inspect the actual pinned VoiceInk/Syll recording HUD implementation.
   - Reduce fixed/minimum width, spacers, padding, or frame constraints causing excess horizontal space.
   - Preserve stop control, waveform, interaction hit targets, and overall visual language.
   - This is a layout finishing change only.

## Verification contract

Automated evidence must cover at least:

- preferred-only dictionary persistence and retrieval;
- alias persistence and one-pass correction (`Super Base` -> `Supabase`);
- case/boundary behaviour and non-cascading correction regression;
- recognition cache refresh after CRUD / enable-disable operations where architecture permits;
- deterministic filler cleanup on representative conversational text;
- preservation of meaningful hedges/qualifiers and ordinary prose;
- punctuation/casing normalization without paraphrase;
- terminology preservation through cleanup;
- existing focused tests still passing.

Automated tests are not Feature acceptance.

## Required local build evidence

The local executor must record:

- starting branch, HEAD, and worktree state;
- currently installed Syll/VoiceInk bundle identity before replacement if determinable;
- exact prepared/built commit;
- build/signing verification result;
- exact installed app path/bundle identity used for David's QA;
- any local-only uncommitted state left behind.

## Human QA gate

Prepare an installed Syll build for David. David should only have to launch it, add one dictionary term and one alias, dictate several natural sentences, inspect resulting text, glance at the recorder HUD, and return PASS/FAIL with natural-language feedback.

The script must naturally cover Shukuru, Kean, Supabase, one new preferred vocabulary term, one alias, obvious fillers, and ordinary prose that should not be over-cleaned.

Do not ask David to debug recogniser internals.

## Definition of success

Success is not that dictionary code exists. Success requires evidence that David can teach his installed Syll terminology himself, receives noticeably better deterministic non-LLM cleanup without meaning-changing rewrites, and sees a materially tighter recording indicator while the product remains small and simple.
