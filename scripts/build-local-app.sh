#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"
MODE="core"
CORE_FLUIDAUDIO_COMMIT="c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7"
FULL_FLUIDAUDIO_COMMIT="6428e29186573c6d33c598e25d460e6690bc0ee1"

usage() {
  printf '%s\n' \
    "Build a prepared VoiceInk overlay as a local, ad-hoc-signed app." \
    "" \
    "Usage:" \
    "  ./scripts/build-local-app.sh [--core-only | --full]" \
    "" \
    "The default is --core-only. This script does not prepare, install, open," \
    "launch, or grant permissions to the app."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --core-only)
      MODE="core"
      ;;
    --full)
      MODE="full"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

PROJECT="$APP_DIR/VoiceInk.xcodeproj"
PACKAGE_RESOLVED="$PROJECT/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
LOCAL_ENTITLEMENTS="$APP_DIR/VoiceInk/VoiceInk.local.entitlements"
BOOSTER="$APP_DIR/VoiceInk/Transcription/FluidAudio/FluidAudioVocabularyBooster.swift"

if [[ ! -d "$PROJECT" || ! -f "$PACKAGE_RESOLVED" || ! -f "$LOCAL_ENTITLEMENTS" ]]; then
  echo "app/ is not prepared. Run prepare-app.sh before building." >&2
  exit 1
fi

if [[ ! -f "$APP_DIR/VoiceInk/Services/AIEnhancement/CleanupOutputValidator.swift" ]]; then
  echo "The core overlay is not present in app/. Prepare it before building." >&2
  exit 1
fi

if [[ "$MODE" == "core" ]]; then
  if [[ -e "$BOOSTER" ]]; then
    echo "Boosting source is present in a requested CORE-ONLY build. Reset and prepare core again." >&2
    exit 1
  fi
  if ! grep -q "$CORE_FLUIDAUDIO_COMMIT" "$PACKAGE_RESOLVED"; then
    echo "CORE-ONLY build does not contain the expected upstream FluidAudio revision." >&2
    exit 1
  fi
else
  if [[ ! -f "$BOOSTER" ]] || ! grep -q "$FULL_FLUIDAUDIO_COMMIT" "$PACKAGE_RESOLVED"; then
    echo "Full boosting overlay is not prepared." >&2
    exit 1
  fi
fi

OUTPUT_ROOT="$ROOT_DIR/build/voiceink-$MODE"
DERIVED_DATA="$OUTPUT_ROOT/DerivedData"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Debug/VoiceInk.app"

mkdir -p "$OUTPUT_ROOT"

xcodebuild \
  -project "$PROJECT" \
  -scheme VoiceInk \
  -configuration Debug \
  -destination "platform=macOS,arch=arm64" \
  -derivedDataPath "$DERIVED_DATA" \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  CODE_SIGNING_ALLOWED=NO \
  'SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) DEBUG LOCAL_BUILD' \
  build

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Build reported success but did not produce $APP_BUNDLE" >&2
  exit 1
fi

while IFS= read -r -d '' nested_bundle; do
  codesign --force --sign - --timestamp=none "$nested_bundle"
done < <(
  find "$APP_BUNDLE/Contents" -depth -type d \
    \( -name '*.framework' -o -name '*.xpc' -o -name '*.appex' -o -name '*.app' \) \
    -print0
)

codesign \
  --force \
  --sign - \
  --timestamp=none \
  --entitlements "$LOCAL_ENTITLEMENTS" \
  "$APP_BUNDLE"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

ENTITLEMENTS_DUMP="$(mktemp -t voiceink-local-entitlements).plist"
cleanup() {
  rm -f "$ENTITLEMENTS_DUMP"
}
trap cleanup EXIT
codesign --display --entitlements :- "$APP_BUNDLE" >"$ENTITLEMENTS_DUMP" 2>/dev/null
plutil -lint "$ENTITLEMENTS_DUMP" >/dev/null

for forbidden_key in \
  com.apple.developer.aps-environment \
  com.apple.developer.icloud-container-identifiers \
  com.apple.developer.icloud-services \
  keychain-access-groups
do
  if /usr/libexec/PlistBuddy -c "Print :$forbidden_key" "$ENTITLEMENTS_DUMP" >/dev/null 2>&1; then
    echo "Unsafe entitlement survived local signing: $forbidden_key" >&2
    exit 1
  fi
done

printf '%s\n' \
  "Local VoiceInk build verified." \
  "Mode: $MODE" \
  "App: $APP_BUNDLE" \
  "LOCAL_BUILD: enabled" \
  "Signing: ad hoc, reduced local entitlements" \
  "" \
  "This script did not install or launch the app."
