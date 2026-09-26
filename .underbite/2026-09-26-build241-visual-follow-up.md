# Build 241 initial human QA and visual follow-up

Status: visual-only source candidate for Supervisor review. Build 241 remains installed; this record does not authorize installation of a successor. Source parent: canonical `main@008f23a5b8033ba3b47f3dfc321b5de7d0d67ea2`.

## Human observation

David began a short Fn dictation immediately and reported that its opening was captured in this trial. This does not establish a repair of the historical first-word-loss problem; build 241 retained the start instrumentation and made no startup repair. The new pill appeared and responded to speech: functional responsiveness PASS for this observation. David rejected its visual size and treatment. He also reported that the unchanged menu-bar icon was neither improved nor restored to his preferred old orange mark: menu-bar identity FAIL / NOT DELIVERED.

## Build-241 material changes relative to build-239 source

The maintained build-239 composition is pinned upstream plus core overlays and patches through `syll-command-mode.patch`. Later source commits `31beec3`, `a119940`, and `008f23a` added latest-completed Copy Last recovery, cleanup-before-dictionary spelling authority, Reset Clipboard, the four-item everyday menu with Diagnostics and Quit, bounded ordinary WAV/raw/final and timing evidence, explicit Mark Last/Delete All actions, recording-start/first-buffer counters, and the initial live-meter pill. The Parakeet V3/TDT path, historical Command Mode/double-tap implementation, application-icon source, and monochrome menu-bar renderer remained unchanged. The offline recognition evaluator added by `84c8f67` is research tooling, not a runtime recognizer change. History's normal menu entry was removed; its underlying implementation was not deleted. None of the new menu/recovery/diagnostic behaviors is human accepted solely from this first trial.

## Exact pill gap and candidate

Build 241: 138 × 43 pt dark material capsule; 15 pt orange dot; nine orange bars, each 4 pt wide with 4 pt gaps; 27 pt waveform lane; 17 pt horizontal padding; 12 pt shadow radius. The approved visual target is approximately 64 × 22 pt, 8 pt dot, eight 1.5–3 pt bars, tighter spacing, and a small shadow. The original visible capsule occupied roughly 4.2 times the target area before its shadow.

The candidate changes only `SyllWaveformPill` drawing constants and the ordinary pill fade duration. It uses a 64 × 22 pt material capsule, 8 pt #FF8A00 dot, eight 2 pt live-meter bars with 2 pt gaps, 16 pt waveform lane, 9.5 pt side padding, 5 pt shadow radius, and 0.15 s entrance/0.25 s exit. The same `Recorder.audioMeterSnapshot()` closure, `.recording` gate, and low-centred mini-panel placement remain. Existing nonordinary Command Mode/assistant rendering is unchanged. Actual SwiftUI renders are under ignored `build/indicator-render-64x22/`; they are mechanical visual evidence, not human acceptance.

## Menu-bar identity evidence and boundary

The exact orange source is the build-221 application `AppIcon.icns`, retained at `reference/Syll-build221-AppIcon.icns` (raw SHA-256 `a3cc8688e8ab6482fbd65458537703dc32d2f2d4e8f3c411c394f4012bc4b88f`). Its 256 pt render has SHA-256 `590b1986b8b1c5e4d07c926acd50cb8bdf50f0e94737253e6c47005f28a0de23`. This proves application artwork, not prior status-item use. Build-221/223–227 `Assets.car` files contain `menuBarIcon.png` in *template* mode; the source blob `fd19dc02f4e7cfc68b92e8e6042da3368335de83` is a microphone/nib, not orange Syll artwork. Archived build-229 and build-230 source explicitly renders `Image("menuBarIcon").renderingMode(.template)`; build 231 uses monochrome `text.cursor`. Later root patches show four-bar and three-bar-and-stroke status marks as template drawings. The older follow-up plan requests using the orange application artwork for a future status item, but does not prove that treatment was historically installed. No exact historical coloured menu-bar treatment or low-risk rendering path has been proven. The visual candidate leaves the current menu-bar mark untouched for Supervisor's identity decision.
