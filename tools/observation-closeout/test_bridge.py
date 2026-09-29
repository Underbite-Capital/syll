#!/usr/bin/env python3
"""Bridge regression tests: outstanding semantics, proposal survival across
closeout reruns, validated response import, malformed-output retryability, and
correction staleness. Runs against a synthetic sandbox store only."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

TOOL = Path(__file__).resolve().parent / "observations.py"


def run(root: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess:
    result = subprocess.run(
        [sys.executable, str(TOOL), "--root", str(root), *args],
        capture_output=True, text=True)
    if check and result.returncode != 0:
        raise AssertionError(f"tool failed: {args}\n{result.stdout}\n{result.stderr}")
    return result


def make_observation(root: Path, suffix: str, text: str) -> str:
    observation_id = f"00000000-0000-4000-8000-{suffix.zfill(12)}"
    record = {
        "schemaVersion": 1,
        "id": observation_id,
        "createdAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "originalText": text,
        "text": text,
        "correctedText": None,
        "correctedAt": None,
        "audioFile": f"{observation_id}.wav",
        "audioDurationSeconds": 2.0,
        "model": "parakeet-tdt-0.6b-v3",
        "status": "new",
        "review": None,
    }
    (root / f"{observation_id}.json").write_text(json.dumps(record), encoding="utf-8")
    (root / f"{observation_id}.wav").write_bytes(b"RIFF")
    return observation_id


def read(root: Path, observation_id: str) -> dict:
    return json.loads((root / f"{observation_id}.json").read_text(encoding="utf-8"))


def main() -> int:
    root = Path(tempfile.mkdtemp(prefix="syll-bridge-tests-"))

    proposal = make_observation(root, "1", "Maybe the closeout should group by project.")
    question = make_observation(root, "2", "What should happen to the old spike repo?")
    concern = make_observation(root, "3", "I keep losing the first word on short dictations.")

    # All three start outstanding.
    out = run(root, "list").stdout
    assert out.count("outstanding") >= 1 and proposal in out and concern in out

    # Reviewer answers the question, proposes on the proposal, leaves the concern unresolved.
    responses = {
        "responses": [
            {"id": question, "response": "Keep it archived; it is evidence, not product.", "disposition": "answered"},
            {"id": proposal, "response": "Grouping is reasonable but needs your decision.", "disposition": "proposal"},
            {"id": concern, "response": "Confirmed against the corpus; still open.", "disposition": "unresolved"},
        ]
    }
    responses_file = root / "responses.json"
    responses_file.write_text(json.dumps(responses), encoding="utf-8")
    run(root, "import-responses", "--file", str(responses_file))

    # Regression: proposal awaiting decision and unresolved concern survive
    # the next closeout's outstanding read; the answered question does not.
    for _ in range(3):
        outstanding = json.loads(run(root, "list", "--json").stdout)
        ids = {r["id"] for r in outstanding}
        assert proposal in ids, "proposal awaiting decision dropped from outstanding work"
        assert concern in ids, "unresolved concern dropped from outstanding work"
        assert question not in ids, "answered question should leave the outstanding list"
        assert read(root, proposal)["status"] == "awaitingDecision"
        assert read(root, concern)["status"] == "unresolved"

    # Repeated import of the same responses does not duplicate history: one
    # review field per observation, updated in place.
    run(root, "import-responses", "--file", str(responses_file))
    assert isinstance(read(root, proposal)["review"], dict), "review duplicated or malformed"

    # Malformed reviewer output is rejected per entry and stays retryable.
    bad = {"responses": [
        {"id": "does-not-exist", "response": "ghost", "disposition": "answered"},
        {"id": concern, "response": "", "disposition": "answered"},
        {"id": concern, "response": "Still open after recheck.", "disposition": "unresolved"},
    ]}
    bad_file = root / "bad-responses.json"
    bad_file.write_text(json.dumps(bad), encoding="utf-8")
    result = run(root, "import-responses", "--file", str(bad_file), check=False)
    assert result.returncode == 1, "malformed entries must make the import report failure"
    concern_record = read(root, concern)
    assert concern_record["review"]["response"] == "Still open after recheck."
    outstanding = json.loads(run(root, "list", "--json").stdout)
    assert concern in {r["id"] for r in outstanding}, "unresolved concern must remain retryable"

    # Correction after review: original preserved, basisText keeps the
    # response attached to the old wording.
    run(root, "correct", "--id", proposal, "--text", "Maybe the daily closeout should group observations by project.")
    corrected = read(root, proposal)
    assert corrected["originalText"] == "Maybe the closeout should group by project."
    assert corrected["correctedText"] == "Maybe the daily closeout should group observations by project."
    assert corrected["review"]["basisText"] == "Maybe the closeout should group by project."
    assert corrected["review"]["basisText"] != corrected["correctedText"], "staleness must be detectable"
    # A corrected proposal still awaits the decision.
    outstanding = json.loads(run(root, "list", "--json").stdout)
    assert proposal in {r["id"] for r in outstanding}, "corrected proposal must stay outstanding"

    print("Bridge regression tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
