# Spike report

## Current decision

**Not yet decided.** The shell and configuration can be prepared by Codex; ASR winner, latency, BOYA behavior and preference require David's recorded speech and 20-prompt trial.

## Build and shell

| Item | Status | Evidence / gap |
| --- | --- | --- |
| VoiceInk source | Ready | Upstream `fda316996d87bc0c7b68d11a741b5c5aec8d8617` imported under `app/` |
| Local build | Ready | arm64 Debug app built with Xcode 26.6 and ad-hoc signing; `codesign --verify --deep --strict` passes |
| App launch | Passed | `/Users/david/Downloads/VoiceInk.app` launched and reached the VoiceInk permissions screen |
| Microphone / Accessibility | Pending David/macOS | Security-sensitive OS permission gate |
| BOYA selection | Pending connected device | Current VoiceInk exposes Selected Microphone |
| ChatGPT / Claude / Cursor insertion | Pending | Must be tried without submission |
| No automatic submission | Source-supported; runtime pending | Auto Send defaults to None and is configurable per mode |

## Dictionary

- Human source: `dictionary.yaml`
- Import artifact: `prototype/VoiceInk_David_Settings.json`
- Seed: 26 canonical terms and 18 deterministic alias groups.
- Pipeline: ASR → optional paragraph formatting → deterministic replacement → optional AI enhancement → paste.
- Matching in current VoiceInk: case-insensitive, longest-first and Unicode-boundary-aware for spaced languages.
- ASR bias: not forced into Parakeet because the inspected VoiceInk/FluidAudio call does not expose a clean vocabulary parameter. Vocabulary is supplied to enhancement when enabled.
- Contextual entity repair: not added; measure the deterministic layer first.

## Model comparison

| Model | Why included | Corpus result | Typical latency | Decision |
| --- | --- | --- | --- | --- |
| Parakeet V3 via FluidAudio | Preferred local path already in VoiceInk | Pending BOYA corpus | Pending | First candidate |
| Whisper Large V3 Turbo via whisper.cpp | Strong local comparator already in VoiceInk | Pending BOYA corpus | Pending | Second candidate |
| Voxtral via MLX | No supported in-shell MLX path; official Mini 3B guidance targets vLLM/Transformers and a much larger runtime | Not run | Not run | Deferred by spike scope |

## Cleanup

The exact **David cleanup** contract is versioned in `cleanup-prompt.txt` and included in the import artifact. It is optional and must remain OFF for the raw ASR/dictionary baseline. No contextual entity-repair pass has been added.

## What still fails or remains unknown

- Actual BOYA device detection and audio quality.
- Release-to-cursor latency and raw transcripts.
- Permission grant and persistence for the ad-hoc build.
- Cursor insertion behavior across the three named apps.
- Whether dictionary aliases cover David's recurring misrecognitions without false positives.
- Whether cleanup helps without semantic drift.
- David's preference after 20 prompts.

## Smallest next step

Complete `TRY-IT.md` through the shell smoke test, then record the BOYA corpus with Parakeet V3 and Whisper Large V3 Turbo. Do not add another model or feature before those results.
