#!/usr/bin/env bash

doctor_line() {
  local failures=0
  printf '%sLINE Linux Helper Doctor%s\n\n' "$C_BOLD" "$C_RESET"

  detect_distro
  printf '%-24s %s\n' 'Distribution:' "${PRETTY_NAME:-$DISTRO_ID}"
  printf '%-24s %s\n' 'Architecture:' "$(uname -m)"
  printf '%-24s %s\n' 'Session:' "${XDG_SESSION_TYPE:-unknown}"
  printf '%-24s %s\n' 'DISPLAY:' "${DISPLAY:-none}"
  printf '%-24s %s\n' 'Prefix:' "$PREFIX"

  RUNNER_BIN="$RUNNERS_HOME/$RUNNER_NAME/bin"
  if [[ -x "$RUNNER_BIN/wine" ]]; then
    printf '%-24s %s\n' 'Runner:' "$("$RUNNER_BIN/wine" --version 2>/dev/null || echo present)"
  else
    printf '%-24s %s\n' 'Runner:' 'MISSING'
    failures=$((failures + 1))
  fi

  if [[ -f "$PREFIX/system.reg" ]]; then
    printf '%-24s %s\n' 'Wine prefix:' 'OK'
  else
    printf '%-24s %s\n' 'Wine prefix:' 'MISSING'
    failures=$((failures + 1))
  fi

  local launcher exe
  launcher=$(find_line_launcher)
  exe=$(find_line_exe)
  if [[ -n "$launcher" && -n "$exe" ]]; then
    printf '%-24s %s\n' 'LINE installation:' 'FOUND'
    printf '%-24s %s\n' 'LINE executable:' "$exe"
  else
    printf '%-24s %s\n' 'LINE installation:' 'NOT FOUND'
    failures=$((failures + 1))
  fi

  local verifier=''
  if command -v osslsigncode >/dev/null 2>&1; then
    verifier=$(command -v osslsigncode)
  elif [[ -x "$TOOLS_HOME/osslsigncode-$OSSLSIGNCODE_TAG/osslsigncode" ]]; then
    verifier="$TOOLS_HOME/osslsigncode-$OSSLSIGNCODE_TAG/osslsigncode"
  fi

  if [[ -n "$verifier" && -f "$PREFIX/drive_c/windows/system32/crypt32.dll" ]]; then
    local verify_out current_digest calculated_digest
    verify_out=$("$verifier" verify -in "$PREFIX/drive_c/windows/system32/crypt32.dll" 2>&1 || true)
    current_digest=$(awk '/Current message digest/{print $NF; exit}' <<<"$verify_out")
    calculated_digest=$(awk '/Calculated message digest/{print $NF; exit}' <<<"$verify_out")
    if grep -Fq 'CN=Microsoft Windows' <<<"$verify_out" && [[ -n "$current_digest" && "$current_digest" == "$calculated_digest" ]]; then
      printf '%-24s %s\n' 'Compatibility signature:' 'OK'
    else
      printf '%-24s %s\n' 'Compatibility signature:' 'MISSING / REPAIR NEEDED'
      failures=$((failures + 1))
    fi
  else
    printf '%-24s %s\n' 'Compatibility signature:' 'UNKNOWN (verifier unavailable)'
  fi

  local prefix_running=0 proc cmd
  for proc in /proc/[0-9]*; do
    [[ -r "$proc/environ" && -r "$proc/cmdline" ]] || continue
    if { tr '\0' '\n' < "$proc/environ"; } 2>/dev/null | grep -Fxq "WINEPREFIX=$PREFIX"; then
      cmd=$({ tr '\0' ' ' < "$proc/cmdline"; } 2>/dev/null || true)
      if [[ "$cmd" == *'LINE.exe'* ]]; then
        prefix_running=1
        break
      fi
    fi
  done
  if [[ $prefix_running == 1 ]]; then
    printf '%-24s %s\n' 'LINE process:' 'RUNNING (this prefix)'
  else
    printf '%-24s %s\n' 'LINE process:' 'not running'
  fi

  printf '\n'
  if (( failures == 0 )); then
    printf '%sRESULT: PASS%s\n' "$C_GREEN" "$C_RESET"
  else
    printf '%sRESULT: %d issue(s) found%s\n' "$C_YELLOW" "$failures" "$C_RESET"
    printf 'Try: line-linux repair\n'
  fi
  return "$failures"
}
