# Troubleshooting

## `CRYPT32.dll` / `NO_SIGNATURE`

Run:

```bash
line-linux doctor
line-linux repair
```

A Wine runner/prefix update may have replaced signed Wine DLLs.

## LINE installer cannot open

The tested path uses XWayland. Ensure the desktop session exposes a `DISPLAY` variable:

```bash
echo "$DISPLAY"
```

If it is empty, start installation from a graphical desktop session with XWayland available.

## Fonts are missing

Run:

```bash
line-linux repair
```

Repair re-applies the `cjkfonts` Winetricks dependency before checking signatures.

## LINE itself needs reinstall/update

```bash
line-linux update
```

This downloads the current bootstrap installer directly from LINE's official CDN again.

## Collect basic diagnostics

```bash
line-linux doctor
```

When opening an issue, include the doctor output, distro name, desktop environment, session type, and the exact LINE security dialog text. Do not upload account credentials or private signing keys.
