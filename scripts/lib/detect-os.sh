#!/bin/bash
# detect-os.sh - OS and distribution detection

# Source common utilities
_DETECT_OS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_DETECT_OS_DIR/common.sh"

# Global variables set by detection
OS_TYPE=""          # linux, darwin, windows
OS_DISTRO=""        # ubuntu, debian, arch, fedora, etc.
OS_VERSION=""       # Version number
PKG_MANAGER=""      # apt, pacman, dnf, brew, etc.
PKG_INSTALL=""      # Full install command
PKG_UPDATE=""       # Full update command
IS_WSL=false        # Running in Windows Subsystem for Linux

# Detect if running in WSL
detect_wsl() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
        return 0
    fi
    return 1
}

# Detect macOS
detect_macos() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        OS_TYPE="darwin"
        OS_DISTRO="macos"
        OS_VERSION="$(sw_vers -productVersion 2>/dev/null || echo "unknown")"

        if command_exists brew; then
            PKG_MANAGER="brew"
            PKG_INSTALL="brew install"
            PKG_UPDATE="brew update"
        else
            log_warn "Homebrew not found. Will attempt to install it."
            PKG_MANAGER="brew"
            PKG_INSTALL="brew install"
            PKG_UPDATE="brew update"
        fi
        return 0
    fi
    return 1
}

# Detect Linux distribution
detect_linux() {
    if [[ "$(uname -s)" != "Linux" ]]; then
        return 1
    fi

    OS_TYPE="linux"
    detect_wsl

    # Try /etc/os-release first (standard)
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_DISTRO="${ID:-unknown}"
        OS_VERSION="${VERSION_ID:-unknown}"

        case "$OS_DISTRO" in
            ubuntu|debian|linuxmint|pop|elementary|zorin)
                PKG_MANAGER="apt"
                PKG_INSTALL="apt-get install -y"
                PKG_UPDATE="apt-get update"
                ;;
            arch|manjaro|endeavouros|garuda)
                PKG_MANAGER="pacman"
                PKG_INSTALL="pacman -S --noconfirm"
                PKG_UPDATE="pacman -Sy"
                ;;
            fedora)
                PKG_MANAGER="dnf"
                PKG_INSTALL="dnf install -y"
                PKG_UPDATE="dnf check-update || true"
                ;;
            centos|rhel|rocky|almalinux)
                if command_exists dnf; then
                    PKG_MANAGER="dnf"
                    PKG_INSTALL="dnf install -y"
                    PKG_UPDATE="dnf check-update || true"
                else
                    PKG_MANAGER="yum"
                    PKG_INSTALL="yum install -y"
                    PKG_UPDATE="yum check-update || true"
                fi
                ;;
            opensuse*|suse*)
                PKG_MANAGER="zypper"
                PKG_INSTALL="zypper install -y"
                PKG_UPDATE="zypper refresh"
                ;;
            alpine)
                PKG_MANAGER="apk"
                PKG_INSTALL="apk add"
                PKG_UPDATE="apk update"
                ;;
            void)
                PKG_MANAGER="xbps"
                PKG_INSTALL="xbps-install -y"
                PKG_UPDATE="xbps-install -S"
                ;;
            gentoo)
                PKG_MANAGER="emerge"
                PKG_INSTALL="emerge"
                PKG_UPDATE="emerge --sync"
                ;;
            nixos)
                PKG_MANAGER="nix"
                PKG_INSTALL="nix-env -i"
                PKG_UPDATE="nix-channel --update"
                ;;
            *)
                log_warn "Unknown distribution: $OS_DISTRO"
                # Fallback detection
                detect_pkg_manager_fallback
                ;;
        esac
        return 0
    fi

    # Fallback to detecting package manager directly
    detect_pkg_manager_fallback
    OS_DISTRO="unknown"
    OS_VERSION="unknown"
    return 0
}

# Fallback package manager detection
detect_pkg_manager_fallback() {
    if command_exists apt-get; then
        PKG_MANAGER="apt"
        PKG_INSTALL="apt-get install -y"
        PKG_UPDATE="apt-get update"
    elif command_exists pacman; then
        PKG_MANAGER="pacman"
        PKG_INSTALL="pacman -S --noconfirm"
        PKG_UPDATE="pacman -Sy"
    elif command_exists dnf; then
        PKG_MANAGER="dnf"
        PKG_INSTALL="dnf install -y"
        PKG_UPDATE="dnf check-update || true"
    elif command_exists yum; then
        PKG_MANAGER="yum"
        PKG_INSTALL="yum install -y"
        PKG_UPDATE="yum check-update || true"
    elif command_exists zypper; then
        PKG_MANAGER="zypper"
        PKG_INSTALL="zypper install -y"
        PKG_UPDATE="zypper refresh"
    elif command_exists apk; then
        PKG_MANAGER="apk"
        PKG_INSTALL="apk add"
        PKG_UPDATE="apk update"
    elif command_exists brew; then
        PKG_MANAGER="brew"
        PKG_INSTALL="brew install"
        PKG_UPDATE="brew update"
    else
        PKG_MANAGER="unknown"
        PKG_INSTALL=""
        PKG_UPDATE=""
    fi
}

# Main detection function
detect_os() {
    if detect_macos; then
        return 0
    elif detect_linux; then
        return 0
    else
        OS_TYPE="unknown"
        OS_DISTRO="unknown"
        OS_VERSION="unknown"
        PKG_MANAGER="unknown"
        return 1
    fi
}

# Print detected OS information
print_os_info() {
    log_info "OS Type: $OS_TYPE"
    log_info "Distribution: $OS_DISTRO"
    log_info "Version: $OS_VERSION"
    log_info "Package Manager: $PKG_MANAGER"
    if $IS_WSL; then
        log_info "WSL: Yes"
    fi
}

# Check if OS is supported
is_supported_os() {
    case "$PKG_MANAGER" in
        apt|pacman|dnf|yum|brew)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Install packages using detected package manager
pkg_install() {
    if [[ -z "$PKG_INSTALL" ]]; then
        die "No package manager detected"
    fi

    log_info "Installing packages: $*"
    # Homebrew should not use sudo
    if [[ "$PKG_MANAGER" == "brew" ]]; then
        $PKG_INSTALL "$@"
    else
        maybe_sudo $PKG_INSTALL "$@"
    fi
}

# Update package lists
pkg_update() {
    if [[ -z "$PKG_UPDATE" ]]; then
        die "No package manager detected"
    fi

    log_info "Updating package lists..."
    # Homebrew should not use sudo
    if [[ "$PKG_MANAGER" == "brew" ]]; then
        $PKG_UPDATE
    else
        maybe_sudo $PKG_UPDATE
    fi
}

# Run detection if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_os
    print_os_info
fi
