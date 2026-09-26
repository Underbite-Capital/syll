# Syll repository convergence evidence

## Candidate gate

The successor begins at `e4c161e26fc390aca70d4179cf820310d9c12ef8`.
Its core composition uses pinned VoiceInk
`3c211dab63454f18cf3f8b58750ec6bf3f5b4d17`, root `overlays/core`, and
the ordered core, branding, recovery, shell, command-mode, and core-reliability
patches. The Xcode 27 Metal Toolchain (`27A266a`) was installed only after
David's explicit authorization. `xcodebuild -showComponent MetalToolchain -json`
reported `installed`, and `xcrun metal --version` ran. The isolated core build
reported `** BUILD SUCCEEDED **`; the ad-hoc signed executable SHA-256 was
`58105906b8f87c898987e769ad18e21ba8f1fe3254fd4bbac75946fc7e1d5087`.
`codesign --verify --deep --strict` passed. The XCTest target compiled with
`** TEST BUILD SUCCEEDED **`, while app-hosted XCTest execution was rejected by
automatic approval review because it would launch the candidate test host.
Standalone focused Swift/SwiftData checks of the composed source passed.
No candidate was installed or launched.

## Original dirty `app/` classification

The root `app/` initially had 42 modified tracked paths and 11 untracked
paths at the pinned upstream commit. Every one was compared byte for byte
against the cleanly prepared successor:

- 48 paths matched exactly. They are materialized root overlays/patches and
  generated composition, not unique source.
- `VoiceInk/Paste/CursorPaster.swift` and
  `VoiceInk/Transcription/Engine/TranscriptionPipeline.swift` were older than
  the build-239 `syll-command-mode.patch` changes that condition clipboard
  restoration on a posted paste command and save completed text before
  delivery.
- `VoiceInk/Views/Recorder/MiniRecorderView.swift` was older than the
  maintained command/HUD overlay. That implementation remains unaccepted;
  its human-QA failure is preserved separately.
- `VoiceInk/VoiceInk.swift` was older than the maintained shell/recovery
  patches, including the current template menu mark. The historical coloured
  menu-bar idea remains deferred; no icon was changed in this convergence.
- `VoiceInk/Transcription/Processing/WordReplacementService.swift` was older
  than the successor's cleanup-before-dictionary correction.

The source of each of the five differences is present in the maintained
successor. No useful unique dirty-subtree content was found (category 4 is
empty). Resetting/rematerializing the generated subtree is safe only after
the integrated main passes a fresh build and the archived branch evidence is
verified.

## Branch evidence

At inventory, `main`, `feature/syll-dictation-quality-control`, and
`codex/voiceink-personal-dictionary` were ancestors of the candidate and had
no unique commits. The `prd-handoff` branch had three unique commits; they
are merged into main history, with its PRD handoff and accepted-at-the-time
ticket graph archived under `research/history/2026-08-21-prd-handoff/`.
That graph is not current delivery authority. Command Mode remains
unaccepted, correction learning remains deferred, short-utterance evidence
is still limited, and the future double-tap action remains undecided.
The historical coloured Syll mark's raw build-221 ICNS is retained under
`reference/` with its digest and provenance. It is not a current menu-bar
change or a release requirement.
