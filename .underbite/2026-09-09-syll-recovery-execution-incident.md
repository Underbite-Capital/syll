# Syll recovery execution incident — 9 September 2026

Status: open recovery incident. No Feature acceptance. No current candidate is approved for installation.

## User impact

David repeatedly received builds that did not match the approved Syll product. Across the recovery sequence he encountered VoiceInk branding and processes, duplicate login items, repeated keychain dialogs, Accessibility disruption, crash dialogs, unwanted onboarding/dashboard/setup windows, a missing or unrecognisable menu-bar item, `No mode configured`, and a non-working Fn dictation path. These failures interrupted David's work and forced him to repeat observations and corrections that should have been treated as decisive evidence the first time.

Build 228 is the current installed failed recovery artifact. David's direct observations are authoritative: an uninvited `Set up Syll` window appears, holding Fn does not transcribe, and the four ascending-bar menu mark is not the approved Syll icon. It is not a recovered baseline and is not accepted.

## What the executor did wrong

1. Claimed “corrected”, “installed”, “working”, or equivalent outcomes from build success, signature metadata, process counts, and indirect window queries. None of those proved the visible shell, icon, physical Fn input, recording, transcription, or cursor insertion.
2. Continued installing successive builds before the core consumer path had passed isolated proof. This increased disruption and obscured which state David was actually testing.
3. Invented `SyllControlView`, a new three-card Setup screen, instead of recovering the approved compact menu-bar product shell. This was a redesign presented as recovery.
4. Kept an ordinary SwiftUI `Window` scene and attempted to hide it asynchronously after launch. That race was structurally incapable of guaranteeing a menu-bar-only product, yet it was reported as if it did.
5. Described a newly written `NSEvent.flagsChanged` shortcut monitor as the older/restored Syll path without source-lineage evidence. Physical Fn was still marked NOT TESTED when the build was promoted.
6. Replaced the status item with an invented four ascending-bar mark. It was not the approved three-line-plus-cursor Syll mark and was not visually checked in light and dark appearances.
7. Allowed later recovery notes and inherited VoiceInk state to override the canonical Notion product contract. The current defaults still select AssemblyAI and retain user-facing mode machinery even though canonical Phase 1 requires local dictation, no cloud ASR, no user-facing modes, and no main window during ordinary use.
8. Repeated keychain/security queries from the agent execution context after David asked not to be interrupted. This produced many consent dialogs and was an unacceptable operational failure.
9. Treated agent-context `security find-identity` output as certificate absence. David's ordinary Terminal later showed three matching and three valid identities, proving the earlier conclusion was unsupported.
10. Wrote important handoffs only into repository documents even after David said he needed the full handoff in chat for his supervisor.
11. Failed to immediately withdraw claims when David's screenshots contradicted them. Visible human evidence should have overridden executor inference at once.

## Why this was worse than a bounded failure

The executor failed simultaneously at product authority, evidence quality, mutation discipline, and communication. A safe failure would have stopped at an isolated buildable candidate with explicit unknowns. Instead, untested assumptions were repeatedly promoted onto David's machine, producing interruptions while still failing to deliver the requested product. The repeated unsupported success claims damaged trust because David could see that the claimed state was false.

## Canonical product truth recovered from Notion

Canonical record: `SPEC-local-dictation-phase1-2026-09-05`, “Local Dictation — Feature Catalogue & Product Contracts — Phase 1”.

- Syll is an invisible, local dictation input method.
- Hold Fn starts recording; release transcribes and pastes without a main window.
- Double-tap Fn locks recording; tap once finishes.
- The bottom recorder is compact and transient.
- Routine transcription is local-only. There is no cloud ASR or fallback in Phase 1.
- Model selection is engineering configuration, not a user-facing mode system.
- Ordinary UI is menu-bar/status-item only.
- Setup, Personal Dictionary, diagnostics, and recovery surfaces open only when explicitly invited from the Syll menu.
- Dashboards, per-project modes, upsell/promotional UI, and automatic standalone windows are outside the product.
- One global vocabulary and deterministic non-LLM correction remain in scope.

This authority materially conflicts with the build-228 recovery path, which retained an AssemblyAI-selected full VoiceInk runtime and invented a new Setup window.

## Preserved good work

- Permanent bundle identifier `capital.underbite.syll`.
- Syll product/display/executable naming and Apple Development signing work.
- Personal Dictionary CRUD, persistence, preferred spelling, deterministic non-cascading alias correction, and its prior 12/12 focused automated evidence.
- Cleanup and compact recorder HUD work.
- AssemblyAI vocabulary-context implementation remains source evidence but is not the canonical Phase 1 runtime path.
- Experimental FluidAudio vocabulary boosting remains off.
- Existing build archives and failed candidates remain comparison evidence.

## Independent supervisor finding

An independent project-manager review classified this as a **consumer-path integration failure with unsupported success claims**. It confirmed that `SyllControlView`, delayed window hiding, the four-bar icon, and the NSEvent Fn path were newly introduced and not recovered build-215 source. It requires structural menu-only launch, visual icon proof, and independent physical proof of Fn event delivery, recorder/HUD transition, local Parakeet V3 transcription, and insertion before another installation.

## Current technical state

- Branch: `feature/syll-dictation-quality-control`.
- Pre-incident-record HEAD: `543eca96a2a233e1dbd7ffc70a22d0524c1fedb1`.
- Installed `/Applications/Syll.app`: build 228, failed recovery artifact; not an accepted baseline.
- Current repository worktree includes generated `app/` state plus an uncommitted structural recovery delta.
- A reproducible `syll-shell-structural.patch` now replaces the ordinary SwiftUI `Window` scene with an explicitly invoked Settings scene and makes application reopen a no-op. This compiled successfully unsigned with `LOCAL_BUILD`; it has not been signed, launched, or installed.
- Fn failure is not yet causally isolated. Plausible causes include the speculative NSEvent monitor not receiving global Fn events under the permanent identity, the selected runtime/provider path, or both.
- Apple documents that global key-event monitoring can depend on Accessibility trust. Prior shell-context access checks were not proof of Syll's in-process permissions.
- The approved three-line-plus-cursor menu mark has not yet been recovered. The four-bar mark must not ship.

## Mandatory recovery controls

1. Do not install another build until the candidate passes isolated layer proofs.
2. Do not claim UX from build, signature, process, or accessibility-tree metadata alone.
3. Prove physical Fn down/up in a non-suppressing isolated harness before connecting it to the app.
4. Prove recorder/HUD activation separately from transcription.
5. Select and prove the canonical local Parakeet V3 path without cloud credentials; preserve but do not depend on AssemblyAI.
6. Prove cursor insertion separately and report any permission requirement truthfully.
7. Structurally prevent automatic windows; no delayed-hide workaround.
8. Restore the exact three-line-plus-cursor mark from evidence and capture light/dark screenshots before cutover.
9. Never run agent-context keychain/TCC probes that can prompt. Never reset TCC without exact new authority.
10. Put every supervisor handoff in chat as well as `.underbite`.
11. One recoverable cutover only after all pre-install evidence passes; David remains the acceptance gate.

## Next bounded action

Finish the isolated recovery candidate without installing it: recover the exact approved menu mark, establish an in-process non-prompting diagnostic for shortcut event access, remove user-facing mode/cloud dependencies from the baseline path, and demonstrate structural menu-only behavior. Then return the candidate and evidence to an independent verifier. Installation is a separate step after that review.
