# Syll

A small, menu-bar-first macOS dictation app built on VoiceInk's mature recorder and transcription machinery.

## Current status

`main` is the authoritative source branch. The core-reliability composition has passed a local build and mechanical checks, but it has not been installed or accepted by human QA. The installed Syll app remains separate from this source result. The ordinary Fn hold-to-dictate path has prior human evidence; the current source still needs a later bounded experience check before release.

The local diagnostic candidate investigates David's separate report that short recordings can miss their first words. It adds bounded local capture evidence, a smaller everyday menu, and `Reset Clipboard`; it does not change the shipping recognizer or claim to have fixed first-word loss. See `.underbite/2026-09-26-recording-start-and-operational-diagnostics.md` for the source trace, retention limits, and unresolved live evidence gate.

Command Mode is **OPEN / NOT ACCEPTED / NOT VERIFIED**. The historical build-239 candidate failed human QA: double-tap reached the command HUD, but “What’s on port 3 thousand?” was interpreted as an invalid port. Its code remains in the composition without product acceptance. The future double-tap action is undecided. See `.underbite/2026-09-11-syll-command-mode-candidate.md`.

## Scope

```text
existing VoiceInk capture
  -> local Parakeet V3 recognition
  -> conservative deterministic cleanup
  -> one-pass user-authoritative dictionary correction
  -> persist completed transcription before delivery
  -> existing VoiceInk cursor/clipboard delivery
```

Included:

- one Personal Dictionary surface with preferred spellings and aliases;
- non-cascading Unicode-aware deterministic correction;
- exact preferred dictionary spellings retained after cleanup;
- five-second, one-attempt cleanup for cleanup-named prompts;
- deterministic validation and fallback to corrected transcription;
- local Parakeet V3 in the core path, without recognition-time vocabulary bias;
- Copy Last Transcription from the latest completed audio-backed dictation;
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
git checkout main
python3 scripts/verify_overlay.py --core-only
./scripts/prepare-app.sh --core-only
./scripts/build-local-app.sh --core-only
```

Run preparation in a fresh clone or disposable checkout with a clean pinned `app/` submodule. The core build is ad-hoc signed with reduced local entitlements and is not installed or launched automatically. The currently installed `/Applications/Syll.app` is not replaced by these commands.

The historical experimental native-boosting path remains available for research, but is not the current core composition:

```bash
python3 scripts/verify_overlay.py
./scripts/prepare-app.sh --reset
./scripts/build-local-app.sh --full
```

The script refuses to overwrite dirty work unless `--reset` is explicit. Do not use `--reset` on a checkout with unclassified work.

## Source of truth

- VoiceInk upstream: `Beingpax/VoiceInk@3c211dab63454f18cf3f8b58750ec6bf3f5b4d17`
- Core replacements/new files: `overlays/core/`
- Optional boosting adapter: `overlays/boosting/`
- Minimal edits to existing upstream files: `patches/`
- Human-editable terminology seed: `dictionary.yaml`
- Importable starting configuration: `prototype/VoiceInk_David_Settings.json`
- Detailed handoff: `docs/IMPLEMENTATION-HANDOFF.md`
- Acceptance checklist: `docs/MANUAL-QA.md`
- Local recognition research and bounded evaluator: `.underbite/2026-09-26-local-recognition-study.md` and `tools/recognition-eval/` (no product-path change or acceptance)
- Local recording-start investigation and bounded operational evidence: `.underbite/2026-09-26-recording-start-and-operational-diagnostics.md` (candidate only)

Do not make ad hoc edits under `app/` and then forget them. Port accepted fixes back into an overlay or patch so a clean checkout can reproduce the build.

## Why this repository is still a submodule overlay

The old spike already used VoiceInk as a submodule. `main` keeps that arrangement explicit and reproducible: the pinned upstream submodule stays clean, while maintained changes live in root overlays and patches. A prepared `app/` is a disposable generated composition.

## Historical evidence

The original spike report, research, test corpus, and benchmark templates remain in place. They are evidence of what was attempted, not proof that the product worked.

VoiceInk is GPL-3.0. Any distributed modified build must continue to comply with its licence.
