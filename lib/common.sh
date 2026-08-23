#!/usr/bin/env bash

: "${APP_NAME:=line-linux-helper}"
: "${APP_HOME:=${XDG_DATA_HOME:-$HOME/.local/share}/$APP_NAME}"
: "${CACHE_HOME:=${XDG_CACHE_HOME:-$HOME/.cache}/$APP_NAME}"
: "${PREFIX:=$APP_HOME/prefix}"
: "${RUNTIME_HOME:=$APP_HOME/runtime}"
: "${RUNNERS_HOME:=$APP_HOME/runners}"
: "${TOOLS_HOME:=$APP_HOME/tools}"
: "${SIGNING_HOME:=$APP_HOME/signing}"
: "${BIN_HOME:=$HOME/.local/bin}"
: "${DESKTOP_HOME:=${XDG_DATA_HOME:-$HOME/.local/share}/applications}"
: "${ICON_HOME:=${XDG_DATA_HOME:-$HOME/.local/share}/icons}"

mkdir -p "$CACHE_HOME" "$APP_HOME"

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_BLUE=$'\033[34m'
else
  C_RESET=''; C_BOLD=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_BLUE=''
fi

log()  { printf '%s[+]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
info() { printf '%s[*]%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
warn() { printf '%s[!]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()  { printf '%s[x]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

run() {
  if [[ ${DRY_RUN:-0} == 1 ]]; then
    printf 'DRY-RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"; }

as_root() {
  if (( EUID == 0 )); then
    "$@"
  else
    command -v sudo >/dev/null 2>&1 || die "sudo is required to install system dependencies"
    sudo "$@"
  fi
}

sha256_file() { sha256sum "$1" | awk '{print $1}'; }

ensure_dirs() {
  run mkdir -p "$APP_HOME" "$CACHE_HOME" "$RUNNERS_HOME" "$TOOLS_HOME" "$SIGNING_HOME" "$BIN_HOME" "$DESKTOP_HOME" "$ICON_HOME"
}

is_x86_64() {
  case "$(uname -m)" in
    x86_64|amd64) return 0 ;;
    *) return 1 ;;
  esac
}

wine_env() {
  export WINEPREFIX="$PREFIX"
  export WINEARCH=win64
  export WINE="$RUNNER_BIN/wine"
  export WINESERVER="$RUNNER_BIN/wineserver"
  export WINELOADER="$RUNNER_BIN/wine"
}

find_line_launcher() {
  find "$PREFIX/drive_c/users" -type f -path '*/AppData/Local/LINE/bin/LineLauncher.exe' -print -quit 2>/dev/null || true
}

find_line_exe() {
  find "$PREFIX/drive_c/users" -type f -path '*/AppData/Local/LINE/bin/current/LINE.exe' -print -quit 2>/dev/null || true
}
