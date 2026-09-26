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

## Explicitly marked real failures

Syll keeps marked failures outside the repository at
`~/Library/Application Support/Syll/FailureEvidence/marked/<transcription UUID>/`.
Each directory contains `failure.json` and the exact copied WAV. Enumerate it
without importing private audio into Git:

```sh
python3 tools/recognition-eval/list-marked-failures.py
```

The JSONL output gives an `audioPath` for each failure. Pass the same path to
the evaluator with no strategy option for baseline TDT, then with
`--ctc-rescore --dictionary <explicit-local-dictionary.json>` only if the
separate CTC model is installed. Compare raw transcripts before deterministic
correction. A marked failure is evidence of a bad user experience, not a
ground-truth corrected transcript. The metadata records what the shipping path
produced.

David also authorized a bounded ordinary-session corpus under the sibling
`ordinary/` directory for 24 hours or 100 sessions (at most 512 MiB). The same
enumerator can inspect it using `--corpus "$HOME/Library/Application Support/Syll/FailureEvidence/ordinary"`.
These records are operational data, not accepted corrections. Both corpora can
be deleted from Syll's Diagnostics menu. Do not copy their private WAV or JSON
files into this repository.
