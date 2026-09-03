HELPER_VERSION="0.3.0"
SIGNING_PROFILE_VERSION="2"
FONT_PROFILE_VERSION="2"
CJK_PROFILE_VERSION="1"
GRAPHICS_PROFILE_VERSION="1"

# Pinned compatibility runtime. This is Wine Staging, not Proton.
# The amd64-wow64 build avoids requiring 32-bit host libraries for WoW64 apps.
RUNTIME_FAMILY="wine-staging"
RUNNER_NAME="wine-11.16-staging-amd64-wow64"
RUNNER_VERSION="11.16"
RUNNER_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/11.16/wine-11.16-staging-amd64-wow64.tar.xz"
RUNNER_SHA256="746d3d571e474a7a603e084a0d35649699c3d5c98e5ea3e9994e1e5fa693af92"

# Conservative graphics profile: X11/XWayland + WineD3D OpenGL.
DISPLAY_BACKEND_DEFAULT="xwayland"
GRAPHICS_BACKEND_DEFAULT="wined3d"
WINED3D_RENDERER_DEFAULT="gl"

# Official LINE bootstrap installer. No LINE binary is stored in this repository.
LINE_INSTALLER_URL="https://desktop.line-scdn.net/win/new/LineInst.exe"
LINE_ALLOWED_HOST_SUFFIX="line-scdn.net"

# osslsigncode is built locally only when the distro does not provide it.
OSSLSIGNCODE_REPO="https://github.com/mtrojnar/osslsigncode.git"
OSSLSIGNCODE_TAG="2.14"
OSSLSIGNCODE_COMMIT="beec94e308d1a1e03ca17b05fe089d93c6303e90"
