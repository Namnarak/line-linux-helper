#!/usr/bin/env bash

detect_distro() {
  [[ -r /etc/os-release ]] || die "Cannot detect distribution: /etc/os-release missing"
  # shellcheck disable=SC1091
  source /etc/os-release
  DISTRO_ID=${ID:-unknown}
  DISTRO_LIKE=${ID_LIKE:-}

  local distro_words=" $DISTRO_ID $DISTRO_LIKE "
  if [[ "$distro_words" == *" arch "* || "$distro_words" == *" cachyos "* || "$distro_words" == *" manjaro "* || "$distro_words" == *" endeavouros "* ]]; then
    DISTRO_FAMILY=arch
  elif [[ "$distro_words" == *" debian "* || "$distro_words" == *" ubuntu "* || "$distro_words" == *" linuxmint "* || "$distro_words" == *" pop "* ]]; then
    DISTRO_FAMILY=debian
  elif [[ "$distro_words" == *" fedora "* || "$distro_words" == *" rhel "* || "$distro_words" == *" nobara "* ]]; then
    DISTRO_FAMILY=fedora
  elif [[ "$distro_words" == *" opensuse "* || "$distro_words" == *" suse "* ]]; then
    DISTRO_FAMILY=opensuse
  else
    DISTRO_FAMILY=unknown
  fi
}

install_optional_diagnostic_packages() {
  case "$DISTRO_FAMILY" in
    arch) as_root pacman -S --needed --noconfirm mesa-utils >/dev/null 2>&1 || true ;;
    debian) as_root apt-get install -y mesa-utils >/dev/null 2>&1 || true ;;
    fedora) as_root dnf install -y glx-utils >/dev/null 2>&1 || true ;;
    opensuse) as_root zypper --non-interactive install Mesa-demo-x >/dev/null 2>&1 || true ;;
  esac
}

install_dependencies() {
  detect_distro
  info "Detected distro: ${PRETTY_NAME:-$DISTRO_ID} ($DISTRO_FAMILY)"
  [[ ${NO_PACKAGES:-0} == 1 ]] && { info "Skipping package installation (--no-packages)"; return 0; }

  if [[ -e /run/ostree-booted ]]; then
    warn "Immutable/OSTree system detected. Automatic host package installation is skipped."
    warn "Install required dependencies with your distro-supported method, then rerun with --no-packages."
    return 0
  fi

  case "$DISTRO_FAMILY" in
    arch)
      run as_root pacman -S --needed --noconfirm \
        curl ca-certificates tar xz openssl winetricks cabextract unzip \
        git cmake make gcc pkgconf fontconfig zlib noto-fonts ttf-liberation
      run as_root pacman -S --needed --noconfirm osslsigncode || \
        warn "osslsigncode package unavailable; the helper will build its pinned fallback"
      ;;
    debian)
      run as_root apt-get update
      run as_root apt-get install -y \
        curl ca-certificates tar xz-utils openssl winetricks cabextract unzip \
        git cmake build-essential pkg-config libssl-dev zlib1g-dev fontconfig \
        fonts-noto-core fonts-liberation2
      run as_root apt-get install -y osslsigncode || \
        warn "osslsigncode package unavailable; the helper will build its pinned fallback"
      ;;
    fedora)
      run as_root dnf install -y \
        curl ca-certificates tar xz openssl winetricks cabextract unzip \
        git cmake gcc make pkgconf-pkg-config openssl-devel zlib-devel fontconfig \
        google-noto-sans-fonts google-noto-sans-thai-fonts liberation-sans-fonts
      run as_root dnf install -y osslsigncode || \
        warn "osslsigncode package unavailable; the helper will build its pinned fallback"
      ;;
    opensuse)
      run as_root zypper --non-interactive install \
        curl ca-certificates tar xz openssl winetricks cabextract unzip \
        git cmake gcc make pkg-config libopenssl-devel zlib-devel fontconfig \
        google-noto-fonts liberation-fonts
      run as_root zypper --non-interactive install osslsigncode || \
        warn "osslsigncode package unavailable; the helper will build its pinned fallback"
      ;;
    *)
      warn "Unsupported package manager."
      warn "Install manually: curl tar xz openssl winetricks cabextract unzip git cmake C compiler pkg-config fontconfig Noto/Liberation fonts and OpenSSL+zlib development headers"
      ;;
  esac

  # Diagnostic-only: installation failure must not block LINE.
  [[ ${DRY_RUN:-0} == 1 ]] || install_optional_diagnostic_packages
}
