#!/usr/bin/env python3
"""Remember observation closeout bridge.

Retrieves outstanding Syll observations and records considered review
responses against the original observation IDs, without David copying
anything by hand. This is the retrieval/response half of the closeout loop;
the considered response itself comes from the reviewing agent or human.

The store is `~/Library/Application Support/Syll/Observations/` (override with
--root for tests). Each observation is `<id>.json` beside `<id>.wav`, written
by the Syll app. This tool never rewrites `originalText` or `text`; review and
correction are additive fields. It reads and writes only this directory.

Status model: new -> reviewed (answered, nothing outstanding) |
awaitingDecision (proposal/question for David) | unresolved (concern still
open) -> addressed (David marks it; an agent response never does).
Outstanding work for closeout = new + awaitingDecision + unresolved.

This is the supported machine interface. Agents must not edit the JSON
store directly.

Usage:
  observations.py list [--new | --all] [--root PATH] [--json]
  observations.py respond --id ID --response TEXT --disposition answered|proposal|unresolved [--responder NAME] [--root PATH]
  observations.py import-responses --file responses.json [--root PATH]
  observations.py correct --id ID --text TEXT [--root PATH]

`list` (default) prints outstanding observations: status new,
awaitingDecision, or unresolved. `--new` is only status new. `--all`
includes reviewed and addressed history.

Each JSON record agents should rely on:
id, createdAt, originalText, text, correctedText, status, review
(response, disposition, basisText, respondedAt, responder).
`respond` and `import-responses` never set status addressed.

`import-responses` validates a reviewer-produced JSON file:
{"responses": [{"id": ..., "response": ..., "disposition": ...}, ...]}
Unknown IDs, bad dispositions and empty responses are rejected per entry and
leave those items outstanding (retryable); valid entries are persisted.
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
OUTSTANDING = ("new", "awaitingDecision", "unresolved")
DISPOSITIONS = ("answered", "proposal", "unresolved")
STATUS_FOR_DISPOSITION = {
    "answered": "reviewed",
    "proposal": "awaitingDecision",
    "unresolved": "unresolved",
}


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


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


def outstanding(root: Path) -> list[dict]:
    return [r for r in load_observations(root) if r.get("status") in OUTSTANDING]


def only_new(root: Path) -> list[dict]:
    return [r for r in load_observations(root) if r.get("status") == "new"]


def display_text(record: dict) -> str:
    return record.get("correctedText") or record.get("text", "")


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
            raise ValueError(f"no unique observation matching {observation_id!r}")
        path = matches[0]
    record = json.loads(path.read_text(encoding="utf-8"))
    if record.get("schemaVersion") != SCHEMA_VERSION:
        raise ValueError(f"unsupported schema in {path.name}")
    return path, record


def apply_response(root: Path, observation_id: str, response: str,
                   disposition: str, responder: str) -> dict:
    """Persist one validated review response. Returns the updated record."""
    if disposition not in DISPOSITIONS:
        raise ValueError(f"invalid disposition {disposition!r}")
    if not response.strip():
        raise ValueError("empty response")
    path, record = find_record(root, observation_id)
    record["review"] = {
        "respondedAt": now_iso(),
        "responder": responder,
        "response": response,
        "disposition": disposition,
        # The wording this response reviewed. A later correction makes the
        # response's relationship to the old wording explicit, never silently
        # attaching it to the new text.
        "basisText": display_text(record),
    }
    record["status"] = STATUS_FOR_DISPOSITION[disposition]
    atomic_write(path, record)
    return record


def cmd_list(args: argparse.Namespace) -> int:
    if args.all:
        pending = load_observations(args.root)
    elif args.new:
        pending = only_new(args.root)
    else:
        pending = outstanding(args.root)
    if args.json:
        print(json.dumps(pending, indent=2, sort_keys=True))
        return 0
    label = "observation(s)" if args.all or args.new else "outstanding observation(s)"
    if not pending:
        print(f"No {label.replace('(s)', 's')}.")
        return 0
    for record in pending:
        status = record.get("status", "?")
        print(f"[{record.get('createdAt', '?')}] {record['id']} ({status})")
        print(f"  {display_text(record)}")
        review = record.get("review")
        if review:
            print(f"  previous response ({review.get('disposition', '?')}): {review.get('response', '')}")
    print(f"\n{len(pending)} {label}.")
    return 0


def cmd_respond(args: argparse.Namespace) -> int:
    try:
        record = apply_response(args.root, args.id, args.response, args.disposition, args.responder)
    except ValueError as exc:
        raise SystemExit(f"error: {exc}")
    print(f"Recorded {args.disposition} review on {record['id']} (status: {record['status']}).")
    return 0


def cmd_import_responses(args: argparse.Namespace) -> int:
    try:
        payload = json.loads(args.file.read_text(encoding="utf-8"))
        entries = payload["responses"]
        if not isinstance(entries, list):
            raise ValueError
    except (OSError, json.JSONDecodeError, KeyError, ValueError):
        raise SystemExit("error: responses file must be JSON with a 'responses' array")

    applied, failed = 0, 0
    for index, entry in enumerate(entries):
        try:
            record = apply_response(
                args.root,
                str(entry["id"]),
                str(entry["response"]),
                str(entry["disposition"]),
                str(entry.get("responder") or args.responder),
            )
            applied += 1
            print(f"ok: {record['id']} -> {record['status']}")
        except (KeyError, ValueError) as exc:
            failed += 1
            print(f"rejected entry {index}: {exc}", file=sys.stderr)
    print(f"{applied} response(s) imported, {failed} rejected; rejected items remain outstanding.")
    return 1 if failed else 0


def cmd_correct(args: argparse.Namespace) -> int:
    try:
        path, record = find_record(args.root, args.id)
    except ValueError as exc:
        raise SystemExit(f"error: {exc}")
    record["correctedText"] = args.text
    record["correctedAt"] = now_iso()
    atomic_write(path, record)
    note = ""
    review = record.get("review")
    if review and review.get("basisText") and review["basisText"] != args.text:
        note = " Existing response predates this correction and is marked by its basisText."
    print(f"Recorded correction on {record['id']}; original text preserved.{note}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT)
    parser.add_argument("--responder", default="closeout-agent")
    commands = parser.add_subparsers(dest="command", required=True)

    list_parser = commands.add_parser("list", help="List observations. Default: outstanding only.")
    scope = list_parser.add_mutually_exclusive_group()
    scope.add_argument("--new", action="store_true", help="Only observations with no response yet.")
    scope.add_argument("--all", action="store_true", help="Every observation, including reviewed and addressed.")
    list_parser.add_argument("--json", action="store_true")
    list_parser.set_defaults(func=cmd_list)

    respond_parser = commands.add_parser("respond", help="Record a review response against an observation.")
    respond_parser.add_argument("--id", required=True)
    respond_parser.add_argument("--response", required=True)
    respond_parser.add_argument("--disposition", required=True, choices=DISPOSITIONS)
    respond_parser.set_defaults(func=cmd_respond)

    import_parser = commands.add_parser("import-responses", help="Validate and import a reviewer responses file.")
    import_parser.add_argument("--file", type=Path, required=True)
    import_parser.set_defaults(func=cmd_import_responses)

    correct_parser = commands.add_parser("correct", help="Record a correction without losing the original text.")
    correct_parser.add_argument("--id", required=True)
    correct_parser.add_argument("--text", required=True)
    correct_parser.set_defaults(func=cmd_correct)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
