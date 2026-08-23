#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export APP_HOME="$TMP/app" CACHE_HOME="$TMP/cache" PREFIX="$TMP/prefix"
mkdir -p "$APP_HOME" "$CACHE_HOME" "$PREFIX"
# shellcheck source=../config/manifest.sh
source "$ROOT/config/manifest.sh"
# shellcheck source=../lib/common.sh
source "$ROOT/lib/common.sh"
DRY_RUN=0

# Stale lock should recover and be released.
mkdir -p "$APP_HOME/.operation.lock"
printf '999999\n' > "$APP_HOME/.operation.lock/pid"
acquire_operation_lock
[[ -d "$APP_HOME/.operation.lock" ]]
release_operation_lock
[[ ! -e "$APP_HOME/.operation.lock" ]]

grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' <<<"$HELPER_VERSION"
[[ "$RUNNER_SHA256" =~ ^[0-9a-f]{64}$ ]]
[[ "$LINE_INSTALLER_URL" == https://desktop.line-scdn.net/* ]]

echo 'Logic tests passed.'
