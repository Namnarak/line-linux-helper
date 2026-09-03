# LINE Linux Helper

Unofficial community compatibility/setup helper for running the **official Windows edition of LINE** on Linux through Wine.

> [!IMPORTANT]
> This project is not affiliated with, endorsed by, or supported by LY Corporation or LINE.
>
> No LINE binary is bundled, mirrored, patched, decoded, decompiled, or reverse-engineered. The helper downloads LINE's official Windows bootstrap installer directly from `desktop.line-scdn.net` and runs it inside an isolated Wine prefix.

Thai documentation: [docs/README.th.md](docs/README.th.md)

## Why this exists

Recent LINE Desktop builds can reject Wine system DLLs with an error such as:

```text
Security verification failed.
File: C:\windows\system32\CRYPT32.dll
Reason: NO_SIGNATURE
```

`line-linux-helper` prepares an isolated compatibility environment and applies the current community workaround only inside that prefix.

## Stable compatibility profile

Version 0.3 intentionally uses a conservative desktop-app profile:

```text
Runtime:   Wine Staging 11.16 (Kron4ek amd64-wow64 build)
Display:   X11 / XWayland
Graphics:  WineD3D
Renderer:  OpenGL
DXVK:      not managed / not required
Wayland:   native Wine Wayland is not enabled in the stable profile
```

The runner is pinned and verified before use:

```text
Runner: wine-11.16-staging-amd64-wow64
SHA256: 746d3d571e474a7a603e084a0d35649699c3d5c98e5ea3e9994e1e5fa693af92
```

The WoW64 build is used to reduce dependency on 32-bit host libraries. It still requires the normal 64-bit libraries expected by Wine.

### Why Wine Staging instead of Proton?

LINE is a desktop application, not a game. v0.3 therefore moves away from the old Proton-derived runner and uses Wine Staging directly. This keeps useful compatibility patches while avoiding a gaming-oriented runtime profile and makes the graphics path easier to reason about.

The stable profile deliberately stays on WineD3D/OpenGL. Wine's Vulkan renderer remains optional upstream and is not yet the default, and this helper does not install DXVK.

## What the helper does

1. Detects the Linux distribution/package manager.
2. Downloads the pinned Wine Staging WoW64 runner.
3. Verifies the runner SHA-256.
4. Checks the runner for obviously missing host libraries.
5. Creates or migrates a dedicated 64-bit Wine prefix for LINE.
6. Pins the managed graphics profile to WineD3D/OpenGL on X11/XWayland.
7. Installs Noto/Thai/CJK fallback fonts and applies the font-rendering profile.
8. Generates a local self-signed compatibility certificate.
9. Adds Authenticode signatures to Wine DLLs inside the isolated prefix.
10. Downloads `LineInst.exe` directly from LINE's official CDN.
11. Runs LINE's own installer.
12. Creates a desktop launcher and provides diagnostics/repair commands.

When the pinned Wine runtime changes, the helper runs `wineboot -u`, invalidates the old signing marker, and reapplies compatibility fixes instead of silently reusing a prefix prepared by another runner.

## Quick start

```bash
git clone https://github.com/Namnarak/line-linux-helper.git
cd line-linux-helper
./install.sh
```

Optional source bootstrap:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Namnarak/line-linux-helper/main/bootstrap.sh)
```

Then:

```bash
line-linux launch
line-linux doctor
line-linux graphics
```

## Commands

```text
line-linux install [--dry-run] [--no-packages] [--no-desktop] [--prefix PATH]
line-linux launch [--prefix PATH]
line-linux update [--prefix PATH]
line-linux repair [--fonts|--graphics|--signatures] [--no-packages] [--prefix PATH]
line-linux doctor [--prefix PATH]
line-linux graphics [--prefix PATH]
line-linux status [--prefix PATH]
line-linux uninstall [--yes]
line-linux disclaimer
line-linux version
```

### Component repair

A normal repair refreshes the full managed compatibility profile:

```bash
line-linux repair
```

Targeted repairs are available when the runtime itself has not changed:

```bash
line-linux repair --fonts
line-linux repair --graphics
line-linux repair --signatures
```

If a runtime migration is detected during a targeted repair, the helper automatically promotes it to a full repair because changing Wine can replace DLLs and invalidate compatibility signatures.

## Graphics diagnostics

```bash
line-linux graphics
```

The command reports the managed display/graphics profile, X11/XWayland availability, host OpenGL renderer when `glxinfo` is available, software-rendering fallbacks such as llvmpipe, Wine runtime linkage, and the prefix graphics profile.

Example:

```text
Managed display:           xwayland
Managed graphics:          wined3d
WineD3D renderer:          gl
Host OpenGL renderer:      Mesa Intel(R) Graphics
Hardware acceleration:     appears available
Wine host libraries:       OK
Prefix graphics profile:   OK
```

`mesa-utils`/equivalent is installed on a best-effort basis for richer diagnostics. Its absence does not block LINE.

## Font rendering

The helper applies:

- Noto Sans / Noto Sans Thai host fallbacks,
- CJK fallback through Winetricks,
- RGB subpixel smoothing,
- gamma 1400,
- 96 DPI,
- Windows UI font replacements for missing families.

No font files are stored in this repository.

## Supported distributions

Automatic dependency installation targets:

| Family | Examples | Status |
| --- | --- | --- |
| Arch | Arch Linux, CachyOS, Manjaro, EndeavourOS | Tested installer path |
| Debian/Ubuntu | Debian, Ubuntu, Linux Mint, Pop!_OS | Supported installer path |
| Fedora | Fedora, Nobara | Supported installer path |
| openSUSE | Tumbleweed, Leap | Supported installer path |
| Other | x86_64 distro with dependencies installed | `--no-packages` |

Immutable/OSTree systems are detected and the helper intentionally does not mutate the host package database automatically.

NixOS, Alpine/musl and non-x86_64 systems are not currently claimed as supported.

## Security model

Only Wine DLLs inside the dedicated LINE prefix are signed. The signing key is generated locally, stored with restrictive permissions, and never uploaded by the helper.

The generated certificate is **self-signed and is not issued by Microsoft**. Windows-like subject metadata is part of the current compatibility workaround; it does not turn the certificate into a Microsoft trust certificate.

Read [SECURITY.md](SECURITY.md) for the full threat model.

## What the project does not do

- It does not provide a native Linux port of LINE.
- It does not bundle or redistribute LINE binaries.
- It does not patch `LINE.exe`.
- It does not modify system Wine prefixes globally.
- It does not install or manage DXVK in the stable profile.
- It does not enable Wine's native Wayland driver in the stable profile.
- It does not guarantee that LINE calling/video/notification features unsupported by Wine will always work.

## Troubleshooting

Start with:

```bash
line-linux doctor
line-linux graphics
```

If a Wine runtime update or prefix migration makes `NO_SIGNATURE` return:

```bash
line-linux repair --signatures
```

For font issues:

```bash
line-linux repair --fonts
```

For graphics-profile drift:

```bash
line-linux repair --graphics
```

To re-run LINE's official bootstrap installer:

```bash
line-linux update
```

More details: [docs/troubleshooting.md](docs/troubleshooting.md)

## Development

```bash
tests/smoke.sh
```

CI rejects bundled Windows/LINE binaries and private signing material.

## License

The helper code is released under the MIT License. That license applies only to this project's code, not to LINE, Wine, Kron4ek Wine-Builds, Winetricks, or software downloaded at runtime.
