# Syll — Dictation Quality & Control

Date: 2026-09-08
Status: implementation candidate automated-green; local install and human experiential QA pending

## Product authority

The product is called **Syll**.

Preserve the existing product concept and interaction model. David likes Syll overall, including its small footprint, simplicity, icon, and basic recording interaction. This work is a quality-and-control improvement, not a rewrite or expansion into a transcription workstation.

## Observed product feedback

Recognition is useful but not good enough, especially for names and domain terminology. Known examples include Shukuru, Kean, and Supabase. Microphone distance can contribute to recognition errors, so failures must be diagnosed across recognition and post-processing rather than assumed to be deterministic cleanup failures.

A normal user must be able to teach Syll terminology from the product UI. The minimum semantics are:

- preferred vocabulary: a word/name the user wants Syll to recognise and preserve, e.g. `Shukuru`;
- alias/reassignment: a form the recogniser may produce mapped to the preferred spelling, e.g. `Super Base` -> `Supabase`.

These remain one simple Personal Dictionary concept. A dictionary entry is only effective when subsequent real dictation benefits from it.

Cleanup for this slice must not depend on an LLM. Improve deterministic/local cleanup conservatively: remove only high-confidence dictation debris/fillers; improve punctuation, casing, and terminology; preserve intended meaning; do not paraphrase, creatively rewrite, or silently delete meaningful hesitation/qualification. Behaviour must be inspectable and predictable.

The bottom recording indicator is too wide. Preserve the red stop control and waveform, but remove excessive horizontal empty space so the HUD hugs meaningful content while remaining balanced and easy to hit.

## Grounded repository state before implementation

- GitHub `main` and `codex/voiceink-personal-dictionary` both pointed to `3984c4598e9baeb60aba3937e3188490dc262416` at the start of this supervision cycle.
- Product authority was then recorded on `main`; `main` reached `5144a49c23908bde1c81ea44562709a8515d4d44` before the implementation branch was created.
- The repository is a thin reproducible overlay over `Beingpax/VoiceInk@3c211dab63454f18cf3f8b58750ec6bf3f5b4d17`.
- Existing source already contained a unified Personal Dictionary model with preferred spelling + aliases, deterministic non-cascading correction, persistence in existing VoiceInk models, a recognition cache, and an optional fail-open FluidAudio vocabulary-boosting path.
- The existing `TranscriptionAutoCleanupService` is retention/audio-file cleanup, not text cleanup.
- The upstream compact recorder HUD was hard-framed at 184 pt and used flexible spacers around the status/waveform, explaining the excessive empty width.
- Historical handoff evidence explicitly left real speech improvement, microphone/hotkey/insertion behaviour, cleanup quality, and human acceptance unverified.
- GitHub-only supervision cannot truthfully establish local worktree dirtiness or the identity of the currently installed app bundle.

## Implemented candidate

Branch: `feature/syll-dictation-quality-control`
Automated-green candidate head: `238a10f5c8d3b30d8f920774b693d7516e4772d7`

### Personal Dictionary

The existing one-surface model is retained: preferred spelling plus optional spoken aliases. Existing persistence, one-pass non-cascading correction, recognition cache refresh, and optional provider/local boosting machinery are preserved rather than replaced.

Normal user operation does not require editing `dictionary.yaml`.

### Deterministic/local cleanup

Added `DeterministicDictationCleaner` and wired it into the normal post-recognition path after dictionary correction through `WordReplacementService`.

Current deliberately conservative behaviour:

- trims/collapses whitespace;
- removes sentence-opening `yeah so` only;
- removes the existing small high-confidence hesitation family such as `um`, `uh`, `uhm`, `hmm`;
- normalizes punctuation spacing and duplicate commas produced by filler removal;
- capitalizes the first letter;
- adds terminal punctuation when absent;
- preserves `like`, `probably`, `maybe`, `I think`, `sort of`, `you know`, and other ambiguous semantic hedges rather than guessing.

This path contains no LLM call, enhancement provider, hosted cleanup service, or second model. Optional VoiceInk AI enhancement remains a separate downstream capability and is not required for this cleanup.

### Recording indicator

Added a core overlay for `MiniRecorderView`:

- compact width reduced from 184 pt to 136 pt;
- flexible empty spacers removed in favour of compact 8 pt spacing/padding;
- stop/record control, waveform/status display, mode button, expanded transcript state, and assistant state are preserved.

Human visual judgement is still required; 136 pt is a candidate, not accepted product authority.

## Automated evidence

GitHub Actions run `34192985335` against candidate `238a10f5c8d3b30d8f920774b693d7516e4772d7` passed:

- project metadata validation;
- overlay static verification;
- core overlay preparation and `git diff --check`;
- full overlay preparation and `git diff --check`;
- macOS Swift compilation/execution of deterministic cleanup regression tests.

The cleanup regression suite proves representative filler removal, punctuation/casing, question-mark preservation, decimals, and preservation of meaningful hedges including `maybe`, `sort of`, `probably like`, plus ordinary `yeah` outside the narrowly removed `yeah so` opening.

Existing dictionary implementation evidence still covers preferred/alias persistence, case/boundary handling, non-cascading correction, and cache refresh mechanics. These automated checks do not establish real acoustic recognition improvement.

## Installed-build identity

Not yet established.

This supervisor has repository/GitHub access but no access to David's local macOS checkout, signing identity, Accessibility/Microphone permissions, or currently installed Syll application bundle. Therefore no installed build identity is claimed and no human QA should start from this repository-only state.

The local executor must record before/after state:

- starting branch, HEAD, and worktree dirtiness;
- currently installed Syll/VoiceInk bundle identity if determinable;
- exact candidate commit prepared/built;
- build/signing result;
- exact installed app path/bundle identity used for David's QA;
- actual recognizer/provider selected in the installed app;
- any local-only uncommitted state left behind.

Use the core overlay first unless the installed recognizer specifically justifies the experimental FluidAudio boosting overlay. Do not enable FluidAudio globally merely to make a vocabulary claim.

## Human QA gate

After the local build is installed, David should only need to:

1. launch Syll;
2. in Personal Dictionary add preferred term `Shukuru` with no alias;
3. add preferred term `Supabase` with alias `Super Base`;
4. optionally add one genuinely new preferred term of his choosing so the test is not pre-baked;
5. dictate the short script below naturally;
6. inspect the inserted text and glance at the recorder HUD;
7. return PASS/FAIL with natural-language feedback.

Suggested natural script:

> Yeah so um I think we should send the Shukuru update to Kean tomorrow. We use Super Base for the backend, and I probably like the current setup. Maybe we should keep that part as it is. [new preferred term] is also something I say often.

Judgement:

- `Shukuru`, `Kean`, `Supabase`, and the newly added term should come out correctly enough to feel materially more controllable;
- obvious `yeah so` / `um` debris should disappear;
- `probably`, `like`, `Maybe`, and the substantive wording should remain rather than being rewritten;
- punctuation/casing should be clean ordinary prose;
- the bottom recorder should feel materially tighter while retaining the stop control and waveform.

Do not ask David to debug recognizer internals.

## Exact next action

A local coding executor should check out `feature/syll-dictation-quality-control`, inspect and preserve any existing local worktree changes, prepare the candidate from the pinned upstream commit, build/sign/install it as Syll, record the installed identity and active recognizer/provider here, and then hand David only the human QA gate above.

Do not mark this Feature accepted or complete until David passes experiential QA.
