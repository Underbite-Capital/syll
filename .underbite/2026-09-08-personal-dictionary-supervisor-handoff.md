# [Delivery owner] prepare safe Personal Dictionary QA candidate — Syll

```yaml
handoff_id: HANDOFF-SYLL-PERSONAL-DICTIONARY-SAFE-QA-2026-09-08
artifact_id: FEATURE-SYLL-DICTATION-QUALITY-CONTROL
artifact_version: 47f0b645cf977f1003388d2a26452b724cca2f54 + documented local candidate changes
from_role: local feature executor
to_role: delivery owner
assigned_human: David
assigned_agent_or_task: supervisor (assignee to be selected by David)
objective: Deliver one safely installed Syll QA candidate in which David can use one simple Personal Dictionary to add preferred terms and optional heard-as aliases, with vocabulary context sent to the selected recognizer where actually supported.
why_now: David has confirmed the working Syll still transcribes, but cannot yet use the implemented Personal Dictionary because the candidate has not been safely installed. The prior isolated Apple Development pilot also exposed a visible duplicate VoiceInk/Syll identity and is not a migration solution.
exact_ask: Independently inspect the current candidate and evidence; preserve the core AssemblyAI path; supervise the smallest safe route to a single, human-QA Syll build. Return an exact candidate/install plan and evidence, or a precise signing/identity blocker. Do not claim acceptance.
definition_of_done: A reviewable candidate is built with a stable, unambiguous Syll identity; its dictionary UI and effective vocabulary/correction path are evidenced; installation safety versus the working Syll is explained; David receives only the short experiential QA script. If safe installation is not yet provable, return a buildable candidate plus the exact prerequisite.
authority_requested: Repository inspection and local candidate preparation only. Replacing /Applications/Syll.app, TCC reset, Accessibility changes, external publishing, and feature acceptance remain human-controlled gates.
independence_required: true
scope:
  - One Personal Dictionary UI: preferred word, optional heard-as alias, add, search, edit, delete.
  - Persistence, duplicate/conflict handling, non-cascading correction, preferred-spelling preservation, and recognition-cache refresh.
  - Actual vocabulary context for the selected recognizer only; current local selection is AssemblyAI.
  - Conservative deterministic cleanup and compact recorder HUD only insofar as already included in the candidate.
  - Stable local identity/signing investigation needed to make a QA install safe.
non_goals:
  - A second Boosting screen, an LLM, automatic vocabulary learning, an updater product, or a distributable-release claim.
  - Enabling experimental FluidAudio merely to claim boosting.
  - Replacing, resetting, re-signing, deleting, or otherwise disturbing the current /Applications/Syll.app before a safe path is demonstrated.
  - Asking David to debug recognizer internals.
inputs:
  - .underbite/2026-09-08-dictation-quality-control.md
  - .underbite/2026-09-08-local-candidate-preparation.md
  - .underbite/2026-09-08-macos-accessibility-identity-handoff.md
  - .underbite/2026-09-08-apple-development-signing-pilot.md
  - README.md
  - docs/IMPLEMENTATION-HANDOFF.md
  - overlays/core/VoiceInk/Views/Dictionary/VocabularyView.swift
  - overlays/core/VoiceInk/Views/Dictionary/WordReplacementView.swift
  - overlays/core/VoiceInk/Services/PersonalDictionaryService.swift
  - overlays/core/VoiceInkTests/PersonalDictionaryServiceTests.swift
source_identities:
  - Current working app: /Applications/Syll.app; bundle com.prakashjoshipax.VoiceInk; working Accessibility must be preserved.
  - Candidate source commit: 47f0b645cf977f1003388d2a26452b724cca2f54.
  - Selected recognizer/provider observed locally: AssemblyAI.
  - AssemblyAI batch/streaming vocabulary path: VocabularyWord projection -> LLMkit AssemblyAIClient -> keyterms_prompt.
evidence_already_completed:
  - Core overlay static validation and preparation passed.
  - Core candidate build passed.
  - 10 focused PersonalDictionaryCorrectorTests and PersonalDictionaryServiceTests passed, including preferred-only and alias persistence, edit/delete, conflict handling, cache refresh, Super Base -> Supabase, non-cascading correction, and preferred spelling preservation.
  - Candidate UI removes inspector-only path/revision/bias diagnostics and refresh control from the primary dictionary surface.
  - Experimental FluidAudio booster remains disabled because AssemblyAI is the selected recognizer and has its own actual key-term context path.
blockers:
  - The Personal Dictionary candidate is not the working installed Syll.
  - The working Syll's historical local/ad-hoc-style identity is not suitable as a stable update identity.
  - No Developer ID Application certificate is currently available; no distribution-ready claim is permitted.
  - Apple Development pilot v1 proved signing components must be signed consistently, but also produced an unacceptable visible VoiceInk/Syll duplicate and has not completed Accessibility continuity testing.
held_decisions:
  - Permanent production bundle identity and signed update path remain unresolved.
  - Developer ID Application and notarization remain future human-controlled prerequisites for distribution.
return_to_role: local feature executor
return_to: David / current Syll task
return_contract: Return one evidence-backed recommendation: (a) a safe local QA candidate and exact non-destructive install procedure, or (b) the precise human-controlled signing/identity prerequisite. Include recognizer/provider, vocabulary delivery path, signature/designated requirement evidence, all remaining dirtiness, and the exact QA prompt. Do not mark the Feature accepted.
due_or_review_by: next supervised Syll session
```

## Product truth the supervisor must preserve

David wants a single small Personal Dictionary, not a vocabulary inspector and not multiple configuration surfaces.

- `Shukuru` means: preserve/boost that spelling where the active recognizer supports it.
- `Supabase` with heard-as `Super Base` means: provide `Supabase` to the recognizer and deterministically correct `Super Base` to `Supabase` if it appears.
- Changes should take effect on the next dictation without a Syll restart where the active provider permits it.

The current candidate persists canonical entries in SwiftData `WordReplacement`, retains `VocabularyWord` as a legacy and compatibility projection, applies alias correction once from the original transcript, then runs conservative deterministic cleanup. For the currently selected AssemblyAI provider, `PersonalDictionaryService.recognitionTerms` supplies each preferred spelling and its aliases to batch and streaming connections; LLMkit emits them as AssemblyAI `keyterms_prompt`. This is real provider context, not a replacement-table substitute. It does not prove that David's actual speech will improve; that remains human QA.

## Required QA when a safe installed candidate exists

Give David only:

1. Open Personal Dictionary.
2. Add `Shukuru` as a preferred term.
3. Add `Supabase` with spoken alias `Super Base`.
4. Add one new preferred term of his own choosing.
5. Dictate naturally:

   > Yeah so um I think we should send the Shukuru update to Kean tomorrow. We use Super Base for the backend, and I probably like the current setup. Maybe we should keep that part as it is. [new preferred term] is also something I say often.

6. Inspect the resulting text and glance at the bottom recording indicator.
7. Return only PASS/FAIL plus whatever felt wrong.

Expected: terminology should feel materially more controllable; opening `yeah so` and `um` debris disappears; `probably`, `like`, `Maybe`, and intended wording remain; casing/punctuation improve; and the recorder HUD remains compact with stop control and waveform.

No action needed from David until the supervisor returns either a safe QA candidate or a concrete human-controlled signing prerequisite.
