HELPER_VERSION="0.2.0"
SIGNING_PROFILE_VERSION="2"
FONT_PROFILE_VERSION="2"
CJK_PROFILE_VERSION="1"

# Pinned compatibility profile. Update only after testing.
RUNNER_NAME="wine-proton-11.0-1-amd64"
RUNNER_VERSION="11.0-1"
RUNNER_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/proton-11.0-1/wine-proton-11.0-1-amd64.tar.xz"
RUNNER_SHA256="270dcbc3fdea9a19f1b60caed99fd8040639fb4626c69d424d0efdb12eb67b9f"

# Official LINE bootstrap installer. No LINE binary is stored in this repository.
LINE_INSTALLER_URL="https://desktop.line-scdn.net/win/new/LineInst.exe"
LINE_ALLOWED_HOST_SUFFIX="line-scdn.net"

# osslsigncode is built locally only when the distro does not provide it.
OSSLSIGNCODE_REPO="https://github.com/mtrojnar/osslsigncode.git"
OSSLSIGNCODE_TAG="2.14"
OSSLSIGNCODE_COMMIT="beec94e308d1a1e03ca17b05fe089d93c6303e90"
