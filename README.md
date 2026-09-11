# Syll

A small, menu-bar-first macOS dictation app built on VoiceInk's mature recorder and transcription machinery.

## Current status

The active implementation lives on `feature/syll-dictation-quality-control`. Command Mode is **OPEN / NOT ACCEPTED / NOT VERIFIED**: the implementation exists and passes its recorded mechanical checks, but the current candidate failed human QA. Double-tap reached the command HUD, yet “What’s on port 3 thousand?” was interpreted as an invalid port and did not execute the intended command. Mechanical test or build success must not be treated as evidence that Command Mode works. See `.underbite/2026-09-11-syll-command-mode-candidate.md` before resuming.

## Scope

```text
existing VoiceInk capture and transcription
  -> AssemblyAI recognition context when selected
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
- AssemblyAI recognition context and FluidAudio remaining disabled in the core path;
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
git checkout feature/syll-dictation-quality-control
python3 scripts/verify_overlay.py --core-only
./scripts/prepare-app.sh --core-only --reset
./scripts/build-local-app.sh --core-only
```

The commands above are the safer dictionary + cleanup path. The build is ad-hoc signed with reduced local entitlements and is not installed or launched automatically.

Only after core human acceptance, prepare the experimental native-boosting path with:

```bash
python3 scripts/verify_overlay.py
./scripts/prepare-app.sh --reset
./scripts/build-local-app.sh --full
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
