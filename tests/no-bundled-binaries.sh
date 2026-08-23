#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

bad=$(find . -type f \( \
  -iname '*.exe' -o -iname '*.dll' -o -iname '*.msi' -o -iname '*.msix' -o \
  -iname '*.appx' -o -iname '*.zip' -o -iname '*.7z' -o -iname '*.tar.xz' -o \
  -iname '*.pfx' -o -iname '*.p12' -o -iname '*.key' -o -iname '*.pem' \
\) -not -path './.git/*' -print)

if [[ -n "$bad" ]]; then
  echo 'ERROR: bundled binary/private material found:' >&2
  echo "$bad" >&2
  exit 1
fi

echo 'OK: no bundled LINE/Windows/runtime binaries or private signing material.'
