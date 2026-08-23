#!/usr/bin/env bash

generate_compat_certificate() {
  local cert="$SIGNING_HOME/cert.pem"
  local key="$SIGNING_HOME/key.pem"
  [[ -s "$cert" && -s "$key" ]] && return 0

  warn "Creating a LOCAL self-signed compatibility certificate. It is NOT issued by Microsoft."
  run mkdir -p "$SIGNING_HOME"
  run chmod 0700 "$SIGNING_HOME"
  run openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$key" -out "$cert" -config "$SIGNING_CONFIG"
  run chmod 0600 "$key"
}

has_compat_signature() {
  local file=$1 out current calculated
  # osslsigncode exits non-zero for our intentionally self-signed chain even
  # when the embedded Authenticode signature itself is present and valid.
  out=$("$OSSLSIGNCODE" verify -in "$file" 2>&1 || true)
  grep -Fq 'CN=Microsoft Windows' <<<"$out" || return 1
  current=$(awk '/Current message digest/{print $NF; exit}' <<<"$out")
  calculated=$(awk '/Calculated message digest/{print $NF; exit}' <<<"$out")
  [[ -n "$current" && "$current" == "$calculated" ]]
}

sign_one_dll() {
  local dll=$1 cert="$SIGNING_HOME/cert.pem" key="$SIGNING_HOME/key.pem"
  local tmp="${dll}.line-linux-helper.$$"

  has_compat_signature "$dll" && return 0

  if "$OSSLSIGNCODE" sign -certs "$cert" -key "$key" -h sha256 \
      -n 'Microsoft Windows' -in "$dll" -out "$tmp" >/dev/null 2>&1; then
    chmod --reference="$dll" "$tmp" 2>/dev/null || true
    mv -f "$tmp" "$dll"
    return 0
  fi
  rm -f "$tmp"
  return 1
}

verify_critical_signatures() {
  local critical=(crypt32.dll winhttp.dll version.dll)
  local dll
  for dll in "${critical[@]}"; do
    local path="$PREFIX/drive_c/windows/system32/$dll"
    [[ -f "$path" ]] || die "Critical Wine DLL missing: $path"
    has_compat_signature "$path" || die "Critical Wine DLL was not signed successfully: $dll"
  done
}

sign_wine_dlls() {
  if [[ ${DRY_RUN:-0} == 1 ]]; then
    info "Would generate a local compatibility certificate and sign Wine DLLs in: $PREFIX"
    return 0
  fi
  ensure_osslsigncode
  generate_compat_certificate

  local failed_log="$CACHE_HOME/signing-failures.txt"
  : > "$failed_log"
  local ok=0 skip=0 fail=0 total=0 dll

  log "Applying compatibility signatures to Wine DLLs inside the isolated LINE prefix"
  while IFS= read -r -d '' dll; do
    total=$((total + 1))
    if has_compat_signature "$dll"; then
      skip=$((skip + 1))
    elif sign_one_dll "$dll"; then
      ok=$((ok + 1))
    else
      fail=$((fail + 1))
      printf '%s\n' "$dll" >> "$failed_log"
    fi
    if (( total % 100 == 0 )); then
      printf '\r    processed=%d signed=%d already=%d skipped/failed=%d' "$total" "$ok" "$skip" "$fail"
    fi
  done < <(find "$PREFIX/drive_c/windows/system32" "$PREFIX/drive_c/windows/syswow64" \
    -type f -iname '*.dll' -print0 2>/dev/null)
  printf '\n'

  verify_critical_signatures
  log "DLL signing complete: signed=$ok already=$skip legacy/unsupported=$fail total=$total"
  (( fail > 0 )) && info "Non-critical signing failures are listed in: $failed_log"
}
