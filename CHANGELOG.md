# Changelog

## 0.3.0 — 2026-09-03

- Replace the Proton-derived compatibility runner with pinned **Wine Staging 11.16**.
- Switch to Kron4ek's `amd64-wow64` build to reduce reliance on 32-bit host libraries.
- Add runtime migration markers; an existing prefix is upgraded with `wineboot -u` when the pinned runner changes.
- Invalidate compatibility-signature markers after runtime migration so replaced Wine DLLs are re-signed.
- Add an explicit stable graphics profile: **X11/XWayland + WineD3D + OpenGL**.
- Add `line-linux graphics` diagnostics with host OpenGL/software-renderer detection when `glxinfo` is available.
- Add runner linkage checks for obviously missing host libraries.
- Add component repair modes: `--fonts`, `--graphics`, and `--signatures`.
- Promote targeted repair to a full repair automatically when a Wine runtime migration is detected.
- Improve dependency setup with `cabextract`, `unzip`, best-effort graphics diagnostics packages, and packaged `osslsigncode` when available.
- Expand persisted state with runtime and graphics profile information.
- Keep DXVK and native Wine Wayland out of the stable profile until separately tested.

## 0.2.1 — 2026-08-23

- Fix CI ShellCheck annotations in the new logic test.
- No compatibility-profile change from 0.2.0.

## 0.2.0 — 2026-08-23

- Add operation locking to prevent concurrent install/update/repair corruption.
- Make DLL signing and CJK font repair incremental for much faster repeated repairs.
- Add helper and detected LINE versions to `doctor`.
- Add Liberation Sans as a metric-compatible Arial fallback while keeping Noto Sans/Thai for UI glyph coverage.
- Expand build dependencies for local `osslsigncode` compilation across distro families.
- Add optional one-command GitHub source bootstrap; LINE binaries are still fetched only from LINE's official CDN.
- Preserve the no-bundled-binaries/private-key CI policy.

## 0.1.1 — 2026-08-23

- Fix ShellCheck/CI issues in the initial release.
- Improve distro-family detection and desktop-cache handling.
- Confirm full rendered LINE UI in the CachyOS KDE/Wayland smoke test.
- Strengthen signature verification by checking Authenticode digest equality.

## 0.1.0 — 2026-08-23

- Initial public release.
- Automatic setup path for Arch, Debian/Ubuntu, Fedora and openSUSE families.
- Pinned Kron4ek Wine Proton 11.0-1 with SHA-256 verification.
- Isolated Wine prefix and CJK font setup.
- Local self-signed Wine DLL compatibility-signature workaround.
- LINE bootstrap fetched directly from the official LINE CDN at runtime.
- `install`, `launch`, `update`, `repair`, `doctor` and `uninstall` commands.
- KDE/GNOME desktop launcher integration.
- CI guard preventing bundled Windows/LINE binaries and private signing material.
- End-to-end tested on CachyOS KDE/Wayland (XWayland path) with LINE 26.4.2.3957.
