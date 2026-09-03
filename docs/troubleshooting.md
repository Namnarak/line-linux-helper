# Troubleshooting

## Start here

Run both checks first:

```bash
line-linux doctor
line-linux graphics
```

`doctor` checks the LINE install, Wine runtime, compatibility signatures, fonts, and managed graphics profile. `graphics` focuses on X11/XWayland, WineD3D/OpenGL, host renderer detection, and obvious missing runtime libraries.

## `CRYPT32.dll` / `NO_SIGNATURE`

Run:

```bash
line-linux repair --signatures
```

A Wine runtime migration can replace Wine DLLs. v0.3 invalidates the old signing marker after `wineboot -u`, but if LINE was interrupted during migration or files changed later, re-signing may still be needed.

For a full compatibility refresh:

```bash
line-linux repair
```

## LINE installer cannot open

The stable profile uses X11/XWayland. Ensure the desktop session exposes a `DISPLAY` variable:

```bash
echo "$DISPLAY"
```

If it is empty, start installation from a graphical desktop session with X11 or XWayland available.

Native Wine Wayland is intentionally not enabled in the v0.3 stable profile.

## Black/blank window or very slow rendering

Run:

```bash
line-linux graphics
```

If `Host OpenGL renderer` reports `llvmpipe`, `softpipe`, or `swrast`, the host is using software rendering. Fix the Linux graphics driver/session first; changing Wine settings is unlikely to solve the root cause.

If the prefix graphics profile is missing:

```bash
line-linux repair --graphics
```

The stable profile is WineD3D + OpenGL. DXVK and WineD3D's Vulkan renderer are not managed by v0.3.

## Wine host libraries are missing

`line-linux graphics` checks the Wine executable with `ldd` when available. If it reports missing libraries, install the corresponding 64-bit runtime packages for your distribution, then run:

```bash
line-linux repair
```

The pinned runner uses Kron4ek's `amd64-wow64` build, so it does not require 32-bit host libraries merely to run WoW64 applications, but normal 64-bit Wine dependencies are still required.

## Fonts are missing or Thai text looks wrong

Run:

```bash
line-linux repair --fonts
```

This restores the CJK fallback marker/profile, RGB font smoothing, gamma 1400, 96 DPI, and Wine font replacements.

## LINE itself needs reinstall/update

```bash
line-linux update
```

This downloads the current bootstrap installer directly from LINE's official CDN again and refreshes the managed graphics/font/signature compatibility profile before running it.

## Migrating from v0.2 / Proton runner

The first v0.3 repair/install detects that the prefix was prepared by another runtime and runs:

```text
Wine Staging download + SHA256 verification
→ wineboot -u
→ invalidate old signing marker
→ reapply graphics/font profile
→ re-sign Wine DLLs
```

Do not manually copy DLLs from the old Proton runner into the new prefix.

## Collect diagnostics for an issue

Include:

```bash
line-linux version
line-linux doctor
line-linux graphics
```

Also include distro name, desktop environment, session type, GPU/driver if known, and the exact LINE error text. Do not upload account credentials, LINE session data, or private signing keys.
