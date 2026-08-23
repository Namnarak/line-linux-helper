#!/usr/bin/env bash

ensure_osslsigncode() {
  if command -v osslsigncode >/dev/null 2>&1; then
    OSSLSIGNCODE=$(command -v osslsigncode)
    return 0
  fi

  local tool_dir="$TOOLS_HOME/osslsigncode-$OSSLSIGNCODE_TAG"
  local src="$CACHE_HOME/osslsigncode-src-$OSSLSIGNCODE_TAG"
  local build="$CACHE_HOME/osslsigncode-build-$OSSLSIGNCODE_TAG"
  OSSLSIGNCODE="$tool_dir/osslsigncode"
  [[ -x "$OSSLSIGNCODE" ]] && return 0

  log "Building osslsigncode $OSSLSIGNCODE_TAG locally (no system install)"
  run rm -rf "$src" "$build"
  run git clone --quiet --depth 1 --branch "$OSSLSIGNCODE_TAG" "$OSSLSIGNCODE_REPO" "$src"
  if [[ ${DRY_RUN:-0} != 1 ]]; then
    local got
    got=$(git -C "$src" rev-parse HEAD)
    [[ "$got" == "$OSSLSIGNCODE_COMMIT" ]] || die "osslsigncode commit mismatch: expected $OSSLSIGNCODE_COMMIT, got $got"
  fi
  run cmake -S "$src" -B "$build" -DCMAKE_BUILD_TYPE=Release
  run cmake --build "$build" --parallel
  run mkdir -p "$tool_dir"
  run cp "$build/osslsigncode" "$OSSLSIGNCODE"
  run chmod 0755 "$OSSLSIGNCODE"
}

ensure_runner() {
  local runner_dir="$RUNNERS_HOME/$RUNNER_NAME"
  local archive="$CACHE_HOME/$RUNNER_NAME.tar.xz"
  RUNNER_BIN="$runner_dir/bin"

  if [[ -x "$RUNNER_BIN/wine" && -x "$RUNNER_BIN/wineserver" ]]; then
    info "Wine runner already installed: $runner_dir"
    return 0
  fi

  log "Downloading pinned Kron4ek Wine Proton $RUNNER_VERSION"
  run curl --proto '=https' --tlsv1.2 -fL --retry 3 --connect-timeout 15 \
    "$RUNNER_URL" -o "$archive"

  if [[ ${DRY_RUN:-0} != 1 ]]; then
    local got
    got=$(sha256_file "$archive")
    [[ "$got" == "$RUNNER_SHA256" ]] || die "Runner SHA256 mismatch. Expected $RUNNER_SHA256, got $got"
  fi

  local temp="$CACHE_HOME/runner-extract.$$"
  run rm -rf "$temp"
  run mkdir -p "$temp" "$RUNNERS_HOME"
  run tar -xJf "$archive" -C "$temp"

  if [[ ${DRY_RUN:-0} != 1 ]]; then
    local wine_path root
    wine_path=$(find "$temp" -type f -path '*/bin/wine' -print -quit)
    [[ -n "$wine_path" ]] || die "Downloaded runner does not contain bin/wine"
    root=${wine_path%/bin/wine}
    rm -rf "$runner_dir"
    mv "$root" "$runner_dir"
    rm -rf "$temp"
    RUNNER_BIN="$runner_dir/bin"
    [[ -x "$RUNNER_BIN/wine" ]] || die "Runner installation failed"
    log "Runner installed: $("$RUNNER_BIN/wine" --version)"
  fi
}

ensure_prefix() {
  RUNNER_BIN="$RUNNERS_HOME/$RUNNER_NAME/bin"
  wine_env
  if [[ -f "$PREFIX/system.reg" ]]; then
    info "Wine prefix already exists: $PREFIX"
    return 0
  fi
  log "Creating isolated 64-bit Wine prefix: $PREFIX"
  run mkdir -p "$PREFIX"
  run env WINEPREFIX="$PREFIX" WINEARCH=win64 WINEDEBUG=-all "$RUNNER_BIN/wineboot" -u
}
