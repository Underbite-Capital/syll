#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"
UPSTREAM_COMMIT="3c211dab63454f18cf3f8b58750ec6bf3f5b4d17"
MODE="full"
RESET=0

usage() {
  cat <<'EOF'
Prepare the VoiceInk submodule with the personal-dictionary overlay.

Usage:
  ./scripts/prepare-app.sh [--core-only] [--reset]

Options:
  --core-only  Apply the unified dictionary and safe cleanup only. Skip the
               experimental FluidAudio vocabulary-boosting adapter.
  --reset      Discard all current changes and untracked files inside app/
               before preparing the exact upstream commit.
  -h, --help   Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --core-only)
      MODE="core"
      ;;
    --reset)
      RESET=1
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

cd "$ROOT_DIR"
if [[ "$MODE" == "core" ]]; then
  python3 "$ROOT_DIR/scripts/verify_overlay.py" --core-only
else
  python3 "$ROOT_DIR/scripts/verify_overlay.py"
fi

git submodule sync -- app
git submodule update --init app

if [[ ! -d "$APP_DIR/.git" && ! -f "$APP_DIR/.git" ]]; then
  echo "VoiceInk submodule was not initialized at $APP_DIR" >&2
  exit 1
fi

if [[ -n "$(git -C "$APP_DIR" status --porcelain)" ]]; then
  if [[ "$RESET" -ne 1 ]]; then
    cat >&2 <<'EOF'
app/ contains local changes. Refusing to overwrite them.
Re-run with --reset only when those changes are disposable, or commit/stash them first.
EOF
    exit 1
  fi

  git -C "$APP_DIR" reset --hard
  git -C "$APP_DIR" clean -fd
fi

MUTATED=0
restore_on_error() {
  local status=$?
  trap - ERR INT TERM
  set +e
  if [[ "$MUTATED" -eq 1 ]]; then
    echo "Preparation failed; restoring app/ to exact upstream $UPSTREAM_COMMIT" >&2
    git -C "$APP_DIR" reset --hard "$UPSTREAM_COMMIT"
    local reset_status=$?
    git -C "$APP_DIR" clean -fd
    local clean_status=$?
    if [[ "$reset_status" -ne 0 ]]; then
      echo "ERROR: git reset --hard $UPSTREAM_COMMIT failed (exit $reset_status) while restoring app/" >&2
    fi
    if [[ "$clean_status" -ne 0 ]]; then
      echo "ERROR: git clean -fd failed (exit $clean_status) while restoring app/" >&2
    fi
    if [[ "$reset_status" -ne 0 || "$clean_status" -ne 0 ]]; then
      echo "ERROR: restore of app/ did not fully succeed. Do not treat this as a clean restore." >&2
    fi
  fi
  exit "$status"
}
trap restore_on_error ERR INT TERM

MUTATED=1
git -C "$APP_DIR" fetch origin "$UPSTREAM_COMMIT"
git -C "$APP_DIR" checkout --detach "$UPSTREAM_COMMIT"

git -C "$APP_DIR" apply --check "$ROOT_DIR/patches/core.patch"

if [[ "$MODE" == "full" ]]; then
  if [[ ! -d "$ROOT_DIR/overlays/boosting" || ! -f "$ROOT_DIR/patches/boosting.patch" ]]; then
    echo "Boosting overlay is not present. Use --core-only or restore the missing files." >&2
    exit 1
  fi

  git -C "$APP_DIR" apply --check "$ROOT_DIR/patches/boosting.patch"
fi

cp -R "$ROOT_DIR/overlays/core/." "$APP_DIR/"
git -C "$APP_DIR" apply "$ROOT_DIR/patches/core.patch"

if [[ "$MODE" == "full" ]]; then
  cp -R "$ROOT_DIR/overlays/boosting/." "$APP_DIR/"
  git -C "$APP_DIR" apply "$ROOT_DIR/patches/boosting.patch"
fi

git -C "$APP_DIR" diff --check
trap - ERR INT TERM

cat <<EOF
Prepared VoiceInk at $UPSTREAM_COMMIT
Mode: $MODE

Next:
  open "$APP_DIR/VoiceInk.xcodeproj"

Inspect the exact delta with:
  git -C "$APP_DIR" status --short
  git -C "$APP_DIR" diff --stat

This script does not sign, install, launch, or grant macOS permissions.
EOF
