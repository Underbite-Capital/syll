#!/usr/bin/env python3
"""Count today's Syll voice captures from local retained evidence.

Ordinary dictations: completed operational-session JSON files
(~/Library/Application Support/Syll/OperationalSessions), which exist only
for finished ordinary dictations. Remember captures: observation records
(~/Library/Application Support/Syll/Observations). Day boundaries are
Africa/Johannesburg. Counts are bounded by each store's retention; they are
not a complete lifetime history. No telemetry leaves the Mac.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, time, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

ZONE = ZoneInfo("Africa/Johannesburg")
OPS = Path.home() / "Library/Application Support/Syll/OperationalSessions"
OBS = Path.home() / "Library/Application Support/Syll/Observations"


def day_bounds(day: datetime.date):
    start = datetime.combine(day, time.min, ZONE)
    return start, start + timedelta(days=1)


def in_day(stamp: str, start: datetime, end: datetime) -> bool:
    try:
        when = datetime.fromisoformat(stamp.replace("Z", "+00:00")).astimezone(ZONE)
    except ValueError:
        return False
    return start <= when < end


def count_ordinary(root: Path, start: datetime, end: datetime) -> int:
    if not root.is_dir():
        return 0
    total = 0
    for path in root.glob("*.json"):
        if path.name.startswith("startup-"):
            continue
        try:
            record = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if record.get("transcriptionID") and in_day(record.get("timestamp", ""), start, end):
            total += 1
    return total


def count_remember(root: Path, start: datetime, end: datetime) -> int:
    if not root.is_dir():
        return 0
    total = 0
    for path in root.glob("*.json"):
        try:
            record = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if record.get("schemaVersion") == 1 and in_day(record.get("createdAt", ""), start, end):
            total += 1
    return total


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--date", default=None, help="YYYY-MM-DD in Africa/Johannesburg; default today")
    parser.add_argument("--ops", type=Path, default=OPS)
    parser.add_argument("--observations", type=Path, default=OBS)
    args = parser.parse_args()
    day = datetime.now(ZONE).date() if args.date is None else datetime.fromisoformat(args.date).date()
    start, end = day_bounds(day)
    ordinary = count_ordinary(args.ops, start, end)
    remember = count_remember(args.observations, start, end)
    print(f"Syll usage {day.isoformat()} (Africa/Johannesburg)")
    print(f"ordinary dictations: {ordinary}")
    print(f"Remember captures: {remember}")
    print(f"completed voice captures: {ordinary + remember}")
    print("Counts use retained local records only and stop at each store's retention cap.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
