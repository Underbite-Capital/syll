# VoiceInk personal dictionary — implementation handoff

**Branch:** `codex/voiceink-personal-dictionary`  
**VoiceInk base:** `Beingpax/VoiceInk@3c211dab63454f18cf3f8b58750ec6bf3f5b4d17`  
**Status:** implementation candidate; automated evidence must pass on the current revision and human acceptance remains mandatory.

## What this branch is

This repository remains a thin, reproducible downstream layer over VoiceInk rather than a second copy of the entire upstream repository. The `app/` submodule supplies VoiceInk; `overlays/` contains complete replacement/new files; `patches/` contains the small edits that are safer to carry as hunks.

Start CORE-ONLY:

```bash
python3 scripts/verify_overlay.py
./scripts/prepare-app.sh --core-only --reset
./scripts/build-local-app.sh --core-only
```

Preparation validates the selected mode's patch syntax before touching `app/`, validates every selected patch against the pinned upstream before copying overlays, and restores a clean pinned submodule on later failure. CORE-ONLY does not depend on boosting files parsing or applying. The build script defines `LOCAL_BUILD`, uses VoiceInk's reduced local entitlements, signs ad hoc, and verifies the resulting bundle. Neither script installs, opens, launches, or grants permissions.

The CORE-ONLY UI intentionally contains no boosting control. The full overlay adds that control and leaves it off by default.

## Core implementation

### One dictionary surface

The app continues to store entries in VoiceInk's existing `WordReplacement` and `VocabularyWord` SwiftData models to avoid a schema migration. The new UI presents them as one concept:

- preferred spelling;
- zero or more spoken aliases;
- enabled/disabled.

`PersonalDictionaryService.migrateLegacyVocabulary` is intentionally idempotent. It creates a no-op replacement row for vocabulary-only terms and keeps preferred spellings in `VocabularyWord` for old backup/import compatibility. It does not delete the legacy data on migration.

### Deterministic correction

`PersonalDictionaryCorrector` finds every candidate against the original transcript, resolves overlaps longest-first at the same location, then applies selected replacements from the end of the string. A correction therefore cannot create text that triggers a second correction in the same pass.

### Cleanup safety

Cleanup still uses VoiceInk's existing enhancement provider and delivery pipeline. The branch changes the default enhancement timeout from seven seconds to five seconds and gives prompts with `cleanup` or `clean dictation` in the title one attempt.

`CleanupOutputValidator` rejects a cleanup result when it is empty, wrapped in a code fence, begins like an assistant answer, changes length implausibly, changes the exact frequency of any numeric token, or loses an exact preferred dictionary spelling already present in the corrected source. Number formatting is deliberately conservative: changing `1,000` to `1000` is rejected and falls back. Rejection throws through VoiceInk's existing enhancement-error path, leaving the deterministic corrected transcript as the delivery fallback.

This is deliberately not a second model or judge agent.

## Native boosting implementation

The full overlay upgrades the pinned FluidAudio revision and adds `FluidAudioVocabularyBooster`. Recognition boosting is **off by default** and fail-open.

When enabled, supported local FluidAudio batch paths expose token timings, load/cache a CTC vocabulary session from the current dictionary, and rescore the result. Any preparation, model, tokenization, or rescoring error returns the original transcript. Nemotron and streaming paths remain unchanged in this iteration.

The first enabled use may download an additional local CTC model. The core-only path avoids both the dependency revision and this runtime behaviour.

## Automated verification contract

- Static verification parses both patch files with Git, checks the core/full UI split, and validates the project metadata.
- Preparation checks both core-only and full overlay application with `git apply --check` and `git diff --check`.
- The local build is only acceptable when `codesign --verify --deep --strict` passes and its entitlements contain no CloudKit, push, or keychain access groups.
- The pure corrector has focused XCTest coverage for case-insensitive aliases, longest-match behaviour, boundaries, punctuation, multiple occurrences, and non-cascading replacement.
- The cleanup validator has focused tests for unchanged repeated numbers, changed numbers, removed repetitions, invented/duplicated numbers, protected spellings, assistant preambles, and non-cleanup prompts.
- Do not mark XCTest passed if the app-hosted runner fails before bootstrap. Do not launch that runner against live data before the protected backup gate.

## Not yet verified

Do not turn these into confident claims:

1. The additional FluidAudio CTC model download and memory/latency on David's machine.
2. Real speech improvement for David's accent, microphone, and terminology.
3. Cleanup behaviour with David's chosen provider/model.
4. Existing VoiceInk import/export and iCloud dictionary sync after editing through the unified surface.
5. Streaming transcription vocabulary boosting; it is explicitly out of scope here.

## Local evidence — 2026-08-27

- Project validation and both core/full static overlay validation passed.
- A deliberately malformed patch was rejected by the Git parser while `app/` remained unchanged.
- CORE-ONLY and full preparation both applied cleanly; the workspace was returned to CORE-ONLY afterward.
- Two clean CORE-ONLY preparations produced the same 12-file SHA-256 manifest: `a81fe2eaaa1510c205e260ea0ce71c7adf2932d65b4a8789f1431ff677e069f5`.
- CORE-ONLY compiled with Xcode 26.6 on macOS 26.5.2 using `LOCAL_BUILD`; inside-out ad-hoc signing and reduced-entitlement verification passed.
- All 15 focused tests executed and passed: 6 personal-dictionary corrector tests and 9 cleanup-validator tests. Result bundle: `build/voiceink-core/DerivedData/Logs/Test/Test-VoiceInk-2026.08.27_09-47-55-+0200.xcresult`.
- A verified backup was created at `/Users/david/Documents/VoiceInk Backups/20260827-093630`; all copied SQLite stores passed `PRAGMA integrity_check` and every payload hash verifies.
- The known-good app was used to create 57 conservative vocabulary terms and one replacement rule (`under bite, underbyte` → `Underbite`). The signed CORE candidate migrated them into the unified surface without observed duplication, retained the aliases on one Underbite row, and accepted a separate `Stu`/`stew` boundary-test entry.
- The signed CORE candidate launched and displayed the existing history and settings. Its changed ad-hoc signature caused the expected Accessibility warning; permission was not granted.
- Microphone, hotkey, insertion, deterministic dictation, cleanup fallback, and semantic QA remain unrun human gates.

## Cleanup crew order of operations

1. Run the validator, CORE-ONLY preparation, and local build commands above.
2. Confirm the prepared diff contains no boosting adapter and retains FluidAudio `c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7`.
3. Fix source only in the wrapper overlay or patch; never treat generated `app/` edits as source of truth.
4. Quit VoiceInk and run `backup-voiceink.sh` with a new absolute destination outside Git. The script refuses to overwrite a destination and verifies copied SQLite stores.
5. Run focused XCTest only after the backup exists; a runner/bootstrap failure blocks launch testing.
6. Create one vocabulary-only and one replacement-only probe in the known-good app, quit it, then launch the candidate and inspect migration.
7. Perform the CORE checks in `MANUAL-QA.md`.
8. Only after David accepts CORE may the full overlay be prepared and boosting tested off, then on.
9. Never describe an unrun automated or human check as passing.

## Likely failure points

- Upstream moves a patched hunk: rebase by updating the pinned commit and regenerating the minimal patch, not by loosening `git apply` checks.
- FluidAudio changes its vocabulary API: use `--core-only` and keep the app usable while repairing the adapter.
- A SwiftUI API differs on the deployment target: prefer ordinary controls over redesigning the dictionary screen.
- Legacy duplicate data surfaces: preserve user data first; deduplicate only after inspecting the actual store.

## Backup and rollback

With VoiceInk quit, create a new backup directory explicitly:

```bash
./scripts/backup-voiceink.sh \
  --destination "/Users/david/Documents/VoiceInk Backups/$(date +%Y%m%d-%H%M%S)"
```

The backup contains the complete application-support directory, exported preferences, the known-good app when present, verified SQLite stores, and SHA-256 hashes. Restoring it is destructive and remains a separate human-approved action.

To reset only the prepared submodule:

```bash
git -C app reset --hard
git -C app clean -fd
git submodule update --init --force app
```

Do not merge, install over the known-good app, restore data, or start boosting on agent authority.
