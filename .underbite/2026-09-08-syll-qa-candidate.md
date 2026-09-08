# Syll Personal Dictionary QA candidate — local evidence

Date: 2026-09-08
Status: **Apple Development installation attempted, launch failed, and working Syll restored**

## Reconciled source identity

- Branch: `feature/syll-dictation-quality-control`.
- Base commit before reconciliation: `47f0b645cf977f1003388d2a26452b724cca2f54`.
- Exact reconciled implementation candidate: `c6f7ca47856d1fceb811b7f7c4bda1f7e9401289` (`Prepare signed Syll personal dictionary QA candidate`).
- The generated `app/` submodule was reset to pinned upstream `3c211dab63454f18cf3f8b58750ec6bf3f5b4d17` and regenerated only through `./scripts/prepare-app.sh --core-only --reset`.
- The complete candidate source is the superproject overlays, `patches/core.patch`, verifier, tests, and Apple Development QA packager committed with this evidence record. The dirty `app/` submodule is the expected generated output, not the source of truth.

## Narrow provider correction

Supervisor review found that the prior candidate supplied only preferred `VocabularyWord` values to AssemblyAI. It did not supply heard-as aliases to recognition context.

The candidate now has one bounded, stable, case-insensitive-deduplicated provider list:

`PersonalDictionaryService.entries -> recognitionTerms (preferred + aliases) -> PersonalDictionaryService.recognitionTerms(limit: 100)`.

Both `CloudTranscriptionService` (batch) and `AssemblyAIStreamingProvider` (next streaming connection) use that list. The pinned LLMkit source puts the list into AssemblyAI `keyterms_prompt` in batch JSON and the streaming WebSocket query. `VocabularyWord` remains for legacy import/backup compatibility. Deterministic one-pass correction still turns `Super Base` into `Supabase` after transcription.

AssemblyAI is the current recognizer. Core-only preparation remains selected; FluidAudio boosting is absent and disabled.

## Build and test evidence

- `python3 scripts/verify_overlay.py --core-only`: passed.
- `./scripts/prepare-app.sh --core-only --reset`: passed; `git -C app diff --check` passed.
- `xcodebuild -quiet build -skipPackagePluginValidation -skipMacroValidation ... CODE_SIGNING_ALLOWED=NO`: passed. The explicit Xcode flags were needed for the already-pinned `mlx-swift` CudaBuild plugin and `mlx-swift-lm` macro validation gates; no source dependency was changed.
- Existing result bundle `build/personal-dictionary-tests.xcresult`: 10 focused dictionary/corrector tests passed for the preceding candidate.
- New current-source XCTest attempt `build/personal-dictionary-current-tests.xcresult`: valid result bundle but zero tests executed (`result: unknown`), despite the focused test target selection. This is not recorded as passing. The new `recognitionTerms` preferred+alias/dedup/bound tests compile into the candidate source but require a functioning app-hosted XCTest runner for execution evidence.

## QA artifact v1

- Path: `build/syll-qa/v1-ready/Syll.app`.
- Display name/name/executable: `Syll` / `Syll` / `Syll`.
- Bundle identifier retained intentionally for settings/history continuity: `com.prakashjoshipax.VoiceInk`.
- Version/build: `0.1` / `216`.
- Icon: current `/Applications/Syll.app` Syll icon copied read-only into the artifact.
- Signing authority: `Apple Development: realjewlion@gmail.com (687D42QJZ6)`.
- TeamIdentifier: `A635S52367`.
- Designated requirement: `identifier "com.prakashjoshipax.VoiceInk" and anchor apple generic and certificate leaf[subject.CN] = "Apple Development: realjewlion@gmail.com (687D42QJZ6)" and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */`.
- Entitlements: app sandbox false; Apple Events automation, microphone, selected-file read-only, network client/server, and screen capture true.
- Provisioning/application identifier: no `embedded.provisionprofile` and no application-identifier entitlement present.
- `codesign --verify --deep --strict --verbose=2` passed after every Mach-O file, framework, XPC service, helper, and the main app were signed with Team `A635S52367`.

## Same-identity update comparison

- v2 artifact: `build/syll-qa/v2-ready/Syll.app`, version `0.1`, build `217`.
- v1 and v2 have the same `com.prakashjoshipax.VoiceInk` bundle identifier, `A635S52367` TeamIdentifier, Apple Development authority class, designated requirement, and entitlements. Only the build number differs (`216` -> `217`).
- This proves the packager can produce compatible same-Mac development identities. It does not yet prove Accessibility continuity: that requires v1 to receive normal consent, then an in-place v1 -> v2 replacement and a live trust/dictation check.

## Installation attempt and rollback — 2026-09-08

David explicitly approved the recoverable replacement. The following occurred:

- The historical working app was first copied, without modification, to `/Users/david/Documents/VoiceInk Backups/20260908-syll-apple-development-qa/Syll-before-apple-development-215.app` and its signature verified.
- QA v1 was staged and atomically placed at `/Applications/Syll.app`; its installed deep/strict signature verification passed.
- Its installed identity was exactly the intended QA identity: bundle `com.prakashjoshipax.VoiceInk`, version/build `0.1` / `216`, Team `A635S52367`, and the v1 designated requirement recorded above.
- It crashed repeatedly at startup before any Accessibility interaction or dictation check. The reports are `/Users/david/Library/Logs/DiagnosticReports/Syll-2026-09-08-122117.ips`, `Syll-2026-09-08-122304.ips`, and `Syll-2026-09-08-122332.ips`. Observed crashing startup frames include `LanguageDictionary.forCodes`, `SonioxProvider.models`, and Sparkle `SPUUpdaterSettings`; this is not yet a root-cause finding and must not be attributed to TCC or Accessibility.
- The failed QA v1 is preserved in place, outside LaunchServices' normal app path, at `/Applications/.Syll-crashing-apple-development-216.app` for forensics. It must not be launched again during ordinary use.
- The immediately preserved historical app was atomically restored to `/Applications/Syll.app`, passed `codesign --verify --deep --strict`, and was relaunched successfully as `/Applications/Syll.app/Contents/MacOS/VoiceInk` (PID observed after restore).

No TCC or Accessibility reset was performed. No permanent user data deletion occurred.

## Protected working state and rollback

- `/Applications/Syll.app` is again the restored, working historical app. It is not the Apple Development candidate.
- Current working identity: bundle `com.prakashjoshipax.VoiceInk`, display name `Syll`, historical `VoiceInk Local Dev` authority, no TeamIdentifier, leaf-bound designated requirement.
- Existing backup evidence remains at `/Users/david/Documents/VoiceInk Backups/20260908-095323`.
- The QA artifact is deliberately non-installed. Installation must be a single atomic replacement of `/Applications/Syll.app` only after David approves the exact operation, with the current app recoverably preserved. A one-time Accessibility grant may be required because the current installed signature and the QA signature have different designated requirements. No TCC reset is permitted.

## Next action

Do not retry installation, request Accessibility consent, or attempt the v1 -> v2 continuity pilot. First reproduce and repair the QA artifact's startup crash in the isolated build/candidate path, verify it launches stably, then repeat the same-Mac pilot from a fresh recoverable backup. The Personal Dictionary Feature remains unaccepted.
