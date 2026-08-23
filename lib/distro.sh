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
      run as_root pacman -S --needed --noconfirm curl ca-certificates tar xz openssl winetricks git cmake make gcc pkgconf fontconfig
      if ! run as_root pacman -S --needed --noconfirm noto-fonts; then
        warn "Could not install noto-fonts automatically; Thai/UI fallback may look worse."
      fi
      ;;
    debian)
      run as_root apt-get update
      run as_root apt-get install -y curl ca-certificates tar xz-utils openssl winetricks git cmake build-essential pkg-config libssl-dev fontconfig
      if ! run as_root apt-get install -y fonts-noto-core; then
        warn "Could not install fonts-noto-core automatically; Thai/UI fallback may look worse."
      fi
      ;;
    fedora)
      run as_root dnf install -y curl ca-certificates tar xz openssl winetricks git cmake gcc make pkgconf-pkg-config openssl-devel fontconfig
      if ! run as_root dnf install -y google-noto-sans-fonts google-noto-sans-thai-fonts; then
        warn "Could not install Noto Sans/Thai automatically; Thai/UI fallback may look worse."
      fi
      ;;
    opensuse)
      run as_root zypper --non-interactive install curl ca-certificates tar xz openssl winetricks git cmake gcc make pkg-config libopenssl-devel fontconfig
      if ! run as_root zypper --non-interactive install google-noto-fonts; then
        warn "Could not install google-noto-fonts automatically; install a Noto Sans + Thai package manually if available."
      fi
      ;;
    *)
      warn "Unsupported package manager. Install these manually: curl tar xz openssl winetricks git cmake C compiler pkg-config fontconfig Noto Sans/Thai fonts OpenSSL development headers"
      ;;
  esac
}
