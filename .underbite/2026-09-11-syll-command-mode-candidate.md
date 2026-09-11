# Syll deterministic Command Mode candidate

Date: 2026-09-11
Status: **OPEN / NOT ACCEPTED / NOT VERIFIED.** Implementation and mechanical verification exist, but the current candidate failed human QA. Do not infer a product PASS from tests, compilation, signing, installation or launch.

## Product boundary

- Hold Fn retains ordinary dictation: record while held, transcribe, persist and paste at the cursor.
- Double-tap Fn latches Command Mode; a later Fn tap stops it.
- Command audio is transcribed through the same exact local Parakeet V3 runtime, but command transcripts are neither persisted nor pasted.
- Interpretation is normalization followed by exact finite matching and typed argument validation. Unmatched and invalid transcripts execute nothing.
- Slice 1 contains inspect/kill port, git status/copy branch, open localhost and the IQS staging alias. It contains no LLM routing, arbitrary shell, chaining, macros, editor, analytics or cloud service.
- The HUD reports Heard, Interpreted and the actual result or failure, then dismisses after four seconds.

## Source and execution boundary

- Root overlays and `patches/syll-command-mode.patch` are the maintained source. The dirty generated `app/` subtree was not reconciled or changed.
- Gesture policy stays in the existing hybrid Fn shortcut handler. Its physically proven second-tap branch marks the active primary recording as Command Mode; there is no parallel gesture state machine.
- Typed commands, normalization/matching, context capture and recipes live under `overlays/core/VoiceInk/Commands/`.
- Recipes invoke only fixed `/usr/sbin/lsof` and `/usr/bin/git` executables with argument arrays; transcript text is never interpolated into a shell command.
- Port killing is limited to one distinct current-user listener, refuses Syll's own PID, sends SIGTERM only and verifies the resulting listener state.
- Repository context is fail-closed and portable: Syll reads the focused window's local `kAXDocumentAttribute`, canonicalizes it and walks ancestors to the nearest `.git`. There is no username, workspace-root, title, clipboard or process-CWD fallback.
- Navigation success means only that macOS accepted the open request; the HUD does not claim that a destination loaded.
- The minimum accepted-runtime source reconciliation is carried in the same composition patch: exact local Parakeet V3 selection, deterministic cleanup, completed ordinary dictation persistence before paste, and clipboard restoration only after a paste event was posted. Restoring a separate historical build tree was not required because the pinned upstream plus root overlay/patch composition is sufficient to compile and test this slice while encoding those accepted invariants.

## Verification evidence

The following results are mechanical evidence only. They do not establish that Command Mode works in live use and do not override the failed human-QA result.

- Deterministic cleanup tests: PASS.
- Existing recorder HUD policy tests: PASS.
- Command registry and spoken port parsing tests: PASS.
- Hybrid Fn integration is source-verified to recognize Apple keyboard companion keycode 179, use a 500 ms double-tap interval and contain no parallel `SyllFnGestureStateMachine`: PASS.
- Repository context tests using a temporary generic repository: PASS.
- Bounded executor tests using a disposable listener and temporary git repository: PASS; the test inspected and SIGTERM-stopped only its own listener and verified the port became free.
- Project metadata, full/core overlay verification and `git diff --check`: PASS.
- Clean isolated patch composition: PASS.
- Unsigned arm64 Debug build with `LOCAL_BUILD`: PASS (`** BUILD SUCCEEDED **`).
- The original pre-install candidate executable had SHA-256 `eae89bae0ef3ef27c83f71521027de5206a560321b3cfed4223825f53e82cdb3`; its outer bundle and main executable both reported `code object is not signed at all` before QA authorization. The disposable candidate was removed at wind-down.
- HUD rendered from the actual `SyllCommandOutcomeView` without launching Syll and was visually inspected: PASS for legibility, compact layout and no clipping/overlap. Durable render-only evidence: `evidence/command-mode-hud-success.png`, SHA-256 `f03b4ec97406ee7d179c755995e994e55b7145304f3b21428d9bc89ab7bab7d1`.

## Authorized QA installation

- David authorized the separate sign/install/launch QA step on 2026-09-11.
- Accepted build 234 was quit normally and archived before replacement at `build/recovery-archives/Syll-build234-pre-command-mode.zip`; its exported preferences are beside it. Archive integrity and preference plist validation passed.
- The exact composed product was restaged as Syll build 235 with bundle identifier `capital.underbite.syll`, signed by Apple Development Team `A635S52367`, and passed deep/strict signature verification.
- Installed executable: `/Applications/Syll.app/Contents/MacOS/Syll`; SHA-256 `db7118d5fe5bf3f2b8f919c32f653f707138bd751037c7670763d753054d5f58`.
- Build 235 launched as `capital.underbite.syll` and remained alive through the launch observation window. System logs contained framework/environment diagnostics (AudioToolbox factory registration, ANE subtype, detached-signature SQLite path, audio analytics disconnect and SelectedTextKit unable to read selected text); none terminated the app, but they are not represented as a clean-log result.
- A second unpacked rollback copy of build 234 was kept in `/private/tmp` during QA and removed at wind-down; the durable ignored recovery archive remains under `build/recovery-archives/`.

## Human/runtime boundary

Physical Fn delivery, live microphone/ASR output, command interpretation and execution are human-QA boundaries. They are not verified by the mechanical checks above. Build 239 failed this boundary and the lane was deliberately stopped without another repair.

## Human QA failure and correction

- Human QA found build 235 had no visible menu-bar icon and double-tapping Fn did not latch Command Mode. Ordinary transcription still worked.
- Runtime logs confirmed rapid taps started and discarded ordinary recordings rather than latching a command.
- Build 235 was removed immediately and proven build 234 restored while correcting the source.
- The trigger fix deletes the parallel `SyllFnGestureStateMachine` and extends the existing physically proven hybrid handler: its established second-tap branch now marks the active primary recording as Command Mode. Hold and single-tap behavior remain on the accepted handler.
- Binary comparison found the icon source had drifted: rejected build 235 used eager `lockFocus()` rendering while build 234 contains a lazy AppKit drawing-handler property named `statusImage`. `syll-recovery.patch` now reproduces that accepted lazy native mark, and overlay verification locks its defining source tokens.
- An attempted build 236 packaging reconciliation renamed the Debug dylib but could not update Xcode's private `__debug_dylib` section; it failed its guarded launch check and was automatically rolled back before QA. It was never presented as a usable build.
- Build 237 retained the working Debug dylib layout, contained the lazy `statusImage`, exactly matched the accepted application-icon hash, passed deep/strict signing verification and launched successfully. Its installed executable SHA-256 was `6f4cb6d29cc126b4bdbbc241b799559a58fafe5551825a60ce195ba93db77267`.
- Build 234 remains in the verified ignored recovery archive. Its temporary unpacked `/private/tmp` copy was removed at wind-down.
- Human QA of build 237 confirmed the menu-bar icon, Copy Last Transcription and ordinary transcription work. Command Mode could latch only with an impractically fast double-tap, and `what's on port 3000` reached interpretation but did not match.
- Temporary diagnostic build 238 established the gesture cause: Apple keyboard Fn/Globe emits companion key-down 179 only 28–88 ms after Fn, and the shortcut monitor treated it as an interruption. The maintained shortcut source now recognizes 179 as a modifier keycode, and the double-tap interval is 500 ms.
- Command normalization now canonicalizes curly apostrophes to ASCII apostrophes and accepts correctly grouped spoken/transcribed digits such as `3,000` while rejecting malformed grouping such as `3,00`.
- The final clean composition and focused registry tests pass. Project validation, core overlay verification, `git diff --check`, and the clean unsigned Debug build pass (`** BUILD SUCCEEDED **`).
- Build 239 was signed with the authorized Apple Development identity, passed deep/strict signature verification, installed at `/Applications/Syll.app`, launched successfully and is running. Installed executable SHA-256: `74cb402ce9dfab5fc2962c98a7000a32697cae8e27233456bae7bd76eecdcd2c`.

## Final human-QA result for this lane

- Command Mode implementation exists and is worth continuing.
- The current candidate does not work correctly in human QA.
- The double-tap/command interaction reached the HUD, but the spoken command was not interpreted correctly.
- Observed example: “What’s on port 3 thousand?” produced an invalid-port interpretation instead of executing `inspect-port(port: 3000)`.
- Therefore Command Mode remains **OPEN / NOT ACCEPTED / NOT VERIFIED**. No command family has product-level acceptance from this session.
- Earlier human observations that the menu-bar icon, Copy Last Transcription and ordinary transcription worked are narrow observations only; they do not accept Command Mode or establish complete hold-to-dictate regression coverage.

## Known issue and next investigation

Observed fact: live ASR can produce a mixed digit-and-scale port phrase (`3 thousand`) that the current registry reports as invalid.

Source fact: `SpokenPortNumber` currently accepts all-word scale forms such as `three thousand` and numeric/grouped forms such as `3000` and `3,000`; its tests do not cover mixed forms such as `3 thousand`.

Inference to verify, not a proven root cause: the live HUD failure is consistent with that uncovered parser boundary. A fresh agent should first capture the exact Heard string, feed that exact string into a failing registry regression test, and inspect normalization/parser input before changing gesture, transcription or execution code. If the exact Heard value differs, follow the observed value rather than broadening the parser speculatively. Re-run focused registry tests and then repeat direct human QA; mechanical PASS remains insufficient.

## Durable resume inventory

- Maintained implementation: `overlays/core/VoiceInk/Commands/`, `overlays/core/VoiceInk/Transcription/Engine/SyllPhase1Runtime.swift`, recorder protocol/HUD overlays, and `patches/syll-command-mode.patch`.
- Integration and safety checks: `scripts/prepare-app.sh`, `scripts/verify_overlay.py`, command registry/context/executor tests, and `.github/workflows/validate-project.yml`.
- Render-only HUD evidence: `evidence/command-mode-hud-success.png`. It proves only that the actual outcome view rendered legibly; it does not prove live command behavior.
- Accepted pre-command rollback artifacts remain ignored under `build/recovery-archives/`, including `Syll-build234-pre-command-mode.zip` and its preferences export. They are not part of this commit.
- The generated `app/` submodule was already dirty before this lane and remains intentionally untouched and excluded from the checkpoint commit.
- Disposable `/private/tmp` compositions, derived builds, diagnostic apps, logs and test binaries from builds 235–239 were removed when winding down. No additional build was installed or launched.

No action needed from David. Resume only when choosing to reopen Command Mode investigation.
