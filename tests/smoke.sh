#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

mapfile -t scripts < <(find . -type f -name '*.sh' -not -path './.git/*' | sort)
for script in "${scripts[@]}"; do
  bash -n "$script"
done

tests/no-bundled-binaries.sh
tests/logic.sh

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -x install.sh uninstall.sh bootstrap.sh bin/line-linux lib/*.sh tests/*.sh
else
  echo 'INFO: shellcheck not installed; syntax/no-binary checks still passed.'
fi

echo 'Smoke tests passed.'

grep -q 'HELPER_VERSION="0.2.0"' config/manifest.sh || { echo "Missing helper version" >&2; exit 1; }
