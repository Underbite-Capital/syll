# Syll ordinary recorder HUD: state-feedback-only recovery slice

Date: 2026-09-09
Status: source implementation and focused policy regression PASS; no candidate prepared, built, signed, launched, installed, or accepted.

## Accepted behavior and boundary

For the ordinary Phase 1 Syll recorder route, the compact bottom HUD provides recording-state feedback only. It must never render live, partial, dictated, or final transcription text. This is a product invariant, not a `ShowLiveTranscript` default: an existing persisted `true` value cannot re-enable text.

The compact control bar remains unchanged at 136 pt by 40 pt. `SyllMenuBarView` and its `Copy Last Transcription` source route are outside this slice and unchanged. Assistant or diagnostic-capable behavior is retained only as an explicit nonordinary policy route; the ordinary `MiniRecorderView` selects `ordinaryPhase1`.

## Source change

- `overlays/core/VoiceInk/Views/Recorder/MiniRecorderView.swift` now routes both the live-transcript branch and assistant follow-up text through `SyllRecorderHUDPresentationPolicy.ordinaryPhase1`. It does not read `ShowLiveTranscript`.
- `overlays/core/VoiceInk/Views/Recorder/SyllRecorderHUDPresentationPolicy.swift` defines the ordinary state-only route and a separately explicit transcript-capable route for nonordinary reuse.
- `scripts/SyllRecorderHUDPresentationPolicyTests.swift` tests the real policy implementation; CI runs it from `.github/workflows/validate-project.yml`.

No generated `app/` source, Fn handling, icon resources, signing, bundle identity, entitlements, ASR/provider, modes, insertion, Personal Dictionary, cleanup, menu copy/service, login shell, setup, TCC, or Keychain code changed in this slice.

## Evidence

- `python3 scripts/verify_overlay.py --core-only`: PASS on 2026-09-09.
- `swiftc overlays/core/VoiceInk/Views/Recorder/SyllRecorderHUDPresentationPolicy.swift scripts/SyllRecorderHUDPresentationPolicyTests.swift -o /private/tmp/syll-recorder-hud-policy-tests && /private/tmp/syll-recorder-hud-policy-tests`: PASS on 2026-09-09.
- The focused regression persists `ShowLiveTranscript=true`, then asserts that `ordinaryPhase1` returns `false` and an empty content value while recording has partial dictated text. It also verifies that text rendering remains available only after explicit selection of the nonordinary `transcriptCapable` route.
- `git diff --check`: PASS after this slice.

## Limits and frozen state

The dirty generated `app/` subtree and other pre-existing recovery changes were preserved. `prepare-app` was not run because regenerating it would mutate that dirty subtree; therefore this overlay has not been composition-compiled into `app/`. No full app compile was attempted for the same reason. `/Applications/Syll.app` remains untouched, and installed build 228 remains untouched and unaccepted.

Human visual QA, physical Fn, local transcription, cursor insertion, structural menu-only launch, and restoration of the approved status mark remain outstanding. Installation remains frozen pending the independently verified recovery candidate and David's approval.
