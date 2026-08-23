# Contributing

Contributions are welcome, especially distro detection fixes, diagnostics, documentation and compatibility reports.

## Rules

1. Do not commit or attach LINE binaries/assets to pull requests.
2. Do not commit Wine runner archives, Windows DLLs, private keys or generated certificates.
3. Keep downloads pointed at upstream/official sources.
4. Do not silently add new `sudo` operations.
5. Run `tests/smoke.sh` before opening a pull request.
6. If changing the pinned Wine runner, update the SHA-256 and document a real LINE smoke test.

The goal is a transparent setup helper, not a repackaged LINE distribution.
