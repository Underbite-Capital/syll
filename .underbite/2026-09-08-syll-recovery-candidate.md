# Syll recovery candidate

Date: 2026-09-08
Status: implementation candidate; installed cutover and human QA pending

## Authority recovered

The current Notion Phase 1 contract confirms that ordinary Syll use is a menu-bar/status item plus the transient recorder. Dashboard, modes, promotional UI, automatic onboarding, and an ordinary standalone launch window are not part of the daily product surface.

## Implementation

- Preserved every source commit through `da5b8e50b4324d764c37c8bf7207207c9dcf6fd4` and the generated `app/` state.
- Added `SyllIdentityMigration` from `com.prakashjoshipax.VoiceInk` to `capital.underbite.syll` using an explicit preference allowlist.
- Shortcut values are decoded as `Shortcut`, validated, and only then migrated. The known double-base64 93-byte value is rejected and replaced by the legacy valid Fn record when present.
- Existing Application Support and keychain service paths remain in place to preserve the working model, dictionary, history, and provider data rather than creating duplicate stores.
- `LSUIElement` is true and the routed UI is `SyllControlView`, never the upstream dashboard/onboarding.
- The menu exposes recorder toggle, Copy Last Transcription, Personal Dictionary, Setup, History, Advanced Settings, Launch at Login, and Quit Syll. Upstream promotion and Dock-mode controls are absent.
- Global shortcut monitoring now uses a non-suppressing `.listenOnly` event tap. `CGPreflightListenEventAccess()` returned `true` in David's logged-in session. Physical Fn and post-update dictation remain human QA gates.
- Personal Dictionary, AssemblyAI vocabulary context, deterministic alias correction/cleanup, compact HUD, and FluidAudio-off behavior remain unchanged.

## Evidence

- Core overlay validation: PASS.
- Reproduction from pinned upstream plus core, branding, recovery patches and overlays: PASS; `git diff --check` clean.
- App and tests compile: PASS.
- App-hosted tests were stopped because Xcode launched the upstream-named unsigned test host and caused an unwanted keychain dialog. Before interruption, all reported dictionary/correction tests and both new identity-migration tests passed. This runner must not be used again in David's active desktop session.
- Isolated signed artifact: `build/syll-recovery-candidate-222/Syll.app`, build 222.
- Candidate identity: `capital.underbite.syll`; name/display/executable `Syll`; `LSUIElement=true`.
- Signing: Apple Development `69C2BB0FE6E75589F044A08105D99DBEFC6DCFC5`; TeamIdentifier `A635S52367`; deep/strict verification PASS in the normal macOS context.
- Candidate has not been launched or installed. Personal Dictionary visual QA, physical Fn, real dictation, permission continuity, and restart/login behavior are NOT TESTED.
- `/Applications/Syll.app` build 221 remains untouched and is the failed-shell artifact pending controlled cutover.

## Exact next action

Commit the recovery source, rebuild the exact committed candidate, then perform one controlled cutover: terminate build 221, archive it as non-launchable recovery evidence, atomically replace it, launch exactly one Syll, and ask David only for physical Fn/dictation plus invited Personal Dictionary inspection. Restart/login proof follows only after those checks pass.

Do not call the Feature accepted.
