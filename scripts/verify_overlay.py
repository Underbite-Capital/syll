#!/usr/bin/env python3
"""Static checks for the reproducible VoiceInk overlay.

This deliberately does not claim that the macOS app compiles. CI separately
initializes the public submodule and asks git to apply the patches exactly.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UPSTREAM_COMMIT = "3c211dab63454f18cf3f8b58750ec6bf3f5b4d17"
FLUIDAUDIO_COMMIT = "6428e29186573c6d33c598e25d460e6690bc0ee1"


def require(path: str) -> Path:
    candidate = ROOT / path
    if not candidate.exists():
        raise AssertionError(f"missing required path: {path}")
    return candidate


def require_text(path: str, *needles: str) -> str:
    text = require(path).read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            raise AssertionError(f"{path} is missing marker: {needle!r}")
    return text


def main() -> int:
    prepare = require_text(
        "scripts/prepare-app.sh",
        UPSTREAM_COMMIT,
        "--core-only",
        "git -C \"$APP_DIR\" apply --check",
    )
    if "MODE=\"full\"" not in prepare:
        raise AssertionError("full overlay must remain the explicit default")

    require_text(
        "overlays/core/VoiceInk/Services/PersonalDictionaryService.swift",
        "migrateLegacyVocabulary",
        "refreshRecognitionCache",
        "saveTerm",
    )
    require_text(
        "overlays/core/VoiceInk/Transcription/Processing/PersonalDictionaryCorrector.swift",
        "selected.reversed()",
        "caseInsensitive",
    )
    require_text(
        "overlays/core/VoiceInk/Services/AIEnhancement/CleanupOutputValidator.swift",
        "numericTokens",
        "protected spelling",
        "Using the corrected transcript instead",
    )
    require_text(
        "patches/core.patch",
        "maxAttempts",
        "validatedText",
        "refreshRecognitionCache",
    )

    dictionary = require_text("dictionary.yaml", "version: 1", "canonical:")
    term_count = len(re.findall(r"^\s*- canonical:", dictionary, flags=re.MULTILINE))
    if term_count < 20:
        raise AssertionError(f"dictionary seed unexpectedly small: {term_count} terms")

    settings = json.loads(require("prototype/VoiceInk_David_Settings.json").read_text(encoding="utf-8"))
    if not settings.get("customPrompts"):
        raise AssertionError("settings import is missing the cleanup prompt")
    if "cleanup" not in settings["customPrompts"][0]["title"].lower():
        raise AssertionError("cleanup prompt title must activate the output validator")

    project = json.loads(require(".underbite/project.json").read_text(encoding="utf-8"))
    if project.get("phase") != "implementation-candidate":
        raise AssertionError("project phase must be implementation-candidate")

    boosting_dir = ROOT / "overlays/boosting"
    boosting_patch = ROOT / "patches/boosting.patch"
    if boosting_dir.exists() and any(boosting_dir.rglob("*.swift")):
        require_text(
            "overlays/boosting/VoiceInk/Transcription/FluidAudio/FluidAudioVocabularyBooster.swift",
            "VocabularyBoostingSession",
            "return text",
        )
        require_text("patches/boosting.patch", FLUIDAUDIO_COMMIT)

    print(f"Overlay metadata valid: {term_count} seeded terms; upstream {UPSTREAM_COMMIT[:12]}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, json.JSONDecodeError) as exc:
        print(f"overlay verification failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
