# Technical literature review

## Executive answer

**Supported but conditional:** use current VoiceInk unchanged as far as possible, with Parakeet V3 as the first model and Whisper Large V3 Turbo as the in-shell comparator. VoiceInk already implements the macOS shell, explicit mic selection, push-to-talk, local Parakeet/Whisper models, post-ASR deterministic replacements, optional enhancement and paste/auto-send controls. The strongest limitation is that no source or generic benchmark can answer David's edit burden on BOYA speech. The highest-information experiment is the supplied 20-clip corpus plus 20 real prompts.

Voxtral via MLX is excluded from the first pass: VoiceInk has no Voxtral transcription provider, and the official Voxtral Mini 3B model card recommends vLLM/Transformers with about 9.5 GB GPU memory rather than a supported MLX/macOS path. Adding it would violate the spike's “reasonably easy” and “no provider abstraction” constraints.

## Decision contract and invariants

- **Architecture or feasibility decision:** Can configuration plus a two-file dictionary toggle patch make current VoiceInk a valid trial shell?
- **Must preserve:** local transcription by default, explicit BOYA selection, no automatic submission, deterministic corrections, optional cleanup and the 90-minute stop rule.
- **Critical failure:** a compile-only result mistaken for end-to-end acceptance, or a mode that presses Return after paste.
- **Non-goals:** new capture, permissions, hotkey, UI, provider or model-management architecture.
- **Research cutoff:** 2026-08-20

## Review method

Sources were limited to the supplied brief, current official VoiceInk repository/docs, the pinned local source, FluidAudio, WhisperKit and Mistral's official model card. Local code was inspected at upstream commit `fda316996d87bc0c7b68d11a741b5c5aec8d8617`. Generic ASR benchmark numbers were not used to choose a winner because the decision metric is David's correction burden.

## Research questions

| ID | Question | Decision changed by the answer | Evidence needed | Status |
| --- | --- | --- | --- | --- |
| T1 | Does VoiceInk already contain the required shell? | Build vs configure | Current source and docs | Established |
| T2 | Are Parakeet V3 and strong Whisper models present locally? | Candidate set | Model registry and official docs | Established |
| T3 | Are replacements deterministic and boundary-safe? | Patch vs reuse | Source inspection plus focused tests | Supported but conditional |
| T4 | Can dictionary/cleanup settings be imported? | Same-day setup burden | Backup decoder/importer and generated artifact | Established |
| T5 | Is Voxtral via MLX a bounded addition? | Third candidate | Official runtime guidance and current project integrations | Open question; excluded from first pass |
| T6 | Which model makes David edit least? | ASR winner | BOYA corpus | Open question |

## Method and evidence comparison

| Method / system | Demonstrated capability | Dataset / domain | Assumptions | Failure modes | Maintenance / licence | Transfer to this project | Evidence status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| VoiceInk main | macOS recording, permissions, mic selection, shortcuts, local models, dictionary, paste and mode output | General dictation | macOS 14.4+, Apple Silicon for preferred path | Permissions, paste focus, sleep/wake UI issues | Active official repo; GPL-3.0 | Direct shell | Established |
| Parakeet V3 via FluidAudio | On-device Core ML ASR and streaming support | Multilingual general ASR | BOYA audio is intelligible | Jargon errors; no clean hotword path in inspected VoiceInk service | FluidAudio pinned to main; Apache-2.0; model terms must be retained | First candidate | Supported but conditional |
| Whisper Large V3 Turbo via whisper.cpp | Strong local Whisper comparator already listed in VoiceInk | General multilingual ASR | Download and memory acceptable | Slower release-to-text latency | whisper.cpp dependency; MIT; model files separate | Second candidate without new provider | Supported but conditional |
| WhisperKit | Official Apple-Silicon Whisper runtime | General multilingual ASR | Integration effort is justified | Duplicate provider work during spike | MIT | Not selected because VoiceInk already ships whisper.cpp | Project inference |
| Voxtral Mini 3B | Audio transcription and understanding through vLLM/Transformers | Published model benchmarks | Suitable local macOS runtime exists | Large model/runtime and integration cost | Apache-2.0 model card | Excluded unless first two candidates both fail and an MLX path becomes trivial | Supported but conditional |

## Implementations, datasets and standards

- VoiceInk requirements: macOS 14.4+, Xcode/CLI tools and Git; local builds omit iCloud dictionary sync and automatic updates.
- Current VoiceInk source lists Parakeet V3 (494 MB) and Whisper Large V3 Turbo (1.5 GB), while exact real latency remains unmeasured.
- FluidAudio is integrated at a pinned Swift package revision in VoiceInk. VoiceInk's FluidAudio service loads local model assets and does not expose a vocabulary-bias parameter in the inspected batch transcription path.
- VoiceInk word replacements are applied after ASR, case-insensitively, longest-first, with Unicode-aware boundaries for spaced languages. Vocabulary is enhancement context, not Parakeet bias.

## Threats to validity and transfer limits

Official docs describe capabilities but do not prove this Mac's permissions, the BOYA device name, current-cursor delivery in each target app, latency, jargon accuracy or preference versus Flow. David's accent, speaking speed, room noise and prompt style dominate transfer. A 20-clip corpus is intentionally diagnostic, not statistically generalisable.

## Architecture inference chains

```text
VoiceInk already contains the shell and Parakeet V3 -> duplicated shell work adds no decision evidence
-> configure current VoiceInk -> predict same-day usable baseline -> build and three-app cursor trial.

VoiceInk replacements are post-ASR and boundary-aware -> dictionary behavior does not require an ASR feature
-> import generated replacements -> predict seeded aliases survive punctuation without fragment matches
-> focused replacement checks plus BOYA terminology clips.

No supported Voxtral/MLX path exists in the shell -> third provider adds integration risk before comparative evidence
-> defer Voxtral -> predict Parakeet/Whisper comparison answers the first decision
-> reconsider only if both fail for different, fixable reasons.
```

## Experiment backlog

| Priority | Hypothesis | Smallest test | Baseline / reference | Metric | Failure threshold | Decision / reversal condition |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | VoiceInk shell works without redesign | Launch, grant permissions, select BOYA, paste into three apps | No local build | 10 shell checks | Any persistent paste/permission/auto-send failure | Stop shell work at ~90 minutes |
| 2 | Parakeet V3 minimises interactive wait | 20 BOYA clips | Wispr Flow and Whisper Turbo | median release-to-ready and edit burden | Feels substantially slower than Flow | Prefer Whisper or stop |
| 3 | Deterministic aliases protect key terms | Corpus rows C01-C17 with dictionary ON/OFF | Raw ASR | terminology errors/edit burden | Important terms still require routine manual repair | Patch alias set once or stop |
| 4 | Cleanup helps without semantic drift | Prompts 11-20 with cleanup ON | First 10 OFF | edits and meaning violations | Any invented/softened instruction | Keep cleanup OFF |

## Completion audit

- [x] Consequential source and claim entries recorded.
- [x] Primary/official sources support mechanisms and operational facts.
- [x] Current versions, source commit and licences checked.
- [x] Transfer limits and excluded Voxtral path are visible.
- [x] Recommendations are labelled by evidence status.
- [x] The top experiment has a stop/reversal rule.
