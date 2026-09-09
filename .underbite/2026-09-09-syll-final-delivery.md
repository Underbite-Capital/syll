# Syll Phase 1 final delivery — 2026-09-09

## Authority and candidate

- Human-authorised local recovery cutover from rejected build 228 to final build 229.
- Permanent identity: `capital.underbite.syll`; executable/product: `Syll`.
- Historical menu icon source blob: `fd19dc02f4e7cfc68b92e8e6042da3368335de83`.
- Build 228 remains rejected evidence and is not an accepted product revision.

## Runtime contract

- Ordinary dictation resolves only the installed `parakeet-tdt-0.6b-v3` FluidAudio model.
- Realtime transcription and AI enhancement are disabled; deterministic formatting and paste delivery are enabled.
- Startup no longer performs the irrelevant Ollama availability probe.
- Dictionary persistence is explicitly local-only, and startup does not construct cloud or custom-provider models.
- Fn supports hold/release, single-tap start with automatic stop, and double-tap lock followed by tap-to-stop.
- The compact recorder HUD is 144 × 40 points and contains no text.
- The menu exposes Toggle Recorder, Copy Last, Personal Dictionary, and Quit; the only settings scene is Personal Dictionary.

## Machine evidence

- Real local inference used the resolved FluidAudio CLI and the installed Parakeet V3 assets, not a mock or fixture transcript.
- Input phrase: `This is a quick test of Syll.`
- Output: `This is a quick test of Sil.`
- Audio duration: 1.750875 seconds; processing: 0.08 seconds; 23× realtime; confidence 0.827.
- Final build: 229. Deep/strict code-sign verification passed with TeamIdentifier `A635S52367`.
- Runtime launch completed and Parakeet V3 prewarm completed in 0.28 seconds without a crash or ordinary app window.
- Exactly one Syll process and one `/Applications/Syll.app` remained after cutover; temporary and repository build bundles were unregistered/removed after archiving.
- Rejected build 228 archive SHA-256: `5f323b15d24c0c9cf1f5c3d4154b7a2ea676c6881f560b61998886ed0c255e93`.
- Earlier discoverable build-bundle archive SHA-256: `ead9c01358d9d73ddcac66f3b03f4788bb6e8af16d8fb3530d55e74507414462`.
- Exact final build-229 source archive: `build/final-artifacts/syll-phase1-build-229-source.tar.gz`; SHA-256 `dd3bdb2a97c5d683b8ae62195d4b63f915680f878796f932c2c84179ec742429`.

## Remaining acceptance gate

Human experiential QA is intentionally limited to one short Fn dictation in a normal text field and one Copy Last check. PASS accepts build 230; FAIL must include the observed symptom.

## Human QA failure and recovery — build 230

- Observed failure on build 229: physical Fn opened and dismissed the recorder and transcription persisted, but cursor insertion did not occur.
- Runtime fact: `CursorPaster` reported that Accessibility permission was not granted. This is the concrete insertion blocker.
- System Settings inspection confirmed `Syll.app` is present in Privacy & Security → Accessibility with its toggle **off**. Enabling that human-controlled toggle is the remaining gate; it was not changed by the executor.
- Build 230 requests the one required macOS Accessibility approval on launch; when posting Cmd-V fails, it now leaves the completed transcription on the clipboard instead of restoring the prior clipboard.
- The menu-bar mark now scales the historical asset to its 18-point status-item bounds. The rejected blue microphone app icon was replaced at all AppIcon sizes with the historical Syll microphone/nib mark.
- Compact HUD width increased from 136 to 144 points.

### Deferred recorder-design request

Observed from `IMG_2443.HEIC`: the left stop control remains visually cramped while the centre audio-meter bars consume too much width. After dictation is accepted, explore a slimmer centre meter and more breathing room around the left control. Also evaluate a lighter Granola/Jamie-like recording indicator while preserving Syll's preferred centred, near-bottom placement. Treat this as a future feature request, not part of the recovery acceptance gate.

## Human functional acceptance and icon-only build 231

- David confirmed build 230 can transcribe using physical Fn and insert text at the cursor after enabling Accessibility.
- Runtime logs independently recorded four successful transcription sessions without the prior Accessibility/paste error.
- Build 230 is the proven-working rollback baseline; archive SHA-256: `a72335333ebb869a505c13d3ac1ecf7d4dd0937988dda16c7caf1cf955f55ff5`.
- The microphone/nib bitmap rendered as an unrecognisable `A`-like menu mark and was rejected by David.
- Build 231 changes only `SyllMenuBarMark` relative to build-230 source: it uses the native macOS `text.cursor` symbol (verified available), monochrome at 15 points within the existing 18-point label. No shortcut, recorder, ASR, processing, persistence, insertion, permission, identity, entitlement, or HUD logic changed.
- Post-cutover: build 231 is running, its status-item scene registered, Parakeet V3 prewarm completed in 0.21 seconds, and its entitlements digest exactly matches build 230.
- Human visual QA then established that build 231 still had no identifiable menu-bar control. Build 232 retains the native `text.cursor` mark and adds the explicit word `Syll` beside it so the menu-only control surface is unmistakable. No dictation-path code changed. Build 232 is installed and running; its status-item scene registered and Parakeet V3 prewarm completed in 0.22 seconds.
## Identity correction hold — 2026-09-09 12:09 SAST

- Human evidence: build 232 is functionally working, but its visible `text.cursor` + `Syll` menu-bar treatment is rejected.
- Human evidence: the black microphone/nib application icon visible in Spotlight in `IMG_2444.HEIC` is rejected.
- Prior human evidence: the blue microphone/nib application artwork visible in `IMG_2442.HEIC` was also rejected; it must not be treated as the desired app identity.
- Preserved visual evidence: `build/syll-qa/repaired-218-menu.png` shows the earlier standalone microphone menu-bar mark. This is evidence for the prior menu-bar presentation, not authority to install it.
- Safety decision: freeze the working build 232 installation and dictation path. Do not install another identity candidate until both the menu-bar mark and app icon are matched to direct human/reference evidence.
- Open question: the exact desired application icon has not yet been recovered from a proven artifact.

## Approved identity recovery — 2026-09-09

- David explicitly selected the orange rising-bars-and-vertical-stroke mark on a navy rounded square. It is recovered from the archived Syll build-221 icon bundle and is the sole approved Syll application identity.
- A prior inventory mislabeled this mark as build 229. The source was corrected before any installation: it is build 221–228, while build 229 is a forbidden blue microphone/nib variant.
- The approved macOS-rendered asset SHA-256 is `590b1986b8b1c5e4d07c926acd50cb8bdf50f0e94737253e6c47005f28a0de23`.
- A versioned AppIcon asset catalogue now supplies that one artwork at every macOS icon size. The Apple Development build script no longer copies an icon from `/Applications/Syll.app`, eliminating the stale-installed-icon path that caused mixed identity bundles.
- The menu-bar mark is the same three rising bars plus vertical stroke rendered as a monochrome template; all microphone, pen-nib, four-bar, `text.cursor`, and text-label marks are forbidden.
- An unsigned, uninstalled candidate compiled successfully. Both its AppIcon container and asset catalogue render the approved orange mark at 256 px. `/Applications/Syll.app` remains build 232 and was not stopped, replaced, signed, launched, or otherwise modified.

## Approved identity cutover — build 233

- Build 233 was compiled from the proven Phase 1 recovery source, not from the incomplete generic `app/` checkout. The recovery source contains the accepted Fn shortcut state machine, local Parakeet V3-only runtime, state-only compact HUD, persistence-before-delivery behavior, and cursor-paste recovery path.
- Its only source delta is `SyllMenuBarMark`: the rejected `text.cursor` plus text label was replaced by the selected three rising bars and vertical stroke template. The only asset delta is the locked `AppIcon.appiconset`.
- The staged and installed `AppIcon.icns` both render to SHA-256 `590b1986b8b1c5e4d07c926acd50cb8bdf50f0e94737253e6c47005f28a0de23` at 256 px.
- Build 233 passed deep/strict signature verification with `Identifier=capital.underbite.syll` and `TeamIdentifier=A635S52367`; its entitlements exactly match build 232.
- Before replacement, working build 232 was preserved at `build/recovery-archives/Syll-build232-pre-orange-working.zip`, SHA-256 `4001166fe268411e0f714b1b3353cc219d436fd556c90c63ad4477c8f85b8ee0`.
- `/Applications/Syll.app` now contains build 233. Launch Services registered the bundle, and one process is running from `/Applications/Syll.app/Contents/MacOS/Syll`.
- Syll remains a menu-only app (`LSUIElement=true`), so no Dock icon is expected. Its visible control surface is the required menu-bar icon.
- The Apple Development build script now rejects any source tree that lacks `SyllPhase1Runtime`, preventing a generic upstream checkout from being packaged as a Syll recovery build. It also builds the app icon only from the locked versioned asset catalogue and never copies an installed icon.

## Native menu-bar rendering correction — build 234

- Human visual QA showed that build 233's SwiftUI `Canvas` label did not render visibly in the macOS menu bar, even though its menu scene was inserted and transcription continued to work.
- Build 234 changes only that label implementation: the same approved three-bars-and-vertical-stroke geometry is now drawn into an AppKit `NSImage` marked as a status-item template. This avoids the Canvas transparency path; no Fn, recorder, ASR, model, persistence, paste, permission, identity, entitlement, or application-icon logic changed.
- Build 233 is preserved at `build/recovery-archives/Syll-build233-pre-native-menu-working.zip`, SHA-256 `3678f4c29444820ad3525199d477decfaf1c7e9ccf2741151c2eaff22085d68c`.
- `/Applications/Syll.app` now contains signed build 234 and its process was relaunched after Launch Services registration.
