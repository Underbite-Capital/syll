# Repaired Personal Dictionary Apple Development QA candidate

Date: 8 September 2026

Status: implementation evidence only; Feature not accepted; real-app migration not authorized.

## Protected state and starting point

- Branch: `feature/syll-dictation-quality-control`.
- Starting HEAD: `45b0eb097006df3cf00bacf797cab06efd503f69` (`Diagnose Apple Development candidate startup crash`).
- Starting worktree: outer repository clean except generated `app/` submodule dirtiness (` m app`).
- Protected working app: `/Applications/Syll.app`, historical build 215. It was not modified, replaced, re-signed, deleted, or used as the candidate's runtime data location.
- Protected forensic app: `/Applications/.Syll-crashing-apple-development-216.app`. It was not modified or deleted.
- TCC and Accessibility were not reset or changed.

## Root-cause repair and exact source

The accepted cause was retained: build 216 omitted `LOCAL_BUILD`, enabling the private CloudKit dictionary store without its required CloudKit entitlement/provisioning authority and crashing on the Core Data CloudKit queue.

The canonical Apple Development QA packager, `scripts/build-apple-development-pilot.sh`, now builds its own source application and always supplies:

```text
SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) DEBUG LOCAL_BUILD
CODE_SIGNING_ALLOWED=NO
```

The QA package is then recursively signed with the pinned Apple Development identity. `scripts/verify_overlay.py` now rejects the QA path if those build conditions or runtime signing are absent. This is scoped to the local Apple Development QA path; no CloudKit entitlement was added and CloudKit was not disabled for a future properly provisioned release.

- Exact candidate source commit: `6d703465a657d185ac65f857b2650dd83965e806` (`Make Apple Development QA builds local-safe`).
- Source-of-truth changes are committed. Remaining `app/` dirtiness is generated overlay state only.

## Preparation and automated evidence

Passed:

```text
python3 scripts/verify_overlay.py --core-only
./scripts/prepare-app.sh --core-only --reset
git -C app diff --check
```

The current-source focused XCTest command was:

```text
xcodebuild -quiet test \
  -project app/VoiceInk.xcodeproj \
  -scheme VoiceInk \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build/personal-dictionary-current-derived-data \
  -resultBundlePath build/personal-dictionary-current-fixed.xcresult \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_TESTABILITY=YES \
  'SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) DEBUG LOCAL_BUILD' \
  -only-testing:VoiceInkTests/PersonalDictionaryServiceTests \
  -only-testing:VoiceInkTests/PersonalDictionaryCorrectorTests
```

`xcrun xcresulttool get test-results summary` reports 12 executed, 12 passed, 0 failed, 0 skipped. The result bundle is `build/personal-dictionary-current-fixed.xcresult`. Covered behavior includes preferred-only persistence/cache refresh; preferred plus alias; edit; delete; duplicate/conflict handling; preferred and alias recognition terms with stable deduplication and bounding; `Super Base` to `Supabase`; boundary handling; all occurrences; punctuation; longest alias; and non-cascading correction.

## Reproducible QA build

Command:

```text
./scripts/build-apple-development-pilot.sh 218 /Users/david/work/projects/syll/build/syll-qa/repaired-218
```

The build output showed `-DLOCAL_BUILD` in the Swift compiler invocation in addition to the canonical command-line setting above.

- App: `/Users/david/work/projects/syll/build/syll-qa/repaired-218/Syll.app`
- Executable: `/Users/david/work/projects/syll/build/syll-qa/repaired-218/Syll.app/Contents/MacOS/Syll`
- Version/build: `0.1` / `218`
- Bundle ID: `com.prakashjoshipax.VoiceInk`
- Bundle/display/executable names: `Syll` / `Syll` / `Syll`
- TeamIdentifier: `A635S52367`
- Intended certificate common name: `Apple Development: realjewlion@gmail.com (687D42QJZ6)`
- Designated requirement: `identifier "com.prakashjoshipax.VoiceInk" and anchor apple generic and certificate leaf[subject.CN] = "Apple Development: realjewlion@gmail.com (687D42QJZ6)" and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */`
- Hardened runtime: present (`flags=0x10000(runtime)`).
- Entitlements: app sandbox false; Apple Events automation true; microphone true; user-selected read-only files true; network client/server true; screen capture true.
- Embedded provisioning profile: absent.

The package script's immediate deep/strict verification completed during the build. A later fresh verification did **not** pass: `codesign --verify --deep --strict` returned `CSSMERR_TP_NOT_TRUSTED` for the root and nested code, and `security find-identity -v -p codesigning` then reported `0 valid identities found`. The artifact retains the intended Team ID and designated requirement, but this current trust/identity failure is a release blocker and must not be described as a presently valid verified signature.

## Isolated runtime result

Because the candidate retains the production bundle ID and the application hard-codes the existing Application Support container name, it was launched with `CFFIXED_USER_HOME=/private/tmp/syll-qa-218-home`. A Swift Foundation check established that its Application Support directory consequently resolves beneath that isolated home. All observed candidate-created default, dictionary, statistics, and HTTP-storage files remained under `/private/tmp/syll-qa-218-home`; production data was not mutated.

Launch overrides were process-local and nonpersistent: `-hasCompletedOnboardingV2 YES -IsMenuBarOnly YES`. The candidate remained alive for more than 30 seconds and produced no new `Syll*.ips` report. The prior Core Data CloudKit crash did not recur. It displayed no standalone onboarding/product window and exposed a menu-bar item.

Runtime verification then hit an explicit stop condition: the candidate's own menu contained `Quit VoiceInk`. The source remains hard-coded at `app/VoiceInk/Views/MenuBarView.swift` (two menu variants), and the main window title remains `VoiceInk` in `app/VoiceInk/VoiceInk.swift`. Screenshot: `build/syll-qa/repaired-218-menu.png`. The isolated process was terminated; the historical working process remained the only real `/Applications/Syll.app` process.

Accordingly, visible Personal Dictionary UI verification is **FAIL/blocked**, not PASS. Source inspection confirms the new dictionary surface exists (`Preferred word`, `Heard as (optional)`, `Add`, searchable entries, edit and delete controls, and no primary refresh/path/revision/bias inspector), but it was not opened or mutated after the material Syll/VoiceInk identity mismatch triggered the mandated stop.

## AssemblyAI vocabulary path

The current real defaults select `AssemblyAI`. Source inspection confirms:

1. `PersonalDictionaryService.recognitionTerms` returns preferred spellings plus aliases, case-insensitively deduplicated and bounded.
2. Batch `CloudTranscriptionService` and `AssemblyAIProvider` pass those terms as `customVocabulary` to pinned LLMkit.
3. LLMkit's `AssemblyAIClient` normalizes them and places them in the transcript request JSON as `keyterms_prompt`.
4. `AssemblyAIStreamingProvider` reads the same recognition terms; LLMkit's `AssemblyAIStreamingClient` serializes them into the streaming URL's `keyterms_prompt`.
5. Dictionary mutation refreshes the cached recognition state, while each pipeline run also refreshes the cache before transcription.
6. Deterministic alias/spelling correction runs through the existing replacement stage after raw transcription. No replacement-table imitation of recognition boosting was introduced.
7. The experimental FluidAudio vocabulary booster file is absent and was not enabled. This slice introduced no LLM cleanup; pre-existing optional AI enhancement remains a separately configured upstream facility and was not used as evidence for dictionary correctness.

This proves plumbing, not an experiential recognition-quality improvement.

## Remaining state and blocker

- Working tree after cleanup: generated ` m app` only.
- Candidate startup: PASS.
- Personal Dictionary visible UI: FAIL/blocked by the material `Quit VoiceInk` identity defect before the popup was exercised.
- AssemblyAI context path: PASS by current source/dependency inspection.
- Signing: presently blocked because the keychain reports no valid signing identities and fresh deep/strict verification returns `CSSMERR_TP_NOT_TRUSTED`.
- Human dictation and vocabulary QA remain outstanding. The Feature is not accepted.

## Proposed migration and rollback (not authorized here)

Do not replace `/Applications/Syll.app` yet. The next bounded task is to change the remaining user-visible VoiceInk identity strings to Syll, rebuild through the same canonical `LOCAL_BUILD` QA path once the Apple Development identity is valid again, obtain fresh deep/strict verification, and repeat isolated visible dictionary CRUD verification.

Only after those checks pass should a supervisor consider a recoverable migration: quit the candidate and working app; preserve an exact backup of build 215 and its data; stage and verify the signed candidate outside `/Applications`; replace the app bundle in place without changing bundle ID, Team ID, designated-requirement shape, entitlements, or TCC; launch and verify effective Accessibility and real dictation. If any check fails, quit the candidate and atomically restore the preserved build-215 bundle. Do not reset TCC during migration or rollback.

## Visible Syll identity follow-up

Source commit `ac24a9554fa4a58c014a96e885e2b0d83bf0ddb3` (`Complete visible Syll identity in QA source`) adds a reproducible `patches/syll-branding.patch`, applies it from `scripts/prepare-app.sh`, and makes `scripts/verify_overlay.py` enforce the critical Syll labels. The core onboarding patch was also corrected so its Accessibility and microphone instructions say Syll.

The bounded branding repair changes both status-menu variants to `Quit Syll`; the SwiftUI app and AppKit window titles to Syll; recorder App Intent labels; ordinary microphone, clipboard, and language-restart copy; and the dictionary example. It does not change compatibility-sensitive bundle identifiers, Application Support paths, defaults/autosave keys, Swift target/module names, or upstream provider/service identifiers. Those internal `VoiceInk` identifiers remain necessary to preserve bundle, data, and Accessibility continuity and are not the normal Personal Dictionary/recording branding path.

Fresh current-source evidence:

- `python3 scripts/verify_overlay.py --core-only`: PASS.
- `./scripts/prepare-app.sh --core-only --reset`: PASS at upstream `3c211dab63454f18cf3f8b58750ec6bf3f5b4d17`.
- `git -C app diff --check`: PASS.
- Focused result bundle: `build/personal-dictionary-branding-v2.xcresult`.
- Focused tests: 12 executed, 12 passed, 0 failed, 0 skipped.

An explicitly non-installable diagnostic was built at `/Users/david/work/projects/syll/build/syll-branding-diagnostic-219/Syll.app`, build 219. It retained the compatibility bundle identifier, used `LOCAL_BUILD`, and was run with `CFFIXED_USER_HOME=/private/tmp/syll-branding-219-home`. It launched without a standalone window. Read-only Accessibility inspection established:

- macOS application menu: `About Syll`, `Hide Syll`, `Quit Syll`;
- status menu: `Quit Syll`.

Launching that diagnostic simultaneously with the historical working app produced a confusing second visible app identity because both processes shared the compatibility bundle identifier and macOS reused/cached VoiceInk/Syll identity presentation. David required execution to stop. The diagnostic process was terminated immediately; the generated `default.profraw` was removed; `/Applications/Syll.app` remained the only working real app and was never modified. This simultaneous-launch approach must not be repeated on David's active desktop.

Personal Dictionary visible UI remains **FAIL/not completed**: source and 12/12 tests contain the intended controls, but the popup was not opened before David stopped the duplicate-app verification. Do not promote source inspection to visual PASS.

The signing diagnosis remains read-only and blocking:

- `security find-identity -v -p codesigning`: `0 valid identities found`;
- no certificate matching `Apple Development: realjewlion@gmail.com (687D42QJZ6)` is present in the login keychain;
- therefore no matching certificate/private-key pair can form a valid signing identity;
- no provisioning profiles are installed;
- Xcode has no valid development signing identity to resolve.

Exact human-controlled prerequisite: in Xcode Settings → Accounts, select the relevant Apple account and use Manage Certificates to create or download a valid Apple Development certificate so that its matching private key is installed in the login keychain. Once that single prerequisite is satisfied, the canonical `LOCAL_BUILD` Apple Development packaging path is ready to produce a new isolated signed candidate. Installation remains unauthorized, and the Feature remains unaccepted.

Final worktree state before this evidence update: generated ` m app` only. Protected `/Applications/Syll.app` remained build 215 and untouched; TCC and Accessibility were not changed.
