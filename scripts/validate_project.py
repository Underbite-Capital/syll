#!/usr/bin/env python3
"""Validate the durable Underbite project scaffold using only the stdlib."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path


REQUIRED = (
    ".gitignore",
    "README.md",
    "AGENTS.md",
    ".underbite/project.json",
    "research/RESEARCH-PLAN.md",
    "research/COMMERCIAL-DILIGENCE.md",
    "research/TECHNICAL-LITERATURE-REVIEW.md",
    "research/SYNTHESIS.md",
    "research/source-register.csv",
    "research/claim-evidence.csv",
    "decisions/DECISION-LOG.md",
)

CSV_HEADERS = {
    "research/source-register.csv": [
        "source_id", "title", "author_or_issuer", "source_type",
        "primary_or_secondary", "url_or_pointer", "published_or_version_date",
        "checked_at", "licence_or_access", "scope_or_domain", "claim_ids",
        "limitations", "notes",
    ],
    "research/claim-evidence.csv": [
        "claim_id", "claim_text", "claim_kind", "evidence_status", "source_ids",
        "exact_location", "scope", "limitations", "project_inference",
        "decision_affected", "last_checked",
    ],
}

PLACEHOLDERS = (
    "{{PROJECT_NAME}}", "{{PROJECT_SLUG}}", "{{PROJECT_KEY}}",
    "{{CREATED_DATE}}", "{{SLACK_CHANNEL}}",
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--template", action="store_true")
    args = parser.parse_args()
    root = args.root.expanduser().resolve()
    errors: list[str] = []

    for relative in REQUIRED:
        if not (root / relative).is_file():
            errors.append(f"missing required file: {relative}")

    project_file = root / ".underbite/project.json"
    if project_file.is_file():
        try:
            project = json.loads(project_file.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(f"invalid project.json: {exc}")
        else:
            if project.get("schema") != "underbite-project/v1":
                errors.append("project.json schema must be underbite-project/v1")
            if not isinstance(project.get("phase"), str) or not project["phase"].strip():
                errors.append("project.json phase must be a non-empty string")

    for relative, expected in CSV_HEADERS.items():
        path = root / relative
        if not path.is_file():
            continue
        with path.open(newline="", encoding="utf-8") as handle:
            actual = next(csv.reader(handle), [])
        if actual != expected:
            errors.append(f"unexpected CSV header: {relative}")

    validator_path = (root / "scripts/validate_project.py").resolve()
    text_files = [
        path for path in root.rglob("*")
        if path.is_file()
        and ".git" not in path.parts
        and path.resolve() != validator_path
    ]
    placeholder_hits: set[str] = set()
    for path in text_files:
        try:
            body = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        placeholder_hits.update(token for token in PLACEHOLDERS if token in body)

    if args.template:
        missing = set(PLACEHOLDERS) - placeholder_hits
        if missing:
            errors.append(f"template lost placeholders: {sorted(missing)}")
    elif placeholder_hits:
        errors.append(f"unrendered placeholders: {sorted(placeholder_hits)}")

    result = {
        "root": str(root),
        "mode": "template" if args.template else "project",
        "required_files": len(REQUIRED),
        "status": "valid" if not errors else "invalid",
        "errors": errors,
    }
    print(json.dumps(result, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
