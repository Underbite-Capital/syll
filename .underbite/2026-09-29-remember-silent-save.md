# Remember silent success, build 248

Installed for QA. Product source `6b953da` on `candidate/remember-observations`.
Build 248, `capital.underbite.syll`, Team `A635S52367`, executable SHA-256
`d55aa2654a12bb9cfcf2555ce2da0df5f0121f9ed14bbbcb241cc1079e0884da`.
Rollback: `build/recovery-archives/Syll-build247-pre-248-working.zip`
(SHA-256 `c81ec3e136d39c03a6d3bc20cbc146dcfe78aa571d341a9b94bc7878007fe396`;
archived executable verified as build 247). Prior bundle retained at
`/Applications/.Syll-build247-pre248.app`.

A successful Remember capture dismisses the violet pill and shows nothing
else. Transcription or save failure still posts a compact error notification
and keeps audio under `Observations/Failed`. The menu title is
`Observations` or `Observations (N)` and opens the existing window.

Agent interface: `tools/observation-closeout/README.md` and
`tools/observation-closeout/observations.py` (`list`, `list --new`,
`list --all`, `respond`, `import-responses`, `correct`). Responses never
set `addressed`.

Usage: `python3 tools/syll-usage/usage.py`. Ordinary dictations are completed
operational-session records; Remember captures are observation records;
day boundary is Africa/Johannesburg. Counts stop at retention.
