#!/usr/bin/env bash

apply_font_profile() {
  RUNNER_BIN="$RUNNERS_HOME/$RUNNER_NAME/bin"
  wine_env

  log "Applying LINE font rendering profile (Noto fallback + RGB smoothing + 96 DPI)"

  # Source Han Sans/Unifont provide reliable CJK fallback inside the prefix.
  # Avoid rerunning the relatively slow Winetricks font registration on every repair.
  local cjk_marker="$PREFIX/.line-linux-cjk-fonts-$CJK_PROFILE_VERSION"
  if [[ ! -f "$cjk_marker" ]]; then
    run env WINEPREFIX="$PREFIX" WINEARCH=win64 \
      WINE="$RUNNER_BIN/wine" WINESERVER="$RUNNER_BIN/wineserver" \
      winetricks -q cjkfonts
    [[ ${DRY_RUN:-0} == 1 ]] || touch "$cjk_marker"
  else
    info "CJK fallback profile is already installed"
  fi

  if [[ ${DRY_RUN:-0} == 1 ]]; then
    info "Would configure RGB font smoothing, 96 DPI and Wine font replacements"
    return 0
  fi

  local wine="$RUNNER_BIN/wine"
  local latin_ui='Noto Sans' metric_sans='Noto Sans' thai_ui='Noto Sans'
  if command -v fc-match >/dev/null 2>&1; then
    local family
    family=$(fc-match -f '%{family}' 'Noto Sans' 2>/dev/null | head -1 || true)
    [[ "$family" == *'Noto Sans'* ]] && latin_ui='Noto Sans'
    family=$(fc-match -f '%{family}' 'Liberation Sans' 2>/dev/null | head -1 || true)
    [[ "$family" == *'Liberation Sans'* ]] && metric_sans='Liberation Sans'
    family=$(fc-match -f '%{family}' 'Noto Sans Thai' 2>/dev/null | head -1 || true)
    [[ "$family" == *'Noto Sans Thai'* ]] && thai_ui='Noto Sans Thai'
  fi
  info "Font families: UI=$latin_ui, metric-sans=$metric_sans, Thai=$thai_ui"

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
  "$wine" reg add "$replacements" /v 'Segoe UI' /t REG_SZ /d "$latin_ui" /f >/dev/null
  "$wine" reg add "$replacements" /v 'Segoe UI Variable' /t REG_SZ /d "$latin_ui" /f >/dev/null
  "$wine" reg add "$replacements" /v 'Segoe UI Semibold' /t REG_SZ /d "$latin_ui" /f >/dev/null
  "$wine" reg add "$replacements" /v 'Tahoma' /t REG_SZ /d "$latin_ui" /f >/dev/null
  "$wine" reg add "$replacements" /v 'Arial' /t REG_SZ /d "$metric_sans" /f >/dev/null
  "$wine" reg add "$replacements" /v 'Arial Unicode MS' /t REG_SZ /d "$latin_ui" /f >/dev/null
  "$wine" reg add "$replacements" /v 'Microsoft Sans Serif' /t REG_SZ /d "$metric_sans" /f >/dev/null
  "$wine" reg add "$replacements" /v 'Leelawadee UI' /t REG_SZ /d "$thai_ui" /f >/dev/null
  "$wine" reg add "$replacements" /v 'Leelawadee UI Semilight' /t REG_SZ /d "$thai_ui" /f >/dev/null

  # These Wine X11 switches improve GDI client-side antialiasing under XWayland.
  local x11='HKCU\Software\Wine\X11 Driver'
  "$wine" reg add "$x11" /v ClientSideAntiAliasWithCore /t REG_SZ /d Y /f >/dev/null
  "$wine" reg add "$x11" /v ClientSideAntiAliasWithRender /t REG_SZ /d Y /f >/dev/null

  touch "$PREFIX/.line-linux-font-profile-$FONT_PROFILE_VERSION"
  log "Font profile applied"
}

font_profile_status() {
  RUNNER_BIN="$RUNNERS_HOME/$RUNNER_NAME/bin"
  [[ -x "$RUNNER_BIN/wine" && -f "$PREFIX/system.reg" ]] || return 1
  [[ -f "$PREFIX/.line-linux-font-profile-$FONT_PROFILE_VERSION" ]] || return 1

  local wine="$RUNNER_BIN/wine" type gamma dpi
  type=$(WINEPREFIX="$PREFIX" "$wine" reg query 'HKCU\Control Panel\Desktop' /v FontSmoothingType 2>/dev/null | awk '/FontSmoothingType/{print $NF}' | tr -d '\r' | tail -1)
  gamma=$(WINEPREFIX="$PREFIX" "$wine" reg query 'HKCU\Control Panel\Desktop' /v FontSmoothingGamma 2>/dev/null | awk '/FontSmoothingGamma/{print $NF}' | tr -d '\r' | tail -1)
  dpi=$(WINEPREFIX="$PREFIX" "$wine" reg query 'HKCU\Control Panel\Desktop' /v LogPixels 2>/dev/null | awk '/LogPixels/{print $NF}' | tr -d '\r' | tail -1)

  [[ "$type" == 0x2 && "$gamma" == 0x578 && "$dpi" == 0x60 ]]
}
