# Syll composition-preservation slice

Date: 2026-09-09
Status: isolated core composition PASS; unsigned compile PASS; installation remains frozen; no Feature acceptance.

## Outcome

The current root overlays, patches, and preparation script can reconstruct the intended core recovery composition from VoiceInk `3c211dab63454f18cf3f8b58750ec6bf3f5b4d17` without touching the dirty generated `app/` subtree.

The preparation defect was patch dependency ordering. `syll-recovery.patch` depends on branding changes, and `syll-shell-structural.patch` depends on recovery changes, but the script previously checked every patch independently against pristine upstream. `scripts/prepare-app.sh` now checks and applies core, branding, recovery, and structural patches in dependency order. Patch contents and behavior were not changed.

## Dirty-state reconciliation

### Root source of truth

- `patches/core.patch` plus `overlays/core/` represent Personal Dictionary CRUD/persistence, preferred spellings and aliases, deterministic non-cascading correction, deterministic cleanup, the compact recorder, menu copy, identity migration source, and their tests.
- `patches/syll-branding.patch` represents the existing Syll-facing source naming changes.
- `patches/syll-recovery.patch` represents a mixed recovery layer: accepted identity namespace/migration and login-item cleanup are coupled to unapproved incident-era Fn, icon, delayed-hide, and Setup-era behavior.
- `patches/syll-shell-structural.patch` is an unproven candidate layered after recovery. It replaces the ordinary `Window` scene with `Settings`, removes delayed hiding and the main-window request bridge, and makes reopen return `false`.
- `scripts/build-apple-development-pilot.sh` represents the post-build `capital.underbite.syll` bundle identifier and Syll product/display/executable restaging. The upstream Xcode project itself retains VoiceInk target identity.
- The 2026-09-09 HUD overlay and policy make ordinary Phase 1 state-only and do not read `ShowLiveTranscript`.

### Generated `app/` comparison

An isolated clean core composition was created under `/private/tmp` using a local clone and the repository preparation mechanism. A checksum comparison against the untouched dirty `app/` subtree found only two expected content differences:

1. current generated `MiniRecorderView.swift` is stale and lacks the accepted no-text policy integration;
2. current generated `app/` lacks `SyllRecorderHUDPresentationPolicy.swift`.

All other current generated content differences from upstream, including the structural AppDelegate/scene changes, are represented by existing root overlays or patches. No additional unexplained generated delta was found.

Regeneration would therefore preserve the represented current composition and add the accepted no-text HUD behavior. It would not preserve an unidentified generated-only fix because none was detected.

## Deliberately unaccepted state

Mechanical reproduction is not product approval. This slice did not endorse, repair, or newly decide:

- the four ascending-bar status mark or `menuBarIcon` choice;
- incident-era Fn handling;
- cloud/provider or user-facing mode behavior;
- inherited dashboard/onboarding/promotion behavior;
- the three-card `SyllControlView` Setup experience.

The mixed `syll-recovery.patch` remains the exact unresolved coupling: removing its unapproved pieces while retaining accepted identity, migration, and login cleanup would be a behavioral recovery slice, not a composition-only edit.

## Structural shell boundary

The isolated composition reproducibly contains the directionally required mechanics: no ordinary `Window` scene, no delayed hide, reopen cannot create a main window, no notification bridge can create the main window, and menu actions use explicit `openSettings()` invocation.

The `Settings` scene still hosts the unapproved `SyllControlView`, and menu destinations still route through the inherited dashboard/navigation model. No Setup UX was invented or redefined in this slice. That product-routing conflict remains unresolved.

## Verification

- Isolated `./scripts/prepare-app.sh --core-only --reset`: PASS.
- Isolated generated `git diff --check`: PASS.
- Root `python3 scripts/verify_overlay.py --core-only`: PASS.
- Root `git diff --check`: PASS.
- `SyllRecorderHUDPresentationPolicyTests`: PASS, including persisted `ShowLiveTranscript=true`.
- `DeterministicDictationCleanerTests`: PASS.
- Isolated source checks: policy, Mini integration, 136 x 40 geometry, Dictionary service/corrector, deterministic cleaner, `Copy Last Transcription`, and identity migration all present.
- Isolated unsigned `xcodebuild` with `LOCAL_BUILD` and `CODE_SIGNING_ALLOWED=NO`: PASS. This proves compilation only; it makes no runtime or UX claim.
- Personal Dictionary XCTest was not launched. The repository incident record establishes that the app-hosted test runner can launch an upstream-named host and trigger unwanted desktop/keychain interaction. The prior 12/12 focused result remains historical evidence, not a fresh run.

## Frozen state and remaining risks

`/Applications/Syll.app` build 228 was not modified, stopped, launched, replaced, or accepted. No candidate was signed or installed. No login item, TCC, Keychain, credential, or user-data state was read or mutated.

Ranked remaining recovery risks:

1. The mixed recovery patch couples accepted preservation work to unapproved Fn, icon, and Setup-era behavior.
2. The explicit Settings scene still contains unapproved `SyllControlView`/dashboard routing.
3. Permanent identity is applied in a post-build restaging script rather than the Xcode target, and that script still copies an icon from the installed app.
4. Fn, local Phase 1 ASR, insertion, visible shell, and icon remain unverified behaviorally.
