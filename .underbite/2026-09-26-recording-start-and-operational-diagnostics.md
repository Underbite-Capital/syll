# Syll recording-start investigation and diagnostic candidate

Status: implementation candidate; no installed app or human acceptance. Source base: `main@84c8f67f687a08df4fa9a7b88b91d4172db3a2a5`, pinned VoiceInk `3c211dab63454f18cf3f8b58750ec6bf3f5b4d17`.

## Human observation and distinct hypotheses

David reports that short recordings often miss the first word or two. This is distinct from domain-term recognition errors. It could arise before the recording file exists, from dropped callbacks or writes, or from TDT recognition on a complete file. The offline recognition evaluator starts with an already complete file and cannot distinguish these cases.

## Source-observed live path

1. `RecordingShortcutManager` receives a Fn shortcut event and asynchronously toggles `RecorderUIManager`.
2. The panel becomes visible and the start sound plays before `VoiceInkEngine.toggleRecord` enters `.starting` and before hardware capture is ready.
3. Preflight and device resolution run, then `Recorder.startRecording` queues `CoreAudioRecorder.startRecording` onto its serial audio setup queue. It may reuse a prepared AUHAL, or initialize it when the device/preparation is stale. It creates the output WAV, resets its processing ring, then calls `AudioOutputUnitStart`.
4. `CoreAudioRecorder` accepts callbacks only while `recordingActive` is true. The callback renders audio and enqueues it into the ring. Capacity or backpressure can drop a buffer; existing counters report these drops. The processing queue writes 16 kHz mono PCM to the file. No startup silence gate or VAD removes samples from this file path.
5. `VoiceInkEngine` sets `.recording` after `Recorder.startRecording` returns, without waiting for the first accepted callback. The HUD distinguishes `.starting` and `.recording`, but the early start sound precedes actual readiness.
6. Releasing Fn while `.starting` calls cancellation and may end the session before useful capture. Speech spoken during preflight/hardware setup cannot be in the WAV. Releasing after `.recording` stops AUHAL and drains the processing queue before file closure.
7. Ordinary Parakeet V3 receives the complete recorded file URL through `AsrManager.transcribe(audioURL, decoderState:, language:)`. Syll applies text normalization/cleanup after recognition; no Syll-side head trim was found. Model loading/prewarming is launched after recorder start, so prewarming does not make the microphone ready sooner in this path.

These are source facts, not a measurement of David's actual startup interval or proof that the missing words were absent from his WAV. The strongest live-capture hypothesis is that he begins speaking between the early cue and the first accepted buffer. A separate full-file recognizer error remains possible.

## Candidate evidence

The candidate records, for ordinary completed dictations only, the shortcut handler time, recorder start request, AUHAL start return, first accepted buffer, first buffer above a -45 dBFS peak threshold, written frame count, dropped buffer count, audio duration, and inference duration. Early ordinary cancellation while `.starting` gets a separate event. The threshold is a diagnostic proxy for speech, not speech detection or ground truth. The shortcut timestamp is when the app handler ran, not a hardware timestamp for the physical key.

Operational timing JSON files contain no transcript or audio and are capped at 500 entries or 30 days in `~/Library/Application Support/Syll/OperationalSessions/`. They are keyed by transcription UUID for completed sessions. Separately, David's explicit authorization for local operational logging permits the ordinary corpus at `~/Library/Application Support/Syll/FailureEvidence/ordinary/<UUID>/`: exact WAV plus raw TDT and final text, capped at 100 sessions, 24 hours, and 512 MiB. The menu can mark only the latest completed ordinary dictation for five minutes; marking moves its existing directory into `marked/<UUID>/`, capped at 20 entries or 30 days. The menu provides a confirmed delete-all for both stores. This is operational evidence, not a user-facing History product.

Because cleanup can remove the original WAV synchronously on completion, copying the audio occurs after transcription is saved but before the existing completion notification. At the 100-session count cap, the standalone test copied and indexed a synthetic one-minute 16 kHz mono file in about 7-9 ms; actual device/load conditions remain unmeasured. Raw capture adds one in-memory assignment and monotonic timestamp after the already-required TDT inference. Operational timing JSON is written after delivery returns.

## Next evidence gate

On an approved installed build, compare the operational start interval and WAV beginning for a real missed-first-word report. If the word is absent from the WAV, repair the live start cue/readiness contract. If it is present in the WAV but absent from raw TDT output, evaluate recognition on that exact audio through the existing harness. No CTC path has been added to Syll's runtime. No later typing or edit is observed.
