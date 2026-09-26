# Syll final surface and operational corpus candidate

Status: local implementation candidate for Supervisor review; no installation or human acceptance. Source base: `main@a119940f0b68463e6eb438e140425b6b71039414`, pinned VoiceInk `3c211dab63454f18cf3f8b58750ec6bf3f5b4d17`.

## Observed source and bounded policy

`CoreAudioRecorder` writes 16 kHz, mono, signed 16-bit PCM WAV: 32,000 audio bytes per second, about 1.92 MB per minute plus the WAV header. An ordinary 4 GiB audio cap holds about 2,237 minutes, or 37.3 hours of speech (about 75 minutes per day over 30 days), subject to the 3,000-session and 30-day limits. The newest sessions are retained; pruning evicts oldest sessions first. A single file above 64 MiB (about 35 minutes) is not staged so capture cannot monopolize the corpus or unboundedly delay delivery. The marked-failure area remains separately distinguishable, capped at 20 entries and 30 days; its per-file cap bounds it below 1.25 GiB. These are storage ceilings, not a guarantee of 30 days if use exceeds them.

`FailureEvidence/ordinary/<transcription UUID>/` stores a private-permission WAV and JSON with raw TDT text, final text, timestamp, model/path, duration and inference time. `OperationalSessions/<same UUID>.json` stores shortcut, recorder-start, first-buffer, above-threshold buffer, frame/drop, and pipeline timing; it has a 30-day, 5,000-file limit to cover the ordinary corpus plus startup cancellations. Mark Last moves the latest staged directory into `FailureEvidence/marked/` within five minutes. Delete All Local Diagnostic Evidence removes both local stores after confirmation. Nothing is uploaded or Git-tracked. No ordinary microphone audio is retained beyond this bounded local corpus by this subsystem.

## Surface decision

The normal menu has Copy Last Transcription, Reset Clipboard, Personal Dictionary, Launch at Login, a separator, Diagnostics, and Quit Syll. Diagnostics contains Mark Last Transcription as Wrong and Delete All Local Diagnostic Evidence. Ordinary mini recording uses a 138 × 43 point dark material capsule with one orange dot and nine orange bars, driven by the existing `Recorder.audioMeterSnapshot()` path. The capsule is rendered only for `.recording`, remains centered near the bottom in the existing mini panel, and fades as recording state leaves `.recording`. There is no button or text. The historical Command Mode/assistant panel rendering remains separate and unaccepted.

## Identity boundary

`reference/Syll-build221-AppIcon.icns` is the byte-exact approved orange **application** icon source (SHA-256 `a3cc8688e8ab6482fbd65458537703dc32d2f2d4e8f3c411c394f4012bc4b88f`). The icon register and 2026-09-09 handoff identify the approved build-233/234 **menu-bar** mark as a three-bars-and-stroke monochrome AppKit template. The handoff's old blob `fd19dc02f4e7cfc68b92e8e6042da3368335de83` is a VoiceInk microphone/nib image, not the orange Syll mark. The build-221 archive contains the application ICNS and `Assets.car` but no separately proven coloured status-item asset or rendering path. Therefore this candidate leaves the current menu-bar template unchanged rather than guessing a coloured treatment.

## Verification and remaining gate

The Foundation diagnostics test exercises private WAV/raw/final storage, marked distinction, 30-day expiry, count and byte eviction, timing log eviction, and delete-all. `tools/indicator-render/` renders the product SwiftUI view at quiet and speaking meter values without launching Syll; it also checks a larger bar response for the louder level. These mechanical results are not evidence of David's real speech or visual acceptance. The original recording-start instrumentation remains in place; a later real missed-word report must compare the WAV beginning with raw TDT output before changing recognition or the start cue. The existing optional notch presentation has not been redesigned in this candidate.
