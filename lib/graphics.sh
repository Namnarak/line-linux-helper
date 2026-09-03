#!/usr/bin/env bash

graphics_marker_path() {
  printf '%s/.line-linux-graphics-profile-%s' "$PREFIX" "$GRAPHICS_PROFILE_VERSION"
}

prepare_graphics_env() {
  validate_runtime_config

  case "$DISPLAY_BACKEND" in
    xwayland)
      [[ -n ${DISPLAY:-} ]] || die "No X11/XWayland DISPLAY is available. Run LINE from a graphical desktop session."
      # Keep the compatibility path deterministic on Wayland desktops.
      export XDG_SESSION_TYPE=x11
      unset WAYLAND_DISPLAY || true
      ;;
  esac

  # WineD3D remains the managed graphics backend. Wine 11 still defaults to
  # OpenGL because its Vulkan renderer is not yet at feature parity.
  export WINE_D3D_CONFIG="renderer=$WINED3D_RENDERER"
}

apply_graphics_profile() {
  RUNNER_BIN="$RUNNERS_HOME/$RUNNER_NAME/bin"
  wine_env
  validate_runtime_config

  if [[ ${DRY_RUN:-0} == 1 ]]; then
    info "Would configure display=$DISPLAY_BACKEND graphics=$GRAPHICS_BACKEND renderer=$WINED3D_RENDERER"
    return 0
  fi

  local wine="$RUNNER_BIN/wine"
  log "Applying stable graphics profile: WineD3D/OpenGL via X11/XWayland"
  "$wine" reg add 'HKCU\Software\Wine\Direct3D' /v renderer /t REG_SZ /d "$WINED3D_RENDERER" /f >/dev/null
  touch "$(graphics_marker_path)"
}

graphics_profile_status() {
  RUNNER_BIN="$RUNNERS_HOME/$RUNNER_NAME/bin"
  [[ -x "$RUNNER_BIN/wine" && -f "$PREFIX/system.reg" ]] || return 1
  [[ -f "$(graphics_marker_path)" ]] || return 1

  local actual
  actual=$(WINEPREFIX="$PREFIX" "$RUNNER_BIN/wine" reg query 'HKCU\Software\Wine\Direct3D' /v renderer 2>/dev/null \
    | awk '/renderer/{print $NF}' | tr -d '\r' | tail -1)
  [[ "$actual" == "$WINED3D_RENDERER" ]]
}

host_gl_renderer() {
  command -v glxinfo >/dev/null 2>&1 || return 1
  [[ -n ${DISPLAY:-} ]] || return 1
  glxinfo -B 2>/dev/null | sed -n 's/^[[:space:]]*OpenGL renderer string:[[:space:]]*//p' | head -1
}

graphics_doctor() {
  local failures=0 renderer=''

  printf '%sGraphics diagnostics%s\n\n' "$C_BOLD" "$C_RESET"
  printf '%-26s %s\n' 'Desktop session:' "${XDG_SESSION_TYPE:-unknown}"
  printf '%-26s %s\n' 'DISPLAY:' "${DISPLAY:-none}"
  printf '%-26s %s\n' 'Managed display:' "$DISPLAY_BACKEND"
  printf '%-26s %s\n' 'Managed graphics:' "$GRAPHICS_BACKEND"
  printf '%-26s %s\n' 'WineD3D renderer:' "$WINED3D_RENDERER"

  if [[ -z ${DISPLAY:-} ]]; then
    printf '%-26s %s\n' 'X11/XWayland:' 'UNAVAILABLE'
    failures=$((failures + 1))
  else
    printf '%-26s %s\n' 'X11/XWayland:' 'available'
  fi

  renderer=$(host_gl_renderer 2>/dev/null || true)
  if [[ -n "$renderer" ]]; then
    printf '%-26s %s\n' 'Host OpenGL renderer:' "$renderer"
    case "${renderer,,}" in
      *llvmpipe*|*softpipe*|*swrast*)
        printf '%-26s %s\n' 'Hardware acceleration:' 'NO (software renderer)'
        failures=$((failures + 1))
        ;;
      *) printf '%-26s %s\n' 'Hardware acceleration:' 'appears available' ;;
    esac
  else
    printf '%-26s %s\n' 'Host OpenGL renderer:' 'UNKNOWN (glxinfo unavailable)'
  fi

  RUNNER_BIN="$RUNNERS_HOME/$RUNNER_NAME/bin"
  if [[ -x "$RUNNER_BIN/wine" ]]; then
    if check_runner_dependencies; then
      printf '%-26s %s\n' 'Wine host libraries:' 'OK'
    else
      printf '%-26s %s\n' 'Wine host libraries:' 'MISSING'
      failures=$((failures + 1))
    fi
  else
    printf '%-26s %s\n' 'Wine host libraries:' 'runner missing'
    failures=$((failures + 1))
  fi

  if [[ -f "$PREFIX/system.reg" ]]; then
    if graphics_profile_status; then
      printf '%-26s %s\n' 'Prefix graphics profile:' 'OK'
    else
      printf '%-26s %s\n' 'Prefix graphics profile:' 'MISSING / REPAIR NEEDED'
      failures=$((failures + 1))
    fi
  fi

  printf '\n'
  if (( failures == 0 )); then
    printf '%sRESULT: PASS%s\n' "$C_GREEN" "$C_RESET"
  else
    printf '%sRESULT: %d graphics issue(s)%s\n' "$C_YELLOW" "$failures" "$C_RESET"
  fi
  return "$failures"
}
