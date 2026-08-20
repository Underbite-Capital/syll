#!/usr/bin/env python3
"""Render the spike's strict dictionary.yaml subset as a VoiceInk settings backup."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


CANONICAL = re.compile(r'^  - canonical: ("(?:[^"\\]|\\.)*")$')
ALIASES_EMPTY = re.compile(r"^    aliases: \[\]$")
ALIASES_START = re.compile(r"^    aliases:$")
ALIAS = re.compile(r'^      - ("(?:[^"\\]|\\.)*")$')
CLEANUP_PROMPT_ID = "42924d0f-8d85-4eaa-bb3e-2434390406e7"


def quoted_value(token: str, line_number: int) -> str:
    try:
        value = json.loads(token)
    except json.JSONDecodeError as exc:
        raise ValueError(f"line {line_number}: invalid quoted string") from exc
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"line {line_number}: value must be a non-empty string")
    return value


def parse_dictionary(path: Path) -> list[dict[str, object]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    if lines[:2] != ["version: 1", "terms:"]:
        raise ValueError("dictionary must start with 'version: 1' followed by 'terms:'")

    terms: list[dict[str, object]] = []
    current: dict[str, object] | None = None
    accepting_aliases = False

    for line_number, line in enumerate(lines[2:], start=3):
        if not line or line.lstrip().startswith("#"):
            continue
        if match := CANONICAL.fullmatch(line):
            current = {"canonical": quoted_value(match.group(1), line_number), "aliases": []}
            terms.append(current)
            accepting_aliases = False
            continue
        if ALIASES_EMPTY.fullmatch(line):
            if current is None:
                raise ValueError(f"line {line_number}: aliases appear before a canonical term")
            accepting_aliases = False
            continue
        if ALIASES_START.fullmatch(line):
            if current is None:
                raise ValueError(f"line {line_number}: aliases appear before a canonical term")
            accepting_aliases = True
            continue
        if match := ALIAS.fullmatch(line):
            if current is None or not accepting_aliases:
                raise ValueError(f"line {line_number}: alias appears outside an aliases list")
            alias = quoted_value(match.group(1), line_number)
            if "," in alias:
                raise ValueError(f"line {line_number}: aliases may not contain commas (VoiceInk separator)")
            aliases = current["aliases"]
            assert isinstance(aliases, list)
            aliases.append(alias)
            continue
        raise ValueError(f"line {line_number}: unsupported dictionary syntax: {line!r}")

    if not terms:
        raise ValueError("dictionary contains no terms")

    canonical_keys: set[str] = set()
    alias_keys: set[str] = set()
    for term in terms:
        canonical = str(term["canonical"])
        canonical_key = canonical.casefold()
        if canonical_key in canonical_keys:
            raise ValueError(f"duplicate canonical term: {canonical}")
        canonical_keys.add(canonical_key)
        for alias in term["aliases"]:
            alias_key = str(alias).casefold()
            if alias_key == canonical_key:
                raise ValueError(f"alias duplicates its canonical term: {alias}")
            if alias_key in alias_keys:
                raise ValueError(f"duplicate alias: {alias}")
            alias_keys.add(alias_key)
    return terms


def render_backup(terms: list[dict[str, object]], cleanup_prompt: str) -> dict[str, object]:
    replacements: dict[str, str] = {}
    for term in terms:
        aliases = [str(value) for value in term["aliases"]]
        if aliases:
            replacements[", ".join(aliases)] = str(term["canonical"])

    return {
        "version": "2.11",
        "customPrompts": [
            {
                "id": CLEANUP_PROMPT_ID,
                "title": "David cleanup",
                "promptText": cleanup_prompt.rstrip(),
                "useSystemInstructions": True,
            }
        ],
        "modeConfigs": [],
        "vocabularyWords": [{"word": str(term["canonical"])} for term in terms],
        "wordReplacements": replacements,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dictionary", type=Path, default=Path("dictionary.yaml"))
    parser.add_argument("--cleanup-prompt", type=Path, default=Path("cleanup-prompt.txt"))
    parser.add_argument("--output", type=Path, default=Path("prototype/VoiceInk_David_Settings.json"))
    parser.add_argument("--check", action="store_true", help="validate only; do not write output")
    args = parser.parse_args()

    terms = parse_dictionary(args.dictionary)
    cleanup_prompt = args.cleanup_prompt.read_text(encoding="utf-8")
    backup = render_backup(terms, cleanup_prompt)

    if args.check:
        print(f"valid: {len(terms)} terms, {len(backup['wordReplacements'])} replacement groups")
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(backup, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
