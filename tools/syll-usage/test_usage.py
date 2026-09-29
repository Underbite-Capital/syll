#!/usr/bin/env python3
import json
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

TOOL = Path(__file__).resolve().parent / "usage.py"
ZONE = ZoneInfo("Africa/Johannesburg")


def main() -> int:
    root = Path(tempfile.mkdtemp(prefix="syll-usage-"))
    ops = root / "ops"
    obs = root / "obs"
    ops.mkdir()
    obs.mkdir()
    today = datetime.now(ZONE).replace(hour=10, minute=0, second=0, microsecond=0)
    yesterday = today.replace(day=today.day) 
    # Use an explicit stamp inside today's Johannesburg day and one outside.
    inside = today.astimezone(ZoneInfo("UTC")).strftime("%Y-%m-%dT%H:%M:%SZ")
    outside = "2020-01-01T00:00:00Z"
    (ops / "a.json").write_text(json.dumps({"transcriptionID": "a", "timestamp": inside}))
    (ops / "b.json").write_text(json.dumps({"transcriptionID": "b", "timestamp": outside}))
    (ops / "startup-x.json").write_text(json.dumps({"event": "canceled-before-recording-ready", "timestamp": inside}))
    (obs / "c.json").write_text(json.dumps({"schemaVersion": 1, "id": "c", "createdAt": inside, "status": "new"}))
    (obs / "d.json").write_text(json.dumps({"schemaVersion": 1, "id": "d", "createdAt": outside, "status": "new"}))
    result = subprocess.run(
        [sys.executable, str(TOOL), "--date", today.date().isoformat(), "--ops", str(ops), "--observations", str(obs)],
        capture_output=True, text=True, check=True)
    text = result.stdout
    assert "ordinary dictations: 1" in text, text
    assert "Remember captures: 1" in text, text
    assert "completed voice captures: 2" in text, text
    print("usage count fixture passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
