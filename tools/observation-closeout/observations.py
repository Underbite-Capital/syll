#!/usr/bin/env python3
"""Remember observation closeout bridge.

Retrieves new and unresolved Syll observations and records a considered
review response against each original observation, without David copying
anything by hand. This is the retrieval/response half of the closeout loop;
the considered response itself comes from the reviewing agent or human.

The store is `~/Library/Application Support/Syll/Observations/` (override with
--root for tests). Each observation is `<id>.json` beside `<id>.wav`, written
by the Syll app. This tool never rewrites `originalText` or `text`; review and
correction are additive fields. It reads and writes only this directory.

Usage:
  observations.py list   [--root PATH] [--json]
  observations.py respond --id ID --response TEXT --disposition answered|proposal|unresolved [--responder NAME] [--root PATH]
  observations.py correct --id ID --text TEXT [--root PATH]
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

DEFAULT_ROOT = Path.home() / "Library/Application Support/Syll/Observations"
SCHEMA_VERSION = 1
AWAITING = ("new", "unresolved")
DISPOSITIONS = ("answered", "proposal", "unresolved")


def load_observations(root: Path) -> list[dict]:
    if not root.is_dir():
        return []
    observations = []
    for path in sorted(root.glob("*.json")):
        try:
            record = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if record.get("schemaVersion") != SCHEMA_VERSION or "id" not in record:
            continue
        observations.append(record)
    observations.sort(key=lambda r: (r.get("createdAt", ""), r["id"]))
    return observations


def awaiting_review(root: Path) -> list[dict]:
    return [r for r in load_observations(root) if r.get("status") in AWAITING]


def atomic_write(path: Path, record: dict) -> None:
    fd, tmp_name = tempfile.mkstemp(dir=path.parent, suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(record, handle, indent=2, sort_keys=True)
            handle.write("\n")
        os.chmod(tmp_name, 0o600)
        os.replace(tmp_name, path)
    except BaseException:
        try:
            os.unlink(tmp_name)
        except OSError:
            pass
        raise


def find_record(root: Path, observation_id: str) -> tuple[Path, dict]:
    path = root / f"{observation_id}.json"
    if not path.is_file():
        # Accept an unambiguous id prefix, since ids are long.
        matches = [p for p in root.glob("*.json") if p.stem.startswith(observation_id)]
        if len(matches) != 1:
            raise SystemExit(f"error: no unique observation matching {observation_id!r}")
        path = matches[0]
    record = json.loads(path.read_text(encoding="utf-8"))
    if record.get("schemaVersion") != SCHEMA_VERSION:
        raise SystemExit(f"error: unsupported schema in {path.name}")
    return path, record


def cmd_list(args: argparse.Namespace) -> int:
    pending = awaiting_review(args.root)
    if args.json:
        print(json.dumps(pending, indent=2, sort_keys=True))
        return 0
    if not pending:
        print("No observations awaiting review.")
        return 0
    for record in pending:
        text = record.get("correctedText") or record.get("text", "")
        print(f"[{record.get('createdAt', '?')}] {record['id']} ({record.get('status', '?')})")
        print(f"  {text}")
    print(f"\n{len(pending)} observation(s) awaiting review.")
    return 0


def cmd_respond(args: argparse.Namespace) -> int:
    path, record = find_record(args.root, args.id)
    record["review"] = {
        "respondedAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "responder": args.responder,
        "response": args.response,
        "disposition": args.disposition,
    }
    record["status"] = "unresolved" if args.disposition == "unresolved" else "reviewed"
    atomic_write(path, record)
    print(f"Recorded {args.disposition} review on {record['id']} (status: {record['status']}).")
    return 0


def cmd_correct(args: argparse.Namespace) -> int:
    path, record = find_record(args.root, args.id)
    record["correctedText"] = args.text
    record["correctedAt"] = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    atomic_write(path, record)
    print(f"Recorded correction on {record['id']}; original text preserved.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT)
    commands = parser.add_subparsers(dest="command", required=True)

    list_parser = commands.add_parser("list", help="List new and unresolved observations.")
    list_parser.add_argument("--json", action="store_true")
    list_parser.set_defaults(func=cmd_list)

    respond_parser = commands.add_parser("respond", help="Record a review response against an observation.")
    respond_parser.add_argument("--id", required=True)
    respond_parser.add_argument("--response", required=True)
    respond_parser.add_argument("--disposition", required=True, choices=DISPOSITIONS)
    respond_parser.add_argument("--responder", default="closeout-agent")
    respond_parser.set_defaults(func=cmd_respond)

    correct_parser = commands.add_parser("correct", help="Record a correction without losing the original text.")
    correct_parser.add_argument("--id", required=True)
    correct_parser.add_argument("--text", required=True)
    correct_parser.set_defaults(func=cmd_correct)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
