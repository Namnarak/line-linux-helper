#!/usr/bin/env bash

prepare_graphics_env() {
  if [[ -n ${DISPLAY:-} ]]; then
    # The tested compatibility profile uses XWayland rather than Wine's native Wayland path.
    export XDG_SESSION_TYPE=x11
    unset WAYLAND_DISPLAY || true
  fi
}

download_line_installer() {
  if [[ ${DRY_RUN:-0} == 1 ]]; then
    info "Would download LINE directly from: $LINE_INSTALLER_URL"
    return 0
  fi
  local out="$CACHE_HOME/LineInst.exe"
  local meta="$CACHE_HOME/LineInst.meta"
  local effective

  log "Downloading LINE bootstrap installer directly from the official LINE CDN"
  effective=$(curl --proto '=https' --tlsv1.2 -fL --retry 3 --connect-timeout 15 \
    -w '%{url_effective}' -o "$out" "$LINE_INSTALLER_URL") || die "Failed to download LINE installer"

  local host=${effective#*://}
  host=${host%%/*}
  host=${host%%:*}
  case "$host" in
    "$LINE_ALLOWED_HOST_SUFFIX"|*."$LINE_ALLOWED_HOST_SUFFIX") ;;
    *) rm -f "$out"; die "LINE download redirected outside the allowed CDN: $effective" ;;
  esac

  [[ "$(head -c 2 "$out" 2>/dev/null)" == 'MZ' ]] || die "Downloaded LINE installer is not a Windows PE executable"
  local size hash
  size=$(stat -c '%s' "$out")
  (( size > 100000 )) || die "Downloaded LINE installer is unexpectedly small ($size bytes)"
  hash=$(sha256_file "$out")
  printf 'url=%s\nsha256=%s\nsize=%s\ndownloaded_at=%s\n' "$effective" "$hash" "$size" "$(date -Is)" > "$meta"
  log "LINE installer downloaded from $host (sha256=$hash)"
}

install_line() {
  RUNNER_BIN="$RUNNERS_HOME/$RUNNER_NAME/bin"
  wine_env

  if [[ ${DRY_RUN:-0} == 1 ]]; then
    download_line_installer
    info "Would run the official LINE installer inside: $PREFIX"
    return 0
  fi

  prepare_graphics_env
  [[ -n ${DISPLAY:-} ]] || die "No graphical DISPLAY is available. Run installation from a desktop session."

  download_line_installer
  local installer="$CACHE_HOME/LineInst.exe"
  run cp -f "$installer" "$PREFIX/drive_c/LineInst.exe"

  log "Starting the official LINE installer"
  info "LINE itself is installed/downloaded by LINE's own bootstrapper; this project does not bundle it."
  run env WINEPREFIX="$PREFIX" WINEARCH=win64 WINEDEBUG=-all "$RUNNER_BIN/wine" 'C:\LineInst.exe'

  if [[ ${DRY_RUN:-0} == 1 ]]; then return 0; fi

  local launcher=''
  for _ in $(seq 1 30); do
    launcher=$(find_line_launcher)
    [[ -n "$launcher" ]] && break
    sleep 1
  done
  [[ -n "$launcher" ]] || die "LINE installer exited but LineLauncher.exe was not found"
  log "LINE installation detected: $launcher"
}

launch_line() {
  RUNNER_BIN="$RUNNERS_HOME/$RUNNER_NAME/bin"
  [[ -x "$RUNNER_BIN/wine" ]] || die "Wine runner is missing. Run: line-linux repair"
  [[ -f "$PREFIX/system.reg" ]] || die "LINE prefix is missing. Run: line-linux install"
  local launcher
  launcher=$(find_line_launcher)
  [[ -n "$launcher" ]] || die "LINE launcher not found. Run: line-linux install"

  wine_env
  prepare_graphics_env
  local win_launcher
  win_launcher=$(env WINEPREFIX="$PREFIX" "$RUNNER_BIN/winepath" -w "$launcher")
  export WINEDEBUG=-all
  exec "$RUNNER_BIN/wine" "$win_launcher"
}
