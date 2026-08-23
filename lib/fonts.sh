#!/usr/bin/env bash

apply_font_profile() {
  RUNNER_BIN="$RUNNERS_HOME/$RUNNER_NAME/bin"
  wine_env

  log "Applying LINE font rendering profile (Noto fallback + RGB smoothing + 96 DPI)"

  # Source Han Sans/Unifont provide reliable CJK fallback inside the prefix.
  # Thai and general UI glyphs are provided by the distro Noto packages and
  # exposed to Wine through fontconfig.
  run env WINEPREFIX="$PREFIX" WINEARCH=win64 \
    WINE="$RUNNER_BIN/wine" WINESERVER="$RUNNER_BIN/wineserver" \
    winetricks -q cjkfonts

  if [[ ${DRY_RUN:-0} == 1 ]]; then
    info "Would configure RGB font smoothing, 96 DPI and Wine font replacements"
    return 0
  fi

  local wine="$RUNNER_BIN/wine"

  # Equivalent to Winetricks fontsmooth=rgb, kept inline so repair does not
  # depend on the verb implementation changing between winetricks releases.
  "$wine" reg add 'HKCU\Control Panel\Desktop' /v FontSmoothing \
    /t REG_SZ /d 2 /f >/dev/null
  "$wine" reg add 'HKCU\Control Panel\Desktop' /v FontSmoothingType \
    /t REG_DWORD /d 2 /f >/dev/null
  "$wine" reg add 'HKCU\Control Panel\Desktop' /v FontSmoothingGamma \
    /t REG_DWORD /d 1400 /f >/dev/null
  "$wine" reg add 'HKCU\Control Panel\Desktop' /v FontSmoothingOrientation \
    /t REG_DWORD /d 1 /f >/dev/null
  "$wine" reg add 'HKCU\Control Panel\Desktop' /v LogPixels \
    /t REG_DWORD /d 96 /f >/dev/null

  # Wine-specific replacements apply only when the requested Windows family is
  # missing. We do not copy or redistribute font files; Wine resolves these
  # host-installed OFL fonts through fontconfig.
  local replacements='HKCU\Software\Wine\Fonts\Replacements'
  "$wine" reg add "$replacements" /v 'Segoe UI' /t REG_SZ /d 'Noto Sans' /f >/dev/null
  "$wine" reg add "$replacements" /v 'Segoe UI Variable' /t REG_SZ /d 'Noto Sans' /f >/dev/null
  "$wine" reg add "$replacements" /v 'Segoe UI Semibold' /t REG_SZ /d 'Noto Sans' /f >/dev/null
  "$wine" reg add "$replacements" /v 'Tahoma' /t REG_SZ /d 'Noto Sans' /f >/dev/null
  "$wine" reg add "$replacements" /v 'Arial' /t REG_SZ /d 'Noto Sans' /f >/dev/null
  "$wine" reg add "$replacements" /v 'Arial Unicode MS' /t REG_SZ /d 'Noto Sans' /f >/dev/null
  "$wine" reg add "$replacements" /v 'Microsoft Sans Serif' /t REG_SZ /d 'Noto Sans' /f >/dev/null
  "$wine" reg add "$replacements" /v 'Leelawadee UI' /t REG_SZ /d 'Noto Sans Thai' /f >/dev/null
  "$wine" reg add "$replacements" /v 'Leelawadee UI Semilight' /t REG_SZ /d 'Noto Sans Thai' /f >/dev/null

  # These Wine X11 switches improve GDI client-side antialiasing under XWayland.
  local x11='HKCU\Software\Wine\X11 Driver'
  "$wine" reg add "$x11" /v ClientSideAntiAliasWithCore /t REG_SZ /d Y /f >/dev/null
  "$wine" reg add "$x11" /v ClientSideAntiAliasWithRender /t REG_SZ /d Y /f >/dev/null

  log "Font profile applied"
}

font_profile_status() {
  RUNNER_BIN="$RUNNERS_HOME/$RUNNER_NAME/bin"
  [[ -x "$RUNNER_BIN/wine" && -f "$PREFIX/system.reg" ]] || return 1

  local wine="$RUNNER_BIN/wine" type gamma dpi
  type=$(WINEPREFIX="$PREFIX" "$wine" reg query 'HKCU\Control Panel\Desktop' /v FontSmoothingType 2>/dev/null | awk '/FontSmoothingType/{print $NF}' | tr -d '\r' | tail -1)
  gamma=$(WINEPREFIX="$PREFIX" "$wine" reg query 'HKCU\Control Panel\Desktop' /v FontSmoothingGamma 2>/dev/null | awk '/FontSmoothingGamma/{print $NF}' | tr -d '\r' | tail -1)
  dpi=$(WINEPREFIX="$PREFIX" "$wine" reg query 'HKCU\Control Panel\Desktop' /v LogPixels 2>/dev/null | awk '/LogPixels/{print $NF}' | tr -d '\r' | tail -1)

  [[ "$type" == 0x2 && "$gamma" == 0x578 && "$dpi" == 0x60 ]]
}
