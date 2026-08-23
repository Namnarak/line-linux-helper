#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
APP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/line-linux-helper"
RUNTIME="$APP_HOME/runtime"
BIN_HOME="$HOME/.local/bin"

mkdir -p "$APP_HOME" "$BIN_HOME"
rm -rf "$RUNTIME.new"
mkdir -p "$RUNTIME.new"
cp -a "$ROOT/bin" "$ROOT/lib" "$ROOT/config" "$RUNTIME.new/"
rm -rf "$RUNTIME"
mv "$RUNTIME.new" "$RUNTIME"
ln -sfn "$RUNTIME/bin/line-linux" "$BIN_HOME/line-linux"

exec "$BIN_HOME/line-linux" install "$@"
