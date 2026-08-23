#!/usr/bin/env bash

detect_distro() {
  [[ -r /etc/os-release ]] || die "Cannot detect distribution: /etc/os-release missing"
  # shellcheck disable=SC1091
  source /etc/os-release
  DISTRO_ID=${ID:-unknown}
  DISTRO_LIKE=${ID_LIKE:-}

  case " $DISTRO_ID $DISTRO_LIKE " in
    *" arch "*|*" cachyos "*|*" manjaro "*|*|*" endeavouros "*) DISTRO_FAMILY=arch ;;
    *" debian "*|*" ubuntu "*|*" linuxmint "*|*" pop "*) DISTRO_FAMILY=debian ;;
    *" fedora "*|*" rhel "*|*" nobara "*) DISTRO_FAMILY=fedora ;;
    *" opensuse "*|*" suse "*) DISTRO_FAMILY=opensuse ;;
    *) DISTRO_FAMILY=unknown ;;
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
      run as_root pacman -S --needed --noconfirm curl ca-certificates tar xz openssl winetricks git cmake make gcc pkgconf
      ;;
    debian)
      run as_root apt-get update
      run as_root apt-get install -y curl ca-certificates tar xz-utils openssl winetricks git cmake build-essential pkg-config libssl-dev
      ;;
    fedora)
      run as_root dnf install -y curl ca-certificates tar xz openssl winetricks git cmake gcc make pkgconf-pkg-config openssl-devel
      ;;
    opensuse)
      run as_root zypper --non-interactive install curl ca-certificates tar xz openssl winetricks git cmake gcc make pkg-config libopenssl-devel
      ;;
    *)
      warn "Unsupported package manager. Install these manually: curl tar xz openssl winetricks git cmake C compiler pkg-config OpenSSL development headers"
      ;;
  esac
}
