#!/usr/bin/env bash
# shellcheck disable=SC2034

: "${APP_NAME:=line-linux-helper}"
: "${APP_HOME:=${XDG_DATA_HOME:-$HOME/.local/share}/$APP_NAME}"
: "${CACHE_HOME:=${XDG_CACHE_HOME:-$HOME/.cache}/$APP_NAME}"
: "${STATE_HOME:=${XDG_STATE_HOME:-$HOME/.local/state}/$APP_NAME}"
: "${PREFIX:=$APP_HOME/prefix}"
: "${RUNTIME_HOME:=$APP_HOME/runtime}"
: "${RUNNERS_HOME:=$APP_HOME/runners}"
: "${TOOLS_HOME:=$APP_HOME/tools}"
: "${SIGNING_HOME:=$APP_HOME/signing}"
: "${BIN_HOME:=$HOME/.local/bin}"
: "${DESKTOP_HOME:=${XDG_DATA_HOME:-$HOME/.local/share}/applications}"
: "${ICON_HOME:=${XDG_DATA_HOME:-$HOME/.local/share}/icons}"

DISPLAY_BACKEND=${LINE_DISPLAY_BACKEND:-$DISPLAY_BACKEND_DEFAULT}
GRAPHICS_BACKEND=${LINE_GRAPHICS_BACKEND:-$GRAPHICS_BACKEND_DEFAULT}
WINED3D_RENDERER=${LINE_WINED3D_RENDERER:-$WINED3D_RENDERER_DEFAULT}

mkdir -p "$CACHE_HOME" "$APP_HOME" "$STATE_HOME"

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
  run mkdir -p "$APP_HOME" "$CACHE_HOME" "$STATE_HOME" "$RUNNERS_HOME" "$TOOLS_HOME" "$SIGNING_HOME" "$BIN_HOME" "$DESKTOP_HOME" "$ICON_HOME"
}

is_x86_64() {
  case "$(uname -m)" in
    x86_64|amd64) return 0 ;;
    *) return 1 ;;
  esac
}

validate_runtime_config() {
  [[ "$DISPLAY_BACKEND" == xwayland ]] || die "Unsupported display backend: $DISPLAY_BACKEND (v0.3 supports xwayland only)"
  [[ "$GRAPHICS_BACKEND" == wined3d ]] || die "Unsupported graphics backend: $GRAPHICS_BACKEND (v0.3 supports wined3d only)"
  [[ "$WINED3D_RENDERER" == gl ]] || die "Unsupported WineD3D renderer: $WINED3D_RENDERER (v0.3 stable profile uses gl)"
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

acquire_operation_lock() {
  [[ ${DRY_RUN:-0} == 1 ]] && return 0
  local lock="$APP_HOME/.operation.lock" owner=''
  if ! mkdir "$lock" 2>/dev/null; then
    [[ -r "$lock/pid" ]] && owner=$(cat "$lock/pid" 2>/dev/null || true)
    if [[ "$owner" =~ ^[0-9]+$ ]] && ! kill -0 "$owner" 2>/dev/null; then
      warn "Removing stale operation lock from PID $owner"
      rm -rf "$lock"
      mkdir "$lock" || die "Cannot acquire operation lock: $lock"
    else
      die "Another install/update/repair operation is already running${owner:+ (PID $owner)}"
    fi
  fi
  printf '%s\n' "$$" > "$lock/pid"
  OPERATION_LOCK="$lock"
  trap 'release_operation_lock' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM HUP
}

release_operation_lock() {
  if [[ -n ${OPERATION_LOCK:-} && -d ${OPERATION_LOCK:-} ]]; then
    rm -rf "$OPERATION_LOCK"
  fi
  OPERATION_LOCK=''
}

line_version() {
  local ini
  ini=$(find "$PREFIX/drive_c/users" -type f -path '*/AppData/Local/LINE/Data/LINE.ini' -print -quit 2>/dev/null || true)
  [[ -n "$ini" ]] || return 1
  awk -F= '/^last_updated_version=/{gsub(/\r/,"",$2); print $2; exit}' "$ini"
}

write_helper_state() {
  [[ ${DRY_RUN:-0} == 1 ]] && return 0
  local version='unknown' state_file="$STATE_HOME/state.env"
  version=$(line_version 2>/dev/null || true)
  cat > "$state_file" <<STATE
helper_version=$HELPER_VERSION
runtime_family=$RUNTIME_FAMILY
runner_name=$RUNNER_NAME
runner_version=$RUNNER_VERSION
display_backend=$DISPLAY_BACKEND
graphics_backend=$GRAPHICS_BACKEND
wined3d_renderer=$WINED3D_RENDERER
graphics_profile=$GRAPHICS_PROFILE_VERSION
signing_profile=$SIGNING_PROFILE_VERSION
font_profile=$FONT_PROFILE_VERSION
line_version=${version:-unknown}
updated_at=$(date -Is)
STATE
  # Compatibility path for existing tooling that reads the old location.
  ln -sfn "$state_file" "$APP_HOME/state.env"
}
