# David Voice Local Dictation

## Outcome

Give David a same-day, private macOS dictation experiment that determines whether local VoiceInk + BOYA + terminology correction is close enough to Wispr Flow to justify any further work.

## Current phase

Human-validation spike. The ad-hoc-signed arm64 app builds and launches; dictionary/configuration artifacts are ready. macOS permission grants, BOYA testing and the 20-prompt adoption evidence remain David's acceptance gate.

## Decision contract

- **Decision this project must enable:** Could David actually live with this instead of immediately returning to Wispr Flow?
- **Review test:** BOYA 20-clip comparison plus 20 real prompts across ChatGPT, Claude and Cursor.
- **Commercial owner:** David.
- **Technical owner:** David / Codex for the bounded spike.
- **Human authority gates:** Accessibility permission, acceptance, preference and Done remain David's decisions.

## Recommended direction

Use current VoiceInk as the shell. Begin with Parakeet V3, compare the same captured audio with Whisper Large V3 Turbo, import the seeded dictionary, keep cleanup OFF for the baseline and do not add Voxtral or another provider before the human trial.

## Evidence and provenance

- Project key: `PROJECT-DAVID-VOICE-LOCAL-DICTATION`
- VoiceInk upstream: `Beingpax/VoiceInk` at `fda316996d87bc0c7b68d11a741b5c5aec8d8617` (2026-08-19).
- Supplied brief: `reference/spike-brief.txt`, SHA-256 `167cf3a16d742f9153b5e368d04a3c88ff7325afd06c8d88f34f66692d1c5a52`.
- Research cutoff: 2026-08-20.
- Research intensity: Light, because this is a private, reversible, one-user experiment.
- Source/claim ledgers: `research/source-register.csv` and `research/claim-evidence.csv`.

## Product and technical map

```text
BOYA Magic 02
  -> VoiceInk CoreAudio capture + push-to-talk
  -> Parakeet V3 (first) or Whisper Large V3 Turbo (comparator)
  -> paragraph formatting if enabled
  -> deterministic word replacements (global Dictionary corrections toggle)
  -> optional AI enhancement using David cleanup
  -> cursor paste
  -> Auto Send None
```

VoiceInk owns microphone capture, permissions, global shortcuts, recorder UI, focused-app context, model management and delivery. The spike adds only versioned dictionary/configuration artifacts and a two-file global dictionary toggle.

## Verification status

- `scripts/validate_project.py`: passes.
- Dictionary parser: 26 terms and 18 replacement groups; generated JSON parses.
- VoiceInk prerequisites: macOS 26.5.2 arm64, Xcode 26.6, Git and Swift available.
- Local arm64 Debug build completed successfully with ad-hoc signing; deep code-signature verification passes.
- Runtime launch reached VoiceInk's permissions screen. No OS permission was granted by Codex.
- Microphone/Accessibility, BOYA selection, three-app paste and no-submit remain David-run checks because they require security-sensitive permission and live speech.
- No ASR winner, latency or Flow preference is claimed yet.

## Risks and unknowns

1. Ad-hoc rebuilds may prompt for macOS permissions again.
2. The BOYA's exact device identity and audio quality are not observable while disconnected.
3. Generic model recommendations may not transfer to David's speech and terminology.
4. Existing/migrated VoiceInk modes can enable Auto Send even though the default is None; inspect the active mode.
5. Optional cleanup can change meaning; any semantic drift means it stays OFF.
6. GitHub registration is blocked until the local `gh` authentication is repaired.

## Immediate next decision

Grant only the required permissions and complete the shell smoke test in `TRY-IT.md`. If it passes, record the BOYA corpus and 20 prompts. If it does not pass within the 90-minute shell bound, stop and record the exact blocker rather than expanding the build.

## Workspace map

- `TRY-IT.md` — exact same-day setup and trial.
- `SPIKE-REPORT.md` — concise evidence-backed status and final questions.
- `dictionary.yaml` — human-editable source of truth.
- `cleanup-prompt.txt` — exact optional cleanup contract.
- `prototype/VoiceInk_David_Settings.json` — VoiceInk import artifact generated from the dictionary/prompt.
- `evidence/test-corpus.md` — 20 diagnostic utterances.
- `evidence/benchmark.csv` — two-model results table.
- `evidence/20-prompt-trial.csv` — adoption log.
- `app/` — clean VoiceInk submodule pinned to the inspected upstream commit.
- `patches/voiceink-dictionary-toggle.patch` — reproducible two-file source delta against the pinned VoiceInk commit.
- `research/` — Light two-lens diligence and provenance.
- `reference/` — byte-identical supplied brief.
