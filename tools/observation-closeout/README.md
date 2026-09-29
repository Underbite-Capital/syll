# Remember observations — agent interface

Local only. No network, server, or credentials. Do not edit
`~/Library/Application Support/Syll/Observations/*.json` by hand; use this
tool so review fields stay valid.

```sh
python3 tools/observation-closeout/observations.py list
python3 tools/observation-closeout/observations.py list --new --json
python3 tools/observation-closeout/observations.py list --all --json
python3 tools/observation-closeout/observations.py respond \
  --id OBSERVATION_ID --response "…" --disposition answered|proposal|unresolved
python3 tools/observation-closeout/observations.py import-responses --file responses.json
python3 tools/observation-closeout/observations.py correct --id OBSERVATION_ID --text "…"
```

Default `list` is outstanding work: `new`, `awaitingDecision`, and
`unresolved`. `--new` is captures with no response. `--all` includes
`reviewed` and `addressed`.

A response never sets `addressed`. Only David does that in the Observations
window. `proposal` stays `awaitingDecision`. `unresolved` stays outstanding.
`basisText` is the wording the response reviewed.

Day closeout uses the same store through the lighthouse-mac observations
adapter and this import path.
