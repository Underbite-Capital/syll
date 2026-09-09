# Syll follow-up release plan

Status: frozen from David’s direct feedback on 2026-09-09. No implementation, installation, launch, preference mutation, or further visual substitution is authorised by this record.

## Current accepted baseline

- Build 234 is running from `/Applications/Syll.app`.
- David reports that hold-to-talk with Fn works and that transcription is materially better even in a noisy environment.
- David confirms that **Copy Last Transcription** works.
- Keep the dictation, model, recording, paste, permissions, and compact-HUD paths frozen while addressing the follow-ups below.

## Required follow-ups

### 1. Exact coloured menu-bar identity

Observed fact: the status item is now visible, but David rejects its monochrome treatment.

Required outcome: the menu-bar item must use the exact approved orange Syll mark selected by David — the orange rising bars and vertical stroke on the navy rounded square — rather than a monochrome/template approximation.

Authority lock: do not substitute another icon, recolour it, simplify it, or infer an alternative. The authoritative source remains `build/recovery-archives/Syll-build221.app.zip`, rendered PNG SHA-256 `590b1986b8b1c5e4d07c926acd50cb8bdf50f0e94737253e6c47005f28a0de23`.

Acceptance: David sees that exact coloured mark in the menu bar and explicitly accepts it.

### 2. Remove residual VoiceInk naming

Observed fact: David reports that the application is still presented as “VoiceInk”.

Required outcome: audit and remove all user-visible `VoiceInk` names from the installed Syll experience, including menu/window/settings/prompt surfaces, application metadata, and any name exposed by macOS where it is safe to change without breaking the accepted identity, permissions, or data migration.

Acceptance: David can find no user-visible “VoiceInk” label in the ordinary Syll flow. Internal source/module/provenance identifiers may remain only when they are not user-visible.

### 3. Personal Dictionary must open

Observed fact: clicking **Personal Dictionary** in the visible Syll menu produced no user-facing window.

Required outcome: the menu action must reliably open the Personal Dictionary window/scene and make its CRUD UI usable, without changing dictation behavior.

Acceptance: from the Syll menu, David clicks **Personal Dictionary** and a usable Personal Dictionary surface appears every time.

## Release sequence

1. Create one isolated candidate from the proven working recovery source.
2. Implement and verify the coloured status-item rendering against the authoritative asset; do not alter dictation code.
3. Trace the residual visible naming and the dictionary menu-action route with focused tests.
4. Present one uninstalled candidate with visual evidence and a precise source/behavior delta for David’s approval before replacing `/Applications/Syll.app`.
5. Archive the accepted installed build immediately before any approved replacement.

## Explicitly deferred

- Recorder HUD spacing, slimmer centre meter, and alternative Granola/Jamie-style indicator remain future design work.
- No further changes are authorised by this plan until David asks to resume it.
