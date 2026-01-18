#!/bin/bash
# install-deps.sh - Install system dependencies for NeoVim

set -e

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/detect-os.sh"

# Dependency lists by category
BUILD_DEPS_APT="cmake ninja-build gettext curl git build-essential libtool libtool-bin autoconf automake pkg-config unzip"
BUILD_DEPS_PACMAN="base-devel cmake ninja curl git unzip"
BUILD_DEPS_DNF="cmake ninja-build gettext curl git gcc gcc-c++ make libtool autoconf automake pkgconfig unzip"
BUILD_DEPS_BREW="cmake ninja gettext curl git"

RUNTIME_DEPS_APT="ripgrep fd-find fzf xclip wl-clipboard"
RUNTIME_DEPS_PACMAN="ripgrep fd fzf xclip wl-clipboard"
RUNTIME_DEPS_DNF="ripgrep fd-find fzf xclip wl-clipboard"
RUNTIME_DEPS_BREW="ripgrep fd fzf"

# Optional: Node.js for LSP servers (many use it)
OPTIONAL_APT="nodejs npm"
OPTIONAL_PACMAN="nodejs npm"
OPTIONAL_DNF="nodejs npm"
OPTIONAL_BREW="node"

# Install Homebrew on macOS if not present
install_homebrew() {
    if ! command_exists brew; then
        log_step "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add to PATH for current session
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi

        log_success "Homebrew installed"
    else
        log_info "Homebrew already installed"
    fi
}

# Install build dependencies
install_build_deps() {
    log_step "Installing build dependencies..."

    case "$PKG_MANAGER" in
        apt)
            pkg_update
            pkg_install $BUILD_DEPS_APT
            ;;
        pacman)
            pkg_update
            pkg_install $BUILD_DEPS_PACMAN
            ;;
        dnf|yum)
            pkg_update
            pkg_install $BUILD_DEPS_DNF
            ;;
        brew)
            install_homebrew
            pkg_update
            pkg_install $BUILD_DEPS_BREW
            ;;
        *)
            log_warn "Unknown package manager: $PKG_MANAGER"
            log_warn "Please install build dependencies manually:"
            log_warn "  cmake, ninja, gettext, curl, git, gcc, make"
            return 1
            ;;
    esac

    log_success "Build dependencies installed"
}

# Install runtime dependencies
install_runtime_deps() {
    log_step "Installing runtime dependencies..."

    case "$PKG_MANAGER" in
        apt)
            # Some packages might not exist in all Ubuntu versions
            for pkg in $RUNTIME_DEPS_APT; do
                if apt-cache show "$pkg" &>/dev/null; then
                    pkg_install "$pkg" || log_warn "Failed to install $pkg (might not be available)"
                else
                    log_warn "Package $pkg not found in repositories"
                fi
            done
            ;;
        pacman)
            pkg_install $RUNTIME_DEPS_PACMAN
            ;;
        dnf|yum)
            for pkg in $RUNTIME_DEPS_DNF; do
                pkg_install "$pkg" || log_warn "Failed to install $pkg"
            done
            ;;
        brew)
            pkg_install $RUNTIME_DEPS_BREW
            ;;
        *)
            log_warn "Unknown package manager: $PKG_MANAGER"
            log_warn "Please install runtime dependencies manually:"
            log_warn "  ripgrep, fd, fzf, xclip (Linux)"
            return 1
            ;;
    esac

    log_success "Runtime dependencies installed"
}

# Install optional dependencies
install_optional_deps() {
    log_step "Installing optional dependencies (Node.js)..."

    case "$PKG_MANAGER" in
        apt)
            pkg_install $OPTIONAL_APT || log_warn "Optional deps failed (non-critical)"
            ;;
        pacman)
            pkg_install $OPTIONAL_PACMAN || log_warn "Optional deps failed (non-critical)"
            ;;
        dnf|yum)
            pkg_install $OPTIONAL_DNF || log_warn "Optional deps failed (non-critical)"
            ;;
        brew)
            pkg_install $OPTIONAL_BREW || log_warn "Optional deps failed (non-critical)"
            ;;
        *)
            log_info "Skipping optional deps for unknown package manager"
            ;;
    esac
}

# Check if dependencies are installed
check_deps() {
    log_step "Checking dependencies..."

    local missing=()

    # Build dependencies
    for cmd in cmake git curl; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    # Runtime dependencies
    for cmd in rg fzf; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    # fd has different names
    if ! command_exists fd && ! command_exists fdfind; then
        missing+=("fd")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Missing dependencies: ${missing[*]}"
        return 1
    fi

    log_success "All dependencies installed"
    return 0
}

# Print dependency status
print_deps_status() {
    echo ""
    log_info "Dependency Status:"
    echo "  cmake:   $(command_exists cmake && echo "installed" || echo "MISSING")"
    echo "  git:     $(command_exists git && echo "installed" || echo "MISSING")"
    echo "  curl:    $(command_exists curl && echo "installed" || echo "MISSING")"
    echo "  ninja:   $(command_exists ninja && echo "installed" || echo "MISSING")"
    echo "  ripgrep: $(command_exists rg && echo "installed" || echo "MISSING")"
    echo "  fd:      $((command_exists fd || command_exists fdfind) && echo "installed" || echo "MISSING")"
    echo "  fzf:     $(command_exists fzf && echo "installed" || echo "MISSING")"
    echo "  node:    $(command_exists node && echo "installed ($(node --version))" || echo "not installed")"
    echo ""
}

# Main function
main() {
    print_header "Installing Dependencies"

    # Detect OS
    detect_os
    print_os_info
    echo ""

    if ! is_supported_os; then
        log_error "Unsupported OS/package manager: $PKG_MANAGER"
        log_info "Supported: apt, pacman, dnf, brew"
        exit 1
    fi

    # Parse arguments
    local install_build=true
    local install_runtime=true
    local install_optional=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --build-only)
                install_runtime=false
                ;;
            --runtime-only)
                install_build=false
                ;;
            --with-optional)
                install_optional=true
                ;;
            --check)
                check_deps
                print_deps_status
                exit $?
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --build-only      Install only build dependencies"
                echo "  --runtime-only    Install only runtime dependencies"
                echo "  --with-optional   Also install optional dependencies (Node.js)"
                echo "  --check           Check if dependencies are installed"
                echo "  --help            Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done

    # Install dependencies
    if $install_build; then
        install_build_deps
    fi

    if $install_runtime; then
        install_runtime_deps
    fi

    if $install_optional; then
        install_optional_deps
    fi

    # Final check
    echo ""
    print_deps_status
    check_deps
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
