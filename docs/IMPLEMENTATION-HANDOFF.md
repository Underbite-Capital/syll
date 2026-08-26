# VoiceInk personal dictionary — implementation handoff

**Branch:** `codex/voiceink-personal-dictionary`  
**VoiceInk base:** `Beingpax/VoiceInk@3c211dab63454f18cf3f8b58750ec6bf3f5b4d17`  
**Status:** implementation candidate; source-reviewed and statically checked, but exact submodule patch application, Xcode compilation, and human acceptance remain pending.

## What this branch is

This repository remains a thin, reproducible downstream layer over VoiceInk rather than a second copy of the entire upstream repository. The `app/` submodule supplies VoiceInk; `overlays/` contains complete replacement/new files; `patches/` contains the small edits that are safer to carry as hunks.

Run:

```bash
./scripts/prepare-app.sh --reset
```

For the safest recovery path, skip native recognition boosting:

```bash
./scripts/prepare-app.sh --core-only --reset
```

The script pins the exact upstream commit, refuses to overwrite a dirty submodule unless `--reset` is explicit, copies the overlays, checks every patch before applying it, and runs `git diff --check`. It does not sign, install, launch, or grant macOS permissions.

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

`CleanupOutputValidator` rejects a cleanup result when it is empty, wrapped in a code fence, begins like an assistant answer, changes length implausibly, drops/changes a numeric token, or loses an exact preferred dictionary spelling already present in the corrected source. Rejection throws through VoiceInk's existing enhancement-error path, leaving the deterministic corrected transcript as the delivery fallback.

This is deliberately not a second model or judge agent.

## Native boosting implementation

The full overlay upgrades the pinned FluidAudio revision and adds `FluidAudioVocabularyBooster`. Recognition boosting is **off by default** and fail-open.

When enabled, supported local FluidAudio batch paths expose token timings, load/cache a CTC vocabulary session from the current dictionary, and rescore the result. Any preparation, model, tokenization, or rescoring error returns the original transcript. Nemotron and streaming paths remain unchanged in this iteration.

The first enabled use may download an additional local CTC model. The core-only path avoids both the dependency revision and this runtime behaviour.

## Verification performed without David's Mac

- Exact upstream source paths and APIs were inspected at the pinned revisions.
- Static overlay verification runs in `scripts/verify_overlay.py`.
- The included GitHub Actions workflow is configured to initialize the public submodule and check both core-only and full overlay application with `git apply --check` and `git diff --check`. No workflow run was observed during this implementation session, so do not count this as passed evidence yet.
- The pure corrector has focused XCTest coverage for case-insensitive aliases, longest-match behaviour, boundaries, punctuation, multiple occurrences, and non-cascading replacement.
- The cleanup validator has focused tests for unchanged numbers with punctuation edits, changed numbers, protected spellings, assistant preambles, and non-cleanup prompts.

## Not yet verified

Do not turn these into confident claims:

1. Xcode compilation and SwiftData runtime migration on David's macOS/Xcode version.
2. The additional FluidAudio CTC model download and memory/latency on David's machine.
3. Real speech improvement for David's accent, microphone, and terminology.
4. Cleanup behaviour with David's chosen provider/model.
5. Existing VoiceInk import/export and iCloud dictionary sync after editing through the unified surface.
6. Streaming transcription vocabulary boosting; it is explicitly out of scope here.

## Cleanup crew order of operations

1. Run `python3 scripts/verify_overlay.py`.
2. Run `./scripts/prepare-app.sh --core-only --reset`.
3. Build the `VoiceInk` scheme in Xcode before touching boosting.
4. Fix compile errors only in `overlays/core` or `patches/core.patch`; do not edit generated `app/` as the source of truth.
5. Run the dictionary and cleanup-validator XCTest files.
6. Manually verify add/edit/disable/delete and legacy migration.
7. Verify cleanup failure still inserts the deterministic transcript.
8. Only then prepare the full overlay and test boosting off, then on.
9. Record exact failures and changed files in this document or the PR; never describe an unrun test as passing.

## Likely failure points

- Upstream moves a patched hunk: rebase by updating the pinned commit and regenerating the minimal patch, not by loosening `git apply` checks.
- FluidAudio changes its vocabulary API: use `--core-only` and keep the app usable while repairing the adapter.
- A SwiftUI API differs on the deployment target: prefer ordinary controls over redesigning the dictionary screen.
- Legacy duplicate data surfaces: preserve user data first; deduplicate only after inspecting the actual store.

## Rollback

Nothing touches the wrapper's `main` branch or David's installed app. Inside this working tree:

```bash
git -C app reset --hard
git -C app clean -fd
git submodule update --init --force app
```

Or delete the clone and start again. The old spike artifacts remain in the repository for comparison.
