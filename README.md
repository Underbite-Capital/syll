# VoiceInk Personal Dictionary

A small downstream VoiceInk build for David: better terminology, safer dictation cleanup, and optional local word boosting—without replacing VoiceInk's recorder, shortcuts, model management, or cursor delivery.

## Current status

The active implementation lives on `codex/voiceink-personal-dictionary`. It is deliberately a review candidate, not a claimed release. The core code and exact upstream patches are present; CI can prove that the overlay applies cleanly. Xcode build, microphone, insertion, cleanup quality, and recognition quality still require David's Mac and judgement.

## Scope

```text
existing VoiceInk capture and transcription
  -> optional FluidAudio vocabulary boosting
  -> one-pass deterministic alias correction
  -> optional guarded cleanup
  -> existing VoiceInk delivery
```

Included:

- one Personal Dictionary surface with preferred spellings and aliases;
- non-cascading Unicode-aware deterministic correction;
- exact dictionary spellings supplied to cleanup;
- five-second, one-attempt cleanup for cleanup-named prompts;
- deterministic validation and fallback to corrected transcription;
- optional fail-open FluidAudio CTC vocabulary boosting;
- focused tests, reproducible preparation, and cleanup documentation.

Excluded:

- a new recorder or hotkey system;
- hosted services or team vocabulary;
- automatic dictionary learning;
- a second cleanup judge agent;
- streaming-provider boosting;
- autonomous acceptance in place of David using the app.

## Prepare the app

```bash
git checkout codex/voiceink-personal-dictionary
python3 scripts/verify_overlay.py
./scripts/prepare-app.sh --reset
open app/VoiceInk.xcodeproj
```

The full path includes experimental native boosting. To prepare the safer dictionary + cleanup build:

```bash
./scripts/prepare-app.sh --core-only --reset
```

The script refuses to overwrite dirty work unless `--reset` is explicit.

## Source of truth

- VoiceInk upstream: `Beingpax/VoiceInk@3c211dab63454f18cf3f8b58750ec6bf3f5b4d17`
- Core replacements/new files: `overlays/core/`
- Optional boosting adapter: `overlays/boosting/`
- Minimal edits to existing upstream files: `patches/`
- Human-editable terminology seed: `dictionary.yaml`
- Importable starting configuration: `prototype/VoiceInk_David_Settings.json`
- Detailed handoff: `docs/IMPLEMENTATION-HANDOFF.md`
- Acceptance checklist: `docs/MANUAL-QA.md`

Do not make ad hoc edits under `app/` and then forget them. Port accepted fixes back into an overlay or patch so a clean checkout can reproduce the build.

## Why this repository is still a submodule overlay

The old spike already used VoiceInk as a submodule. Rather than pretending that wrapper was a fork, this branch makes the arrangement explicit and reproducible. It preserves a small downstream delta and an immediate `--core-only` escape hatch. A future maintainer can convert it to a conventional fork after the product proves useful; doing that before the human trial adds repository work without improving dictation.

## Historical evidence

The original spike report, research, test corpus, and benchmark templates remain in place. They are evidence of what was attempted, not proof that the product worked.

VoiceInk is GPL-3.0. Any distributed modified build must continue to comply with its licence.
