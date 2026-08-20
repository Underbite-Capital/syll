# Decision log

Append decisions; do not silently rewrite earlier entries.

## 2026-08-20 — Project orientation opened

- **Decision:** Begin two-lens commercial and technical research.
- **Basis:** New project scaffold.
- **Alternatives:** Not yet assessed.
- **Consequences:** Product scope and architecture remain open until synthesis.
- **Owner:** David.
- **Review / reversal condition:** Revisit after the Light diligence and runnable-shell check; superseded by the configuration-first and human-trial decisions below.

## 2026-08-20 — Runnable shell handed to human trial

- **Decision:** Treat successful local build and launch as shell readiness, not spike acceptance.
- **Basis:** The arm64 app built, passed deep signature verification and reached its permissions UI; live BOYA speech and cross-app insertion cannot be validated without David granting OS permissions and speaking.
- **Alternatives:** Grant security-sensitive permissions by automation; claim success from compilation alone.
- **Consequences:** The app and trial packet are ready, while accuracy, latency, cross-app behavior and Wispr Flow preference remain undecided.
- **Owner:** David.
- **Review / reversal condition:** Complete the bounded `TRY-IT.md` trial, or stop after the documented 90-minute shell bound.

## 2026-08-20 — Configuration-first VoiceInk path selected

- **Decision:** Use current VoiceInk main as the shell; compare its existing Parakeet V3 and Whisper Large V3 Turbo paths before considering another engine.
- **Basis:** Current source already implements the scoped macOS interaction, local models, dictionary, cleanup and cursor delivery surfaces.
- **Alternatives:** Build a new shell; integrate WhisperKit; add Voxtral via MLX.
- **Consequences:** Only a global dictionary toggle patch and import/trial artifacts are in scope. Voxtral and product work are deferred.
- **Owner:** David.
- **Review / reversal condition:** Reverse if the shell fails within 90 minutes or the BOYA/20-prompt trial shows local quality or latency is clearly unacceptable.

## 2026-08-20 — Human trial remains the acceptance gate

- **Decision:** A compile, launch or generic model benchmark cannot pass this spike.
- **Basis:** The supplied metric is David's correction burden and willingness to keep using the tool.
- **Alternatives:** Declare success from feature coverage or generic WER.
- **Consequences:** ASR winner, latency, app compatibility and Flow preference remain explicitly unknown until recorded.
- **Owner:** David.
- **Review / reversal condition:** None; this is the governing acceptance rule for the spike.
