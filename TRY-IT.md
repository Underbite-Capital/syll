# Try the local dictation spike

## Safety baseline

Before dictating into any chat composer, open **Modes**, edit the active/default mode, and confirm:

- Transcription model: **Parakeet V3**
- AI Enhancement: **OFF**
- Output: **Paste**
- Auto Send: **None**

This leaves the transcript at the cursor. Releasing push-to-talk must never submit it.

## First launch

1. Open `/Users/david/Downloads/VoiceInk.app`.
2. Complete VoiceInk's local-build onboarding.
3. Grant **Microphone** and **Accessibility** when macOS asks. Screen Recording is not required for this spike; leave screen context off.
4. In **AI Models → Local**, download **Parakeet V3**.
5. In **Audio**, choose **Selected Microphone**, click **Refresh Microphones**, and select **BOYA Magic 02**. Also verify the input meter in **System Settings → Sound → Input**.
6. In **Settings → Shortcuts**, set the primary shortcut to **Push to Talk** and choose a comfortable key.

## Import the spike configuration

1. Open **Settings → Backup → Import Settings → Import**.
2. Select `/Users/david/work/projects/david-voice-local-dictation/prototype/VoiceInk_David_Settings.json`.
3. Choose **Individual categories**.
4. Import **Dictionary** and **Custom Prompts** only.
5. Open **Dictionary** and confirm 26 vocabulary terms and 18 replacement groups are present.
6. Leave **Dictionary corrections** ON for normal use. Turn it OFF only for the paired comparison.

The source of truth is `dictionary.yaml`. After editing it, regenerate the import file from the project root:

```sh
python3 scripts/render_voiceink_dictionary.py
```

VoiceInk's import is additive: existing dictionary entries are preserved, and conflicting aliases are skipped.

## Shell smoke test

Use a harmless empty composer or scratch file. For each target, hold the shortcut, say “Do not submit this message when I release the hotkey,” release, then inspect the text without pressing Return.

| Check | Result |
| --- | --- |
| App launches | ☐ |
| Microphone permission | ☐ |
| Accessibility permission | ☐ |
| BOYA selected explicitly | ☐ |
| Push-to-talk records | ☐ |
| Text lands at cursor | ☐ |
| ChatGPT in Chrome | ☐ |
| Claude | ☐ |
| Cursor | ☐ |
| No release-to-submit behavior | ☐ |

Stop and record the blocker if this shell is not working within roughly 90 minutes.

## Corpus benchmark

1. Read the 20 lines in `evidence/test-corpus.md` naturally through the BOYA, one clip at a time.
2. Capture the raw output with **Dictionary corrections OFF** and **AI Enhancement OFF**.
3. Turn **Dictionary corrections ON**, use **Retry Last Transcription** where useful, and record corrected burden.
4. Download/select **Whisper Large V3 Turbo**, retry the same audio, and record its raw output.
5. Fill `evidence/benchmark.csv`.

Measure latency from hotkey release until the final transcript is ready/pasted. A phone stopwatch or screen recording is sufficient; consistency matters more than sub-millisecond precision. Score correction burden:

- `0`: send-ready
- `1`: one trivial fix
- `2`: several fixes or one important terminology error
- `3`: easier to re-dictate/retype

Choose the model with the lowest correction burden; use latency as the tie-breaker. Do not choose by generic WER.

## Optional cleanup

After the raw ASR + dictionary baseline is stable:

1. Configure a local enhancement provider (VoiceInk Refine, Ollama or Local CLI) if one is already available; otherwise an explicitly chosen cloud provider is permitted only for this optional pass.
2. In the active mode, turn **AI Enhancement ON** and select the imported **David cleanup** prompt.
3. Keep Output **Paste** and Auto Send **None**.
4. Compare prompts 11–20 with cleanup ON against prompts 1–10 OFF.

Any invented instruction, softened profanity or changed uncertainty is a cleanup failure. Turn cleanup OFF; the spike can still pass.

## Twenty real prompts

Use `evidence/20-prompt-trial.csv`. Alternate ChatGPT, Claude and Cursor. After prompt 20, answer only:

1. Prefer this, prefer Wispr Flow, or undecided?
2. What is the dominant pain: ASR, vocabulary, cleanup, latency or macOS interaction?
3. Is that pain one small fix, or a reason to stop?
