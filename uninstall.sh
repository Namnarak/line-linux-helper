#!/usr/bin/env bash
set -euo pipefail
CLI="$HOME/.local/bin/line-linux"
if [[ -x "$CLI" ]]; then
  exec "$CLI" uninstall "$@"
fi
APP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/line-linux-helper"
printf 'line-linux-helper CLI is missing. Remove %s manually if you want to purge it.\n' "$APP_HOME"
