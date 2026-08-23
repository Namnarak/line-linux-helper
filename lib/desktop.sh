#!/usr/bin/env bash

install_desktop_entry() {
  local icon="$ICON_HOME/line-linux-helper.png"
  local icon_source=''
  icon_source=$(find "$PREFIX/drive_c/users" -type f \
    -path '*/AppData/Local/LINE/bin/current/assets/Square310x310Logo.scale-100.png' -print -quit 2>/dev/null || true)

  run mkdir -p "$DESKTOP_HOME" "$ICON_HOME"
  if [[ -n "$icon_source" ]]; then
    run cp -f "$icon_source" "$icon"
  fi

  local desktop="$DESKTOP_HOME/line-linux-helper.desktop"
  if [[ ${DRY_RUN:-0} == 1 ]]; then
    info "Would write desktop entry: $desktop"
    return 0
  fi

  cat > "$desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=LINE
GenericName=Instant Messenger
Comment=LINE Desktop via line-linux-helper
Exec=$BIN_HOME/line-linux launch
Icon=${icon_source:+$icon}
Terminal=false
Categories=Network;InstantMessaging;Chat;
StartupNotify=true
StartupWMClass=LINE
X-GNOME-UsesNotifications=true
DESKTOP
  if [[ -z "$icon_source" ]]; then
    sed -i 's|^Icon=$|Icon=internet-chat|' "$desktop"
  fi
  chmod 0644 "$desktop"

  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_HOME" >/dev/null 2>&1 || true
  command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 >/dev/null 2>&1 || true
  log "Desktop launcher installed"
}
