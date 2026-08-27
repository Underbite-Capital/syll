#!/usr/bin/env bash
set -euo pipefail

APP_ID="com.prakashjoshipax.VoiceInk"
APP_SUPPORT="/Users/david/Library/Application Support/$APP_ID"
KNOWN_GOOD_APP="/Users/david/Downloads/VoiceInk.app"
DESTINATION=""

usage() {
  printf '%s\n' \
    "Create a verified, timestamped backup before launching a local VoiceInk build." \
    "" \
    "Usage:" \
    "  ./scripts/backup-voiceink.sh --destination /absolute/backup/directory" \
    "" \
    "VoiceInk must be quit. The destination must not already exist."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --destination)
      shift
      DESTINATION="${1:-}"
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

if [[ -z "$DESTINATION" || "$DESTINATION" != /* ]]; then
  echo "Provide an explicit absolute --destination." >&2
  exit 2
fi

if [[ -e "$DESTINATION" ]]; then
  echo "Refusing to overwrite existing destination: $DESTINATION" >&2
  exit 1
fi

STAGING="${DESTINATION}.partial.$$"
if [[ -e "$STAGING" ]]; then
  echo "Refusing to overwrite existing staging path: $STAGING" >&2
  exit 1
fi

if pgrep -x VoiceInk >/dev/null; then
  echo "VoiceInk is running. Quit it normally before taking the backup." >&2
  exit 1
fi

if [[ ! -d "$APP_SUPPORT" ]]; then
  echo "VoiceInk application-support directory not found: $APP_SUPPORT" >&2
  exit 1
fi

mkdir -p "$STAGING"
ditto "$APP_SUPPORT" "$STAGING/Application Support/$APP_ID"
defaults export "$APP_ID" "$STAGING/$APP_ID.preferences.plist"

if [[ -d "$KNOWN_GOOD_APP" ]]; then
  ditto "$KNOWN_GOOD_APP" "$STAGING/Known Good VoiceInk.app"
fi

while IFS= read -r store; do
  result="$(sqlite3 "$store" 'PRAGMA integrity_check;')"
  if [[ "$result" != "ok" ]]; then
    echo "SQLite integrity check failed for $store: $result" >&2
    exit 1
  fi
done < <(find "$STAGING/Application Support/$APP_ID" -type f -name '*.store' -print)

(
  cd "$STAGING"
  find . -type f ! -path './SHA256SUMS' -print0 | sort -z | xargs -0 shasum -a 256
) >"$STAGING/SHA256SUMS"

(
  cd "$STAGING"
  shasum -a 256 -c SHA256SUMS >/dev/null
)

mv "$STAGING" "$DESTINATION"

printf '%s\n' \
  "VoiceInk backup verified." \
  "Destination: $DESTINATION" \
  "Preferences: exported" \
  "SQLite stores: integrity checked" \
  "Manifest: $DESTINATION/SHA256SUMS" \
  "" \
  "No installed app or live data was changed."
