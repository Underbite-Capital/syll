# Syll local recognition evaluation

This CLI calls the same pinned FluidAudio `AsrManager` file transcription path
as Syll's ordinary Parakeet V3 dictation: int8 v3 model, default ASR config,
fresh TDT decoder state, and English script hint. It reports the TDT result
before normalization, the text after any experimental strategy, inference
latency with models already loaded, audio duration, latency/audio-duration
realtime factor (lower is faster), and the reciprocal speedup. It compiles
Syll's maintained cleaner and dictionary corrector
via source links, then reports their output separately. The CLI does not paste,
run Syll.app, persist microphone audio, or read David's dictionary.

The `--ctc-rescore` strategy uses the pinned FluidAudio CTC word spotter and
rescorer after TDT. It requires a locally installed CTC 110M model and explicit
JSON vocabulary; it never downloads a model. This is a second inference stage.
The `--trailing-silence-ms` strategy probes an audio-boundary hypothesis and
is not the shipping path. Both compare against `syll-core` on the same source
audio. The output's `rawTranscript` always means the untouched TDT result.
`cleanupAndDictionaryText` applies Syll's cleaner and dictionary corrector to
the strategy text; it excludes the configurable filler filter and delivery.

From a clean clone with ordinary network access:

```sh
./tools/recognition-eval/make-synthetic-fixtures.sh
cd tools/recognition-eval
swift build -c release -debug-info-format none
SYLL_PRODUCT_SOURCE_REVISION=$(git rev-parse HEAD) \
  .build/release/syll-recognition-eval \
  --audio ../../build/recognition-eval-fixtures/shukuru-short.aiff \
  --dictionary ../../build/recognition-eval-fixtures/dictionary.json
```

For an offline build, set `SYLL_FLUIDAUDIO_SOURCE` to a local checkout and
verify it is exactly `c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7`.
SwiftPM also needs FluidAudio's pinned NemoTextProcessing binary artifact in
its cache. Save JSONL outputs outside Git; supplied audio may be private. The
generated synthetic clips are only API and latency probes. They are not a
benchmark of David's voice, microphone, accent, or real terminology errors.
