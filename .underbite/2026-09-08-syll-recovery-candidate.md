# Syll recovery candidate

Date: 2026-09-08
Status: build 227 installed; human QA pending

## Authority recovered

The current Notion Phase 1 contract confirms that ordinary Syll use is a menu-bar/status item plus the transient recorder. Dashboard, modes, promotional UI, automatic onboarding, and an ordinary standalone launch window are not part of the daily product surface.

## Implementation

- Preserved every source commit through `da5b8e50b4324d764c37c8bf7207207c9dcf6fd4` and the generated `app/` state.
- Added `SyllIdentityMigration` from `com.prakashjoshipax.VoiceInk` to `capital.underbite.syll` using an explicit preference allowlist.
- Shortcut values are decoded as `Shortcut`, validated, and only then migrated. The known double-base64 93-byte value is rejected and replaced by the legacy valid Fn record when present.
- Existing Application Support data remains in place. The Syll local credential namespace is now `capital.underbite.syll.Local`; Syll does not implicitly read the ACL-protected `com.prakashjoshipax.VoiceInk.Local` service because doing so produced a password dialog labelled VoiceInk. The legacy credentials remain preserved in Keychain, but were not copied or deleted.
- `LSUIElement` is true and the routed UI is `SyllControlView`, never the upstream dashboard/onboarding.
- The menu exposes recorder toggle, Copy Last Transcription, Personal Dictionary, Setup, History, Advanced Settings, Launch at Login, and Quit Syll. Upstream promotion and Dock-mode controls are absent.
- Global shortcut monitoring now uses a non-suppressing `.listenOnly` event tap. `CGPreflightListenEventAccess()` returned `true` in David's logged-in session. Physical Fn and post-update dictation remain human QA gates.
- Personal Dictionary, AssemblyAI vocabulary context, deterministic alias correction/cleanup, compact HUD, and FluidAudio-off behavior remain unchanged.
- Build 225 incorrectly added a second service-managed login registration alongside the existing ordinary Syll login item. Build 226 removed that duplicate registration once and does not automatically re-enable it.
- Identity migration version 2 validates and migrates `modeConfigurationsV2` (or its legacy predecessor) plus an active configuration ID that belongs to the decoded mode set. This repairs the earlier `No mode configured` failure without synthesizing a replacement mode.
- The four-bar status mark is rendered as an AppKit template image so macOS supplies the correct light/dark menu-bar foreground color.

## Evidence

- Core overlay validation: PASS.
- Reproduction from pinned upstream plus core, branding, recovery patches and overlays: PASS; `git diff --check` clean.
- App and tests compile: PASS.
- App-hosted tests were stopped because Xcode launched the upstream-named unsigned test host and caused an unwanted keychain dialog. Before interruption, all reported dictionary/correction tests and both new identity-migration tests passed. This runner must not be used again in David's active desktop session.
- Isolated signed artifact: `build/syll-recovery-candidate-227/Syll.app`, build 227.
- Candidate identity: `capital.underbite.syll`; name/display/executable `Syll`; `LSUIElement=true`.
- Signing: Apple Development `69C2BB0FE6E75589F044A08105D99DBEFC6DCFC5`; TeamIdentifier `A635S52367`; deep/strict verification PASS in the normal macOS context.
- Build 223 exposed the legacy local Keychain service and produced a password dialog labelled VoiceInk. It was stopped and archived. Build 224 changed the compiled service to `capital.underbite.syll.Local`; it launched menu-bar-only without that dialog. A read-only `sfltool dumpbtm` probe then caused an unrelated administrator prompt; the probe was terminated and must not be repeated in David's active session.
- `/Applications/Syll.app` is now build 227, bundle ID `capital.underbite.syll`, name/display/executable `Syll`, `LSUIElement=true`, Apple Development signed with TeamIdentifier `A635S52367`. Deep/strict signature verification passed. Exactly one Syll process launched and no VoiceInk process was observed.
- Recoverable archives are preserved through `build/recovery-archives/Syll-build226.app.zip`.
- The earlier focused dictionary/correction evidence remains 12/12 PASS. Recovery compilation and overlay validation pass. App-hosted tests were not rerun because their upstream test host causes desktop/keychain interruption.
- Build 227 completed migration version 2 and restored active configuration `10000000-0000-0000-0000-000000000001`. The app and test bundle compile without execution. Personal Dictionary visual QA, physical Fn, real dictation, Accessibility-dependent insertion, and the corrected icon's dark/light visual appearance are NOT TESTED. The Feature is not accepted.

## Exact next action

David should restart the Mac once. After login, report whether exactly one Syll menu-bar item appears, no VoiceInk UI or password dialog appears, and holding Fn records/transcribes. If Fn works, open Personal Dictionary from the Syll menu and perform the bounded terminology QA. If dictation reports a missing AssemblyAI credential, re-enter it into Syll's own keychain namespace rather than granting the renamed app perpetual access to the legacy VoiceInk item.

Do not call the Feature accepted.
