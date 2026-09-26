# Local recognition study (research, not product acceptance)

Date: 2026-09-26. Product source examined: `main` at
`478886e58ba396ce114dcb6f4f86f958cc5b6644`, prepared with
`./scripts/prepare-app.sh --core-only` in an isolated clone. FluidAudio is
pinned to `c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7`. The root `app/`
submodule and installed Syll were not modified.

## Observed effective path

Ordinary dictation stops and drains the CoreAudio recorder on Fn release. It
then sends the recorded file through `FluidAudioTranscriptionService` to
`AsrManager(config: .default)` with int8 Parakeet TDT 0.6B v3, a fresh
decoder state and an English script hint. The service returns a
`TextNormalizer` result. The pipeline filters/optionally formats that text,
then runs Syll's deterministic cleaner followed by Personal Dictionary
correction. Neither `ASRConfig` nor the selected `AsrManager.transcribe` API
accepts personal vocabulary. The raw TDT text is discarded before the
persisted `Transcription` record. That record already carries a UUID,
timestamp, model name, audio duration and total transcription duration; its
`text` is the cleaned/corrected result.

Source: pinned [upstream Syll service](https://github.com/Beingpax/VoiceInk/blob/3c211dab63454f18cf3f8b58750ec6bf3f5b4d17/VoiceInk/Transcription/FluidAudio/FluidAudioTranscriptionService.swift), root [core patch](../patches/core.patch) and [Syll runtime overlay](../overlays/core/VoiceInk/Transcription/Engine/SyllPhase1Runtime.swift), and pinned [FluidAudio TDT API](https://github.com/FluidInference/FluidAudio/blob/c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7/Sources/FluidAudio/ASR/Parakeet/SlidingWindow/TDT/AsrManager.swift). The prepared source was inspected in a disposable clone; durable composition remains the root sources at the revision above.

## Short audio mechanics

Pinned FluidAudio rejects audio below 0.3 s. Accepted clips up to 15 s are
aligned to 80 ms encoder frames, zero padded to the model's 15 s input size,
and passed to the preprocessor with their actual audio length. The TDT decoder
also exits if the encoder has at most one frame. The 0.3 s guard normally
makes that narrower decoder guard unreachable for valid input. Long-audio
chunking, overlap and seam repair do not run on these short clips. Syll uses
manual Fn release as its endpoint and the recorder drains queued audio before
closing the file. This inspection does not establish whether a particular
human clip starts late or ends early; that requires the recorded-file duration
and explicit failure evidence. Punctuation and sentence casing are produced
or changed after TDT and should not be mistaken for acoustic recognition.

Primary source: pinned [ASR constants](https://github.com/FluidInference/FluidAudio/blob/c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7/Sources/FluidAudio/Shared/ASRConstants.swift), [single-clip transcription](https://github.com/FluidInference/FluidAudio/blob/c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7/Sources/FluidAudio/ASR/Parakeet/SlidingWindow/TDT/AsrManager%2BTranscription.swift), and [inference pipeline](https://github.com/FluidInference/FluidAudio/blob/c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7/Sources/FluidAudio/ASR/Parakeet/SlidingWindow/TDT/AsrManager%2BPipeline.swift).

## Realistic local options

| Option | What it changes | Latency and reliability status |
| --- | --- | --- |
| Keep TDT v3 plus explicit dictionary aliases | Only deterministic post-recognition repair | No extra inference. Does not rescue a genuinely new phonetic error unless an alias matches. |
| CTC vocabulary rescoring | Runs a separate Parakeet CTC 110M encoder on the audio, spots bounded terms in CTC probabilities, aligns them with TDT token times and compares candidate versus original CTC scores | Compatible with v3 but is a second acoustic inference and replacement stage. The v3 model has no built-in CTC head. CTC model is absent from this Mac; local end-to-end latency and false substitutions are unmeasured. |
| TDT-CTC-110M hybrid | Uses a smaller, materially different base ASR model with a shared CTC head | Could avoid the second encoder, but changes the base recognizer and its raw quality. Not a safe drop-in for the accepted v3 path without real corpus evidence. |
| Transcribe while Fn is held | Uses the existing FluidAudio streaming/session machinery to move some work before release | Could reduce apparent release delay but changes the accepted batch path and has a startup audio gate with possible dropped chunks. It does not supply terminology context by itself; no same-audio quality or end-to-end timing evidence yet. |
| Short-clip silence or language-hint adjustment | Modifies only the input boundary or script filter | Cheap, but the small synthetic probe below showed no raw-word change. No defect proved. |

CTC is acoustic evidence for a *post-TDT* candidate replacement, not a
vocabulary input into the v3 decoder. Pinned FluidAudio provides string
similarity, length-ratio, short-word and stopword guards plus CTC score
comparison. Those guards are useful but do not make replacement semantically
safe. Its non-mutating candidate-evidence API could support a later stricter
arbiter. A reported 25.98x speedup and ~130 MB peak for v3 plus separate CTC
are upstream's iPhone measurement, not this Mac's release-to-paste result.
Pinned `CtcModels.swift` also warns that greedy decoding of its auxiliary
CTC 110M head has very high WER, so using the CTC output alone is not a
quality shortcut.
The pinned documentation's short `AsrManager.transcribe(customVocabulary:)`
example is not an overload in the pinned TDT manager; the actual APIs are the
CTC spotter/rescorer and the separate sliding-window manager configuration.

Primary source: pinned [FluidAudio CTC design and benchmarks](https://github.com/FluidInference/FluidAudio/blob/c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7/Documentation/ASR/CustomVocabulary.md), [rescorer](https://github.com/FluidInference/FluidAudio/blob/c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7/Sources/FluidAudio/ASR/Parakeet/SlidingWindow/CustomVocabulary/Rescorer/VocabularyRescorer%2BTokenRescoring.swift), and the [CTC word spotter paper](https://arxiv.org/abs/2406.07096). FluidAudio itself documents short-term overfire risk; the CTC option needs negative examples as well as desired terms.

## Bounded mechanics probe

`tools/recognition-eval` compiles the exact maintained Syll cleaner/corrector
sources through links. The CLI uses the pinned v3 call and reports untouched
TDT text, strategy text, normalization, dictionary/cleanup output, elapsed
release-stage inference time (models loaded before timing), source-audio
duration and standard realtime factor = latency / audio duration. It can
also run CTC if the separate model is already installed, without downloading
it. The offline build used the exact pinned FluidAudio source, changing only
the disposable copy of `Package.swift` to point to a previously cached
NemoTextProcessing artifact. The generated audio was macOS `say -v Alex -r
190`, not David's speech. No Syll app was launched.

| Synthetic clip / strategy | Audio | Raw TDT | Cleanup + dictionary | Inference | RTF |
| --- | ---: | --- | --- | ---: | ---: |
| “Shukuru.” / Syll core | 0.745 s | `Shukaru` | `Shukuru.` via supplied alias | 65.9 ms | 0.089 |
| Same audio / +250 ms silence | 0.745 s source | `Shukaru` | `Shukuru.` | 67.6 ms | 0.091 |
| “Please open the Shukuru project.” / Syll core | 1.823 s | `Please open the Shukiru project.` | unchanged | 72.1 ms | 0.040 |
| “Send the report.” / Syll core | 0.942 s | `Send the report.` | unchanged | 66.8 ms | 0.071 |

Removing the English hint also left `Shukaru` and `Shukiru` unchanged on
the same two clips (68.6 and 65.5 ms respectively). These single warm runs
show API mechanics and a failure shape, not a quality or latency distribution.
The raw error in the longer clip demonstrates that more surrounding words do
not guarantee the preferred name; the alias did not cover `Shukiru`.
The TTS engine may itself pronounce the scripted name differently from David,
so this is a correction-path demonstration rather than a scored recognition
error against human speech.
On this Mac `CtcModels.modelsExist` is false for CTC 110M, so no CTC latency,
accuracy or overfire result is claimed. The CLI exits explicitly rather than
fetching it.

Fixture SHA-256: short name `bcc87b2e639327a9b89e7863af8cddc6ef4e43bc4d059897dbc8d64df5a566ea`;
context name `1bced5ef94ed57a5b6541c84b9b5ec9995d778c6012b5688d6247a8a3e7b671a`;
ordinary short `d4792571f103d7c58428796441108202efa1bfb2a58852c4892d38c9a11c19b8`.
Fixtures and individual run JSON were kept in ignored local `build/` only.

Mechanical checks on the prepared 478886e product source: core overlay
metadata verification passed; `xcodebuild ... build` reported `BUILD
SUCCEEDED`; `xcodebuild ... build-for-testing` reported `TEST BUILD SUCCEEDED`
without running the app-hosted tests. The evaluation CLI release build
completed and its core/silence/no-hint strategies ran on the clips above.
The CTC strategy compiled and exited with a clear missing-local-model result.
Xcode printed CoreDevice/iOS Simulator warnings, but the macOS build gates
succeeded. No user-facing runtime or human recognition result was tested.

## Explicit failure evidence seam

The minimum association is the existing transcription UUID and timestamp,
the raw TDT result before normalization, the final persisted text, model/path,
measured recognition duration, and the later correction supplied explicitly
by David. No ordinary microphone audio or typing observation is necessary.
The existing `Transcription` row already has all but the raw result and exact
path marker; `transcriptionDuration` is wider than model inference. A bounded
local diagnostic record could be attached to a completed ordinary dictation,
limited to recent entries and an expiry, with export only on an explicit
failure action. Implementing that now would change SwiftData schema, retain
an additional copy of sensitive dictated text, and require a clear retention
and deletion surface. Those are product/privacy decisions, so no runtime
diagnostic substrate was added in this research pass. The evaluation tool
keeps its own raw output separate without changing ordinary use.

## Recommendation and gate

Keep the current recognition path for the next install decision. The smallest
*research candidate* is a local, opt-in CTC rescore comparison on a small set
of David-supplied failures plus matched ordinary/near-sounding negatives,
using the evaluation CLI and a bounded vocabulary. Measure total warm and
cold release-to-text latency, raw TDT errors, rescued terms and overfires on
the same audio. Only a demonstrated net gain within the essentially immediate
interaction budget should lead to a new Syll build. Do not treat this study or
synthetic fixtures as human acceptance or a reason to install anything now.
