#!/usr/bin/env python3
"""Static checks for the reproducible VoiceInk overlay.

This deliberately does not claim that the macOS app compiles. CI separately
initializes the public submodule and asks git to apply the patches exactly.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
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


def validate_patch_syntax(path: str, *, recount: bool = False) -> None:
    patch = require(path)
    command = ["git", "apply"]
    if recount:
        command.append("--recount")
    command.extend(["--numstat", str(patch)])
    result = subprocess.run(
        command,
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or "git could not parse the patch"
        raise AssertionError(f"invalid patch {path}: {detail}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--core-only",
        action="store_true",
        help="Validate only the independently usable core overlay and patch.",
    )
    args = parser.parse_args()

    validate_patch_syntax("patches/core.patch")
    validate_patch_syntax("patches/syll-branding.patch")
    validate_patch_syntax("patches/syll-recovery.patch", recount=True)
    validate_patch_syntax("patches/syll-shell-structural.patch", recount=True)
    validate_patch_syntax("patches/syll-command-mode.patch")
    validate_patch_syntax("patches/syll-core-reliability.patch")
    validate_patch_syntax("patches/syll-disable-double-tap.patch")
    validate_patch_syntax("patches/syll-remember.patch")
    if not args.core_only:
        validate_patch_syntax("patches/boosting.patch")

    prepare = require_text(
        "scripts/prepare-app.sh",
        UPSTREAM_COMMIT,
        "--core-only",
        'cat-file -e "$UPSTREAM_COMMIT^{commit}"',
        "git -C \"$APP_DIR\" apply --check",
        "patches/syll-branding.patch",
        "patches/syll-command-mode.patch",
        "patches/syll-core-reliability.patch",
        "patches/syll-disable-double-tap.patch",
        "patches/syll-remember.patch",
    )
    if "MODE=\"full\"" not in prepare:
        raise AssertionError("full overlay must remain the explicit default")

    core_dictionary_view = require_text(
        "overlays/core/VoiceInk/Views/Dictionary/DictionarySettingsView.swift",
        "Correct spellings after transcription",
    )
    if "Improve local Parakeet recognition" in core_dictionary_view:
        raise AssertionError("core-only dictionary UI must not expose unavailable recognition boosting")

    require_text(
        "overlays/core/VoiceInk/Services/PersonalDictionaryService.swift",
        "migrateLegacyVocabulary",
        "refreshRecognitionCache",
        "recognitionTerms",
        "saveTerm",
    )
    require_text(
        "overlays/core/VoiceInk/Transcription/Processing/PersonalDictionaryCorrector.swift",
        "selected.reversed()",
        "caseInsensitive",
    )
    require_text(
        "overlays/core/VoiceInk/Transcription/Processing/WordReplacementService.swift",
        "DeterministicDictationCleaner.clean(text)",
        "PersonalDictionaryCorrector.correct(cleanedText, entries: entries)",
    )
    require_text(
        "patches/syll-core-reliability.patch",
        "latestCompletedText",
        'transcriptionStatus == "completed"',
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
        "CloudTranscriptionService",
        "AssemblyAIStreamingProvider",
        "PersonalDictionaryService.recognitionTerms",
    )
    require_text(
        "scripts/build-apple-development-pilot.sh",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) DEBUG LOCAL_BUILD",
        "CODE_SIGNING_ALLOWED=NO",
        "--options runtime",
    )
    require_text(
        "patches/syll-branding.patch",
        'Button("Quit Syll")',
        'Window("Syll"',
        'window.title = "Syll"',
        "Restart Syll",
    )
    require_text(
        "patches/syll-recovery.patch",
        "private static let statusImage: NSImage",
        "flipped: false",
        "image.isTemplate = true",
        "Image(nsImage: Self.statusImage)",
    )
    require_text(
        "overlays/core/VoiceInk/Commands/SyllCommandRegistry.swift",
        'normalized == "git status"',
        'normalized == "copy branch"',
        'normalized == "open iqs staging"',
        '(["kill port "]',
    )
    command_executor = require_text(
        "overlays/core/VoiceInk/Commands/SyllCommandExecutor.swift",
        'executable: URL(fileURLWithPath: "/usr/sbin/lsof")',
        'executable: URL(fileURLWithPath: "/usr/bin/git")',
        "Darwin.kill(listener.pid, SIGTERM)",
    )
    if any(shell in command_executor for shell in ('"/bin/zsh"', '"/bin/sh"', '"/bin/bash"')):
        raise AssertionError("command executor must not route transcripts through a shell")
    command_context = require_text(
        "overlays/core/VoiceInk/Commands/SyllCommandContext.swift",
        "kAXDocumentAttribute",
        "documentURL.isFileURL",
        "nearestRepositoryRoot",
    )
    if "/Users/" in command_context:
        raise AssertionError("repository resolution must not contain a user-specific workspace path")
    command_patch = require_text(
        "patches/syll-command-mode.patch",
        "if mode == .hybrid, pendingHybridTap != nil",
        "if action == .primaryRecording",
        "latchCommandMode()",
        "hybridDoubleTapInterval: TimeInterval = 0.5",
        "179,  // Globe/Fn companion key-down emitted by current Apple keyboards.",
        "stoppedUseCase == .command",
        "await runCommand(on: recordedFile)",
        "saveTranscriptionAndPostCompletion()",
        "pasteResult.didPostPasteCommand",
        "SyllPhase1Runtime.transcriptionConfiguration",
    )
    if "SyllFnGestureStateMachine" in command_patch:
        raise AssertionError("command mode must extend the accepted hybrid Fn handler, not replace it")
    disable_double_tap = require_text(
        "patches/syll-disable-double-tap.patch",
        "-            isHandsFreeRecording = true",
        "-                latchCommandMode()",
        "-            return",
    )
    if disable_double_tap.count("diff --git ") != 1:
        raise AssertionError("double-tap disablement must touch only the shortcut handler")

    remember_patch = require_text(
        "patches/syll-remember.patch",
        "latchObservationMode()",
        "isHandsFreeRecording = true",
        "case observation",
        "SyllSessionRouting.outcome(for: stoppedUseCase.routing",
        "await runObservation(on: recordedFile)",
        "SyllObservationStore.shared.save",
        "recordFailure",
        "isObservationCaptureActive",
        "SyllPhase1Runtime.transcriptionConfiguration",
    )
    if "CursorPaster" in remember_patch or "NSPasteboard" in remember_patch:
        raise AssertionError("observation capture must not add any paste or clipboard path")
    require_text(
        "overlays/core/VoiceInk/Transcription/Engine/SyllSessionRouting.swift",
        "case observation",
        "if cancelRequested { return .cancellation }",
        "return .observation",
    )
    require_text(
        "overlays/core/VoiceInk/Services/SyllObservationStore.swift",
        "originalText",
        "schemaVersion",
        "outstanding",
        "awaitingDecision",
        "markAddressed",
        "basisText",
        "maximumFailedCount",
        "automatic expiry",
    )
    require_text(
        "overlays/core/VoiceInk/Views/SyllObservationsView.swift",
        "Mark Addressed",
        "reviewPredatesCorrection",
        "Failed captures",
        "Correct…",
    )
    require_text(
        "overlays/core/VoiceInk/Views/Recorder/SyllObservationOutcomeView.swift",
        "struct SyllObservationOutcome",
        "struct SyllObservationOutcomeView",
    )
    require_text(
        "overlays/core/VoiceInk/Views/Recorder/RecorderStateProvider.swift",
        "isObservationMode",
        "observationOutcome",
    )
    require_text(
        "overlays/core/VoiceInk/Views/Recorder/MiniRecorderView.swift",
        "isObservationMode",
        "rememberViolet",
        "Recording observation",
        "SyllObservationOutcomeView",
    )
    require_text(
        "overlays/core/VoiceInk/Views/Recorder/SyllWaveformPill.swift",
        "rememberViolet",
        "ordinaryOrange",
    )

    dictionary = require_text("dictionary.yaml", "version: 1", "canonical:")
    require_text("patches/syll-local-diagnostics.patch", "firstAcceptedBufferNanos", "captureRaw", "resetClipboard")
    require_text("overlays/core/VoiceInk/Services/SyllFailureEvidenceStore.swift", "maximumMarkedCount", "maximumOrdinaryCount", "maximumOrdinaryBytes", "rawRecognizerText")
    require_text("overlays/core/VoiceInk/Services/SyllOperationalLog.swift", "firstAcceptedBufferUptimeSeconds", "maximumSessions")
    require_text("overlays/core/VoiceInk/Paste/SyllClipboardResetPolicy.swift", "currentSessionID == expectedSessionID", "currentText == expectedText")
    menu = require_text(
        "overlays/core/VoiceInk/Views/SyllMenuBarView.swift",
        "Reset Clipboard",
        "Copy Last Transcription",
        "Observations",
        "Reveal Observations Folder",
    )
    for hidden in ('Button("Toggle Recorder")', 'Button("Setup…")', 'Button("History…")', 'Button("Advanced Settings…")'):
        if hidden in menu:
            raise AssertionError(f"legacy menu entry remains: {hidden}")
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
    implementation = project.get("implementation", {})
    if implementation.get("command_mode_state") != "dormant-not-accepted":
        raise AssertionError("Command Mode must remain dormant and explicitly unaccepted")

    boosting_dir = ROOT / "overlays/boosting"
    boosting_patch = ROOT / "patches/boosting.patch"
    if not args.core_only:
        if not boosting_dir.exists() or not any(boosting_dir.rglob("*.swift")):
            raise AssertionError("full overlay is missing boosting Swift sources")
        require(boosting_patch.relative_to(ROOT).as_posix())
        require_text(
            "overlays/boosting/VoiceInk/Views/Dictionary/DictionarySettingsView.swift",
            "Improve local Parakeet recognition",
            "isRecognitionBoostingEnabled",
        )
        require_text(
            "overlays/boosting/VoiceInk/Transcription/FluidAudio/FluidAudioVocabularyBooster.swift",
            "VocabularyBoostingSession",
            "return text",
        )
        require_text("patches/boosting.patch", FLUIDAUDIO_COMMIT)

    mode = "core" if args.core_only else "full"
    print(f"Overlay metadata valid ({mode}): {term_count} seeded terms; upstream {UPSTREAM_COMMIT[:12]}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, json.JSONDecodeError) as exc:
        print(f"overlay verification failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
