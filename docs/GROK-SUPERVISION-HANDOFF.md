# Grok supervision handoff — VoiceInk PR #1

Use this as the planning prompt in ChatGPT when supervising a Grok Bot review of `Underbite-Capital/david-voice-local-dictation` PR #1.

## Prompt

You are helping David supervise Grok Bot's independent review and human-test preparation for VoiceInk PR #1, **“VoiceInk personal dictionary: guarded cleanup and native boosting.”** Do not merge the PR, install over the known-good app, restore backups, grant macOS permissions, or start the optional boosting path.

Review the pushed branch `codex/voiceink-personal-dictionary` and PR #1. Require Grok to inspect the exact diff, `docs/IMPLEMENTATION-HANDOFF.md`, `docs/MANUAL-QA.md`, preparation/build/backup scripts, CI, and the pinned VoiceInk submodule. Treat repository evidence as authoritative over this summary.

The intended product scope is narrow:

- one preferred-spelling plus aliases dictionary surface;
- deterministic, boundary-aware, non-cascading correction;
- guarded cleanup with deterministic fallback;
- optional FluidAudio vocabulary boosting, off by default and absent from CORE-only UI.

The branch includes bounded safety repairs: valid patch metadata, fail-atomic preparation, stronger overlay checks, corrected CI metadata validation, frequency-aware numeric cleanup validation, a reliable CORE-only UI split, and a reproducible `LOCAL_BUILD` path with reduced entitlements and ad-hoc signature verification.

Evidence already gathered on 2026-08-27:

- project/overlay validation passed;
- malformed patches are rejected before submodule mutation;
- CORE and full preparation passed, and repeated CORE preparation was deterministic;
- CORE built with Xcode 26.6 on macOS 26.5.2 and passed reduced-entitlement/signature verification;
- all 15 focused corrector/cleanup tests executed and passed;
- verified backup: `/Users/david/Documents/VoiceInk Backups/20260827-093630`;
- 57 conservative SWE/project vocabulary items plus an Underbite replacement probe were created in the known-good app;
- the signed CORE candidate displayed the migrated unified dictionary without observed duplication; `Underbite` retained aliases `under bite, underbyte`, and `Stu` with alias `stew` was added;
- the candidate showed the expected Accessibility warning caused by its changed ad-hoc signature; permission was deliberately not granted.

Ask Grok to try to falsify these claims from the pushed revision and CI evidence. Have it report only concrete findings with file/line references, commands, outputs, and risk classification. It must not modify live VoiceInk data, fabricate dictation evidence, or treat compilation as runtime acceptance.

The remaining acceptance gates are human-only: microphone selection, hotkey recording, cursor insertion/paste/no-auto-submit, spoken correction quality, enable/edit/delete persistence, deterministic cleanup failure/timeout/rejection fallback, and semantic preservation of profanity, uncertainty, negation, dates, filenames, and numbers. FluidAudio boosting must remain deferred until every CORE gate passes and David explicitly opts in.

Have ChatGPT maintain a short supervision ledger with four sections: **claim**, **Grok evidence**, **independent challenge**, and **gate status**. End with exactly one provisional recommendation: `READY TO MERGE`, `READY WITH SMALL FIXES`, or `DO NOT MERGE`. Until human CORE QA passes, the recommendation cannot be `READY TO MERGE`.
