#!/usr/bin/env bash
set -euo pipefail

REPO="Namnarak/line-linux-helper"
REF="${LINE_LINUX_HELPER_REF:-main}"
URL="https://github.com/${REPO}/archive/${REF}.tar.gz"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

printf '[*] Fetching line-linux-helper source from GitHub (%s)...\n' "$REF"
curl --proto '=https' --tlsv1.2 -fL --retry 3 --connect-timeout 15 "$URL" -o "$TMP/helper.tar.gz"
tar -xzf "$TMP/helper.tar.gz" -C "$TMP"
SRC=$(find "$TMP" -mindepth 1 -maxdepth 1 -type d -name 'line-linux-helper-*' -print -quit)
[[ -n "$SRC" && -x "$SRC/install.sh" ]] || { echo '[x] Invalid helper source archive' >&2; exit 1; }
"$SRC/install.sh" "$@"
