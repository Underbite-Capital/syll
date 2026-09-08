#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/app/VoiceInk.xcodeproj"
DERIVED_DATA="$ROOT_DIR/build/syll-qa-derived-data"
SOURCE_APP="$ROOT_DIR/build/syll-qa-derived-data/Build/Products/Debug/VoiceInk.app"
SIGNING_IDENTITY="69C2BB0FE6E75589F044A08105D99DBEFC6DCFC5"
EXPECTED_TEAM="A635S52367"
SYLL_BUNDLE_ID="capital.underbite.syll"
SYLL_NAME="Syll"
SYLL_EXECUTABLE="Syll"

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <build-number> <output-directory>" >&2
  exit 2
fi

BUILD_NUMBER="$1"
OUTPUT_DIR="$2"
APP_BUNDLE="$OUTPUT_DIR/$SYLL_NAME.app"
ENTITLEMENTS="$ROOT_DIR/app/VoiceInk/VoiceInk.local.entitlements"

if [[ ! "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Build number must be numeric." >&2
  exit 2
fi

if ! security find-identity -v -p codesigning | grep -q "$SIGNING_IDENTITY.*Apple Development"; then
  echo "Required Apple Development signing identity is unavailable." >&2
  exit 1
fi

CERT_TEAM="$({ security find-certificate -c 'Apple Development: realjewlion@gmail.com (687D42QJZ6)' -p \
  | openssl x509 -noout -subject; } | sed -E 's/.*OU=([^, ]+).*/\1/')"
if [[ "$CERT_TEAM" != "$EXPECTED_TEAM" ]]; then
  echo "Signing Team mismatch: expected $EXPECTED_TEAM, found $CERT_TEAM" >&2
  exit 1
fi

if [[ ! -d "$PROJECT" || ! -f "$ENTITLEMENTS" ]]; then
  echo "Prepared core candidate is missing; prepare app/ before building Syll QA." >&2
  exit 1
fi

if [[ -e "$APP_BUNDLE" ]]; then
  echo "Refusing to overwrite existing Syll QA artifact: $APP_BUNDLE" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# This Apple Development path is a local QA build. Keep CloudKit disabled unless
# and until a separately provisioned release configuration supplies its intended
# production CloudKit authority.
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

if [[ ! -d "$SOURCE_APP" ]]; then
  echo "QA build reported success but did not produce $SOURCE_APP" >&2
  exit 1
fi

ditto "$SOURCE_APP" "$APP_BUNDLE"

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $SYLL_BUNDLE_ID" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName $SYLL_NAME" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $SYLL_NAME" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $SYLL_EXECUTABLE" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 0.1" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :LSUIElement true" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$APP_BUNDLE/Contents/Info.plist"
ditto "/Applications/Syll.app/Contents/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
mv "$APP_BUNDLE/Contents/MacOS/VoiceInk" "$APP_BUNDLE/Contents/MacOS/$SYLL_EXECUTABLE"

while IFS= read -r -d '' nested_code; do
  if [[ "$nested_code" != "$APP_BUNDLE/Contents/MacOS/$SYLL_EXECUTABLE" \
    && "$(file -b "$nested_code")" == *"Mach-O"* ]]
  then
    codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none --options runtime "$nested_code"
  fi
done < <(
  find "$APP_BUNDLE/Contents" -type f -print0
)

while IFS= read -r -d '' nested_bundle; do
  codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none --options runtime "$nested_bundle"
done < <(
  find "$APP_BUNDLE/Contents" -depth -type d \
    \( -name '*.framework' -o -name '*.xpc' -o -name '*.appex' -o -name '*.app' \) \
    -print0
)

codesign \
  --force \
  --sign "$SIGNING_IDENTITY" \
  --timestamp=none \
  --options runtime \
  --entitlements "$ENTITLEMENTS" \
  "$APP_BUNDLE"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

ACTUAL_TEAM="$(codesign -dvv "$APP_BUNDLE" 2>&1 | sed -n 's/^TeamIdentifier=//p')"
ACTUAL_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_BUNDLE/Contents/Info.plist")"
if [[ "$ACTUAL_TEAM" != "$EXPECTED_TEAM" || "$ACTUAL_ID" != "$SYLL_BUNDLE_ID" ]]; then
  echo "Signed Syll QA identity mismatch: team=$ACTUAL_TEAM bundle=$ACTUAL_ID" >&2
  exit 1
fi

while IFS= read -r -d '' signed_code; do
  SIGNED_TEAM="$(codesign -dvv "$signed_code" 2>&1 | sed -n 's/^TeamIdentifier=//p')"
  if [[ "$SIGNED_TEAM" != "$EXPECTED_TEAM" ]]; then
    echo "Nested signing Team mismatch: team=$SIGNED_TEAM path=$signed_code" >&2
    exit 1
  fi
done < <(
  find "$APP_BUNDLE/Contents" -type f \( -name '*.dylib' -o -perm -111 \) -print0
)

echo "$APP_BUNDLE"
