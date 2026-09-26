# Syll core reliability candidate (2026-09-26)

## Source and scope

This candidate starts at root `1a014c769ec2e37e27f993ad0fc315feb0a69f1f`,
with VoiceInk submodule `3c211dab63454f18cf3f8b58750ec6bf3f5b4d17`.
The build-239 core composition is `overlays/core`, followed by
`core.patch`, `syll-branding.patch`, `syll-recovery.patch`,
`syll-shell-structural.patch`, and `syll-command-mode.patch`. The new
`syll-core-reliability.patch` follows those unchanged historical patches.
The core path pins FluidAudio `c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7`.
The original checkout's dirty `app/` was not used or changed.

The reproduced baseline retains local Parakeet V3, hold-to-dictate,
deterministic correction and cleanup, persistence before delivery, clipboard
restoration conditional on posting a paste command, Copy Last Transcription,
and the existing application/menu identity. Command Mode remains present and
open, without modification or acceptance.

## Recognition-time vocabulary finding

Observed in the pinned FluidAudio source on 2026-09-26:
`ASR/Parakeet/AsrTypes.swift` defines `ASRConfig` without a context or personal
vocabulary field. `ASR/Parakeet/SlidingWindow/TDT/AsrManager.swift` exposes
`transcribe` with audio, decoder state and optional language only. Its
`vocabulary` property is the model's token-id decoding table, not personal
terms. The separate `CustomVocabulary/VocabularyRescorer.swift` uses CTC
acoustic rescoring and additional model machinery. Syll's effective
`FluidAudioTranscriptionService.swift` calls `AsrManager(config: .default)` and
`transcribe(audioURL, decoderState:..., language:...)`. No suitable bounded
recognition-time personal vocabulary input exists in this exact core path.
Recognition remains unchanged; post-ASR dictionary correction remains the
deterministic fallback. This is a source/API finding, not a measured accuracy
or latency result.

## Mechanical evidence and build limit

`python3 scripts/verify_overlay.py --core-only` and the full metadata variant
pass. Standalone checks compiled the actual cleanup/corrector/replacement
sources and extracted the exact persisted-record lookup against in-memory
SwiftData; they passed the casing, alias, punctuation, noncascade, and newest
completed ordinary dictation cases. App-hosted XCTest files are included for
future review but were not run, because they would launch a test host.

The isolated `scripts/build-local-app.sh --core-only` build resolved the exact
FluidAudio revision, then stopped in MLX's `steel_attention.metal` before
compiling changed Syll sources: Xcode 27.0 reported a missing Metal Toolchain.
No application bundle was produced or launched. This host toolchain issue is
not evidence of a Syll source compile failure or a successful candidate build.

## Future correction-learning seam

A bounded future experiment would need an ephemeral correlation ID, the raw
recognizer result, final delivered text, the focused receiving editable
element and selected/insertion range at delivery, and a short-lived edit
observation tied to that same range. Current `TranscriptionPipeline` filters
and transforms the recognizer string before assigning `transcription.text`;
the raw recognizer result is not retained in the persisted record. The
delivery path does not capture a stable receiving element/range or verify the
resulting insertion. No edit observation or persistence is added here.

## Review boundary

This is an uninstalled source/build candidate. Mechanical checks do not prove
cursor delivery, clipboard behavior in a real target app, accent-specific
short utterances, or human acceptance. Supervisor should first review this
exact candidate composition and its test/build evidence. If approved for a
later install, human experience should check ordinary Fn hold, failed cursor
delivery followed by menu Copy Last, clipboard preservation, dictionary
mixed-case at sentence start, and short utterances. Do not treat Command Mode
as accepted by that review.
