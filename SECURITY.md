# Security

## Scope

`line-linux-helper` intentionally creates a dedicated Wine prefix and applies a compatibility signature workaround to Wine DLLs inside that prefix.

It does **not** patch or re-sign LINE binaries.

## Local compatibility certificate

A new RSA private key and self-signed certificate are generated locally per installation under:

```text
~/.local/share/line-linux-helper/signing/
```

The private key is created with permission mode `0600` and is never uploaded by the project.

The certificate contains Windows-like subject metadata used by the current compatibility workaround. It is **not issued by Microsoft** and does not establish Microsoft trust.

Because this workaround weakens the intent of LINE's system-DLL provenance check inside this Wine prefix, the prefix should be dedicated to LINE only. Do not use it as a general Wine prefix for unrelated Windows software.

## Supply chain

- LINE is fetched from `https://desktop.line-scdn.net/win/new/LineInst.exe` at runtime.
- The downloader rejects redirects outside the `line-scdn.net` domain suffix.
- The Kron4ek runner is pinned to an upstream GitHub release and its SHA-256 is verified before extraction.
- If `osslsigncode` is unavailable, source is cloned from upstream at a pinned tag and its Git commit is checked before building locally.
- No `.exe`, `.dll`, `.msi`, Wine runner archive, LINE asset, private key, or generated certificate should be committed to this repository.

## Reporting

Please open a GitHub issue for compatibility bugs. For a security vulnerability in the helper itself, use GitHub's private vulnerability reporting if enabled for the repository.
