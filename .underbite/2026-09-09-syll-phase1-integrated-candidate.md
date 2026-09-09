# Syll Phase 1 integrated recovery candidate

Date: 2026-09-09

## Identity and provenance

- Repository: `/Users/david/work/projects/syll`
- Repository branch: `feature/syll-dictation-quality-control`
- Repository HEAD at composition: `543eca96a2a233e1dbd7ffc70a22d0524c1fedb1`
- Pinned upstream source: `3c211dab63454f18cf3f8b58750ec6bf3f5b4d17`
- Isolated candidate source: `/private/tmp/syll-phase1-candidate.Yu7qwd`
- Compiled product: `/private/tmp/syll-phase1-candidate.Yu7qwd/DerivedData/Build/Products/Debug/Syll.app`
- Candidate executable SHA-256 after signature removal: `f203861446d36c97f2d48c8dfc8e39a8bb876e4a02c9c704269cd31f21b9a93f`

The candidate was composed from the pinned upstream archive plus the current core, branding, recovery, structural and no-text HUD work. The checked-out `app/` submodule and `/Applications/Syll.app` were not changed.

## Frozen ordinary experience

- `Fn` hold starts recording and release finishes it.
- One short tap starts recording and waits 350 ms; a second tap in that interval locks hands-free recording. A tap while locked finishes it.
- The 136x40 HUD remains state-only; transcript text is suppressed by `SyllRecorderHUDPresentationPolicy.ordinaryPhase1`.
- The runtime resolves only `parakeet-tdt-0.6b-v3` from the local FluidAudio provider, forces offline/non-realtime transcription, enables deterministic formatting, disables AI enhancement, and fixes output to paste.
- If the exact local model is unavailable, recording fails with `Local Parakeet V3 model is unavailable`; no provider or cloud fallback is selected.
- Completed transcription data is saved and completion notification posted before cursor delivery, preserving Copy Last independently of paste success.
- The menu contains Toggle Recorder, Copy Last Transcription, Personal Dictionary and Quit Syll. Personal Dictionary is the only Settings scene. Dashboard, setup, history, advanced settings, launch-at-login and debug windows have no ordinary route.
- Project, scheme, target, product, executable, display name and bundle name are `Syll`; bundle identifier is `com.david.syll`. The internal Swift module and upstream source directory remain `VoiceInk` as compatibility/provenance identifiers. The dormant upstream `VoiceInkRefineXPC` target remains compiled but is not selected by the Phase 1 runtime.

## Historical icon

- Candidate source asset: `VoiceInk/Assets.xcassets/menuBarIcon.imageset/menuBarIcon.png`
- Git blob: `fd19ccfd49d87a7f00c791f1d19d2ac299dfac48`
- SHA-256: `de11e5550a84a03094f4cc60c6aff71045b67ccd020d142d6e379795c32ce0b0`
- Wired as a template menu-bar image.
- Historical recovery candidate only: **NOT HUMAN ACCEPTED** and runtime appearance **NOT TESTED**.

## Verification matrix

| Claim | Source | Composed | Compiled | Runtime | Human |
|---|---|---|---|---|---|
| Syll project/scheme/target/product/executable identity | YES | YES | YES | NOT TESTED | NOT TESTED |
| Menu-only ordinary shell; dictionary only window | YES | YES | YES | NOT TESTED | NOT TESTED |
| 136x40 state-only no-text HUD | YES | YES | YES | NOT TESTED | NOT TESTED |
| Fn hold/release and double-tap lock state machine | YES | YES | YES | NOT TESTED | NOT TESTED |
| Local-only Parakeet V3, no cloud fallback | YES | YES | YES | NOT TESTED | NOT TESTED |
| Cleanup/dictionary before cursor insertion | YES | YES | YES | NOT TESTED | NOT TESTED |
| Completed text persisted before paste delivery | YES | YES | YES | NOT TESTED | NOT TESTED |
| Historical menu icon asset wired | YES | YES | YES | NOT TESTED | **NO** |

## Evidence

- Focused HUD policy executable: PASS (`Syll recorder HUD presentation policy tests passed`).
- Asset blob equality: PASS (`fd19ccfd49d87a7f00c791f1d19d2ac299dfac48`).
- Unsigned build command: `xcodebuild -project Syll.xcodeproj -scheme Syll -configuration Debug -derivedDataPath ... -skipPackagePluginValidation -skipMacroValidation CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build`.
- Compile result: `** BUILD SUCCEEDED **`.
- Xcode produced an automatic linker ad-hoc signature despite disabled code signing; it was removed immediately. Final check: `code object is not signed at all`.
- Final built Info.plist: `CFBundleDisplayName=Syll`, `CFBundleExecutable=Syll`, `CFBundleIdentifier=com.david.syll`, `CFBundleName=Syll`.

## Integrity exception

Xcode automatically executed `RegisterWithLaunchServices` for the isolated DerivedData product during its successful build. The app was not copied to Applications and was not launched, but this is a user-state mutation and therefore prevents a claim that the run was mutation-free. No cleanup/unregistration was attempted because that would be another unapproved user-state mutation.

## Gate state

- **UNINSTALLED**
- **UNLAUNCHED**
- **UNSIGNED** after removal of Xcode's automatic linker signature
- **NOT HUMAN ACCEPTED**
- Runtime and visual evidence: **NOT TESTED**

No installation, launch, permission grant, login-item change, Keychain write, or `/Applications/Syll.app` mutation was performed.
