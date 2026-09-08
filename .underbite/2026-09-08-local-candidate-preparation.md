# Syll local candidate preparation — 2026-09-08

Status: prepared for David's experiential QA. This is not Feature acceptance.

## Before mutation

- Observed local branch and HEAD: `main` at `5144a49c23908bde1c81ea44562709a8515d4d44`.
- Observed worktree: clean (`git status --short` empty); the `app/` submodule was uninitialised at pinned commit `3c211dab63454f18cf3f8b58750ec6bf3f5b4d17`.
- Existing installed application: `/Applications/Syll.app`, bundle identifier `com.prakashjoshipax.VoiceInk`, version `2.11`, build `215`, ad-hoc/no Team ID.
- Existing preferences selected transcription provider: `AssemblyAI` (`onboardingTranscriptionProvider`). This provider does not justify the experimental FluidAudio boosting path.
- No Syll/VoiceInk process was initially observed in the ordinary process query. The backup script subsequently detected VoiceInk running; it was quit normally before backup.

## Candidate prepared

- Requested branch: `feature/syll-dictation-quality-control`.
- Exact prepared/build commit: `47f0b645cf977f1003388d2a26452b724cca2f54` (`Record Syll implementation candidate and QA boundary`).
- Overlay validation: `python3 scripts/verify_overlay.py --core-only` passed (26 seeded terms; upstream `3c211dab6345`).
- Preparation: `./scripts/prepare-app.sh --core-only --reset` passed at upstream `3c211dab63454f18cf3f8b58750ec6bf3f5b4d17`.
- Core-only confirmation: `Package.resolved` uses FluidAudio `c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7`; `FluidAudioVocabularyBooster.swift` is absent. Experimental boosting remains disabled.
- Pre-install backup: `/Users/david/Documents/VoiceInk Backups/20260908-095323`; application data and preferences copied, SQLite stores passed `PRAGMA integrity_check`, and the manifest was verified.

## Automated/build evidence

- Deterministic cleaner suite passed: `swiftc overlays/core/VoiceInk/Transcription/Processing/DeterministicDictationCleaner.swift scripts/DeterministicDictationCleanerTests.swift -o /tmp/syll-cleanup-tests && /tmp/syll-cleanup-tests`.
- Focused XCTest invocation for `PersonalDictionaryCorrectorTests` and `CleanupOutputValidatorTests` began dependency compilation, but the runner remained idle for more than five minutes without completing a valid `.xcresult`/bootstrap. It was stopped and is **not recorded as passed**.
- Core build: `./scripts/build-local-app.sh --core-only` completed.
- Signing: `codesign --verify --deep --strict --verbose=2` passed on the build bundle. Identity: ad-hoc (`com.prakashjoshipax.VoiceInk`, no Team ID). Reduced local entitlements contain audio input, screen capture, Apple Events, selected-file read-only, and network client/server; no CloudKit, push, or keychain access group entitlement was present.

## Installed QA application

- Installed and launched path: `/Applications/Syll.app`.
- Installed bundle identity: `com.prakashjoshipax.VoiceInk`, version `2.11`, build `211`; `codesign --verify --deep --strict` passed after installation.
- Previous bundle preserved at `/Applications/.Syll-before-215-AF6234AB-1A12-4EE2-9065-10B0D429D63A.app`.
- Active provider remains AssemblyAI unless David changes it in the app. The core overlay is the selected recognizer-safe path.

## Remaining local state

- Superproject branch is `feature/syll-dictation-quality-control` at the requested commit; it has no tracked-file edits other than this evidence record.
- `app/` is intentionally dirty with the generated core overlay: 17 modified tracked files and 6 untracked overlay/test files. This is the required prepared candidate state, not unrelated local work.
- Build and test DerivedData remain under ignored `build/` paths.

No acceptance decision has been made.

## 2026-09-08 Personal Dictionary popup candidate

David reported that the working Syll Vocabulary popup was a read-only inspector and asked for one small, useful Personal Dictionary. The installed `/Applications/Syll.app` was deliberately not rebuilt, replaced, launched, reset, re-signed, or otherwise changed for this work; its current Accessibility state remains outside this candidate.

### Candidate implementation

- The existing `VocabularyView` popup now delegates to the unified `WordReplacementView`, so there is one dictionary rather than a separate vocabulary inspector and replacement screen.
- The add surface is `Preferred word`, `Heard as (optional)`, and `Add`; entries stay searchable and are editable/deletable.
- A preferred-only entry creates a canonical `WordReplacement` plus its provider-facing `VocabularyWord`. An alias such as `Super Base` is stored with the same canonical entry and deterministically corrects to `Supabase` after transcription.
- The primary surface has no path, revision, inactive-bias diagnostic, or Refresh control. Existing records are migrated on appearance and normal mutations save immediately.

### Effective behaviour traced

- Persistence: SwiftData `WordReplacement` is canonical for preferred text + aliases; `VocabularyWord` is retained as the preferred-term projection used by transcription providers and existing backup/import compatibility.
- Correction: `TranscriptionPipeline` calls `WordReplacementService`, which calls `PersonalDictionaryCorrector` once against the original transcript before deterministic cleanup. The corrector applies selected replacements from the end, so corrections do not cascade.
- Current selected recognizer: prior local evidence records AssemblyAI. `CloudTranscriptionService` reads the current `VocabularyWord` records per batch request; `AssemblyAIProvider` forwards them to `LLMkit.AssemblyAIClient`, which emits them as AssemblyAI `keyterms_prompt`. `AssemblyAIStreamingProvider` reads the current words when a streaming session connects. This is actual provider context bias, not a replacement-table claim.
- Mutations save and refresh the recognition cache immediately. Batch requests read the projection fresh; the next streaming connection reads it fresh. No restart and no LLM are required.

### Automated evidence

- `python3 scripts/verify_overlay.py --core-only` passed.
- `./scripts/prepare-app.sh --core-only --reset` passed; `git -C app diff --check` passed.
- `./scripts/build-local-app.sh --core-only` passed, including ad-hoc build-bundle signature verification under the repository build directory only.
- Focused XCTest passed: 10 tests in `PersonalDictionaryCorrectorTests` and `PersonalDictionaryServiceTests`; result bundle `build/personal-dictionary-tests.xcresult`.
- The service tests cover preferred-only add/persistence/cache refresh, preferred+alias persistence, edit, delete/cache removal, duplicate preferred/alias conflict, and `Super Base` / `Supa Base` to `Supabase`. The existing corrector tests cover non-cascading correction and preferred spelling preservation.

### Safe installed-QA status

No installed QA candidate exists. The repository build is intentionally ad-hoc signed and upstream-branded; installing it would repeat the identity/Accessibility failure documented in `2026-09-08-macos-accessibility-identity-handoff.md`. A future installed QA candidate requires the stable Syll Developer-ID signing/update path specified in that handoff. Do not replace `/Applications/Syll.app` from this candidate.

### Exact next action

Review the repository candidate’s unified popup once it can be assembled from the current working Syll lineage with stable signing. Do not mark the Feature accepted; real dictation QA remains required.
