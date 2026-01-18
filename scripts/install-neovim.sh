#!/bin/bash
# install-neovim.sh - Build and install NeoVim from source

set -e

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/detect-os.sh"

# Configuration
NEOVIM_REPO="https://github.com/neovim/neovim.git"
NEOVIM_VERSION="${NEOVIM_VERSION:-stable}"  # stable, nightly, or specific tag (e.g., v0.10.0)
BUILD_DIR="${BUILD_DIR:-/tmp/neovim-build}"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"

# Installation methods
METHOD_SOURCE="source"
METHOD_APPIMAGE="appimage"
METHOD_PACKAGE="package"

# Get the latest stable version tag
get_latest_stable_tag() {
    curl -sL https://api.github.com/repos/neovim/neovim/releases/latest | \
        grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Check current NeoVim version
get_installed_version() {
    if command_exists nvim; then
        nvim --version | head -1 | awk '{print $2}'
    else
        echo "not installed"
    fi
}

# Remove existing NeoVim installation
remove_existing_nvim() {
    log_step "Checking for existing NeoVim installation..."

    if command_exists nvim; then
        local current_path
        current_path="$(which nvim)"
        log_info "Found NeoVim at: $current_path"

        # Check if it was installed via package manager
        case "$PKG_MANAGER" in
            apt)
                if dpkg -l neovim &>/dev/null; then
                    log_info "Removing package manager installation..."
                    maybe_sudo apt-get remove -y neovim neovim-runtime || true
                fi
                ;;
            pacman)
                if pacman -Qi neovim &>/dev/null; then
                    log_info "Removing package manager installation..."
                    maybe_sudo pacman -Rs --noconfirm neovim || true
                fi
                ;;
            dnf|yum)
                if rpm -q neovim &>/dev/null; then
                    log_info "Removing package manager installation..."
                    maybe_sudo $PKG_MANAGER remove -y neovim || true
                fi
                ;;
            brew)
                if brew list neovim &>/dev/null; then
                    log_info "Removing Homebrew installation..."
                    brew uninstall neovim || true
                fi
                ;;
        esac

        # Remove any local installation
        if [[ -f "$INSTALL_PREFIX/bin/nvim" ]]; then
            log_info "Removing local installation..."
            maybe_sudo rm -f "$INSTALL_PREFIX/bin/nvim"
            maybe_sudo rm -rf "$INSTALL_PREFIX/share/nvim"
            maybe_sudo rm -rf "$INSTALL_PREFIX/lib/nvim"
        fi

        # Remove AppImage if present
        if [[ -f "$HOME/.local/bin/nvim" ]]; then
            rm -f "$HOME/.local/bin/nvim"
        fi
        if [[ -f "$HOME/.local/bin/nvim.appimage" ]]; then
            rm -f "$HOME/.local/bin/nvim.appimage"
        fi
    fi
}

# Build NeoVim from source
build_from_source() {
    local version="${1:-stable}"

    print_header "Building NeoVim from Source"
    log_info "Version: $version"

    # Clean previous build
    if [[ -d "$BUILD_DIR" ]]; then
        log_info "Cleaning previous build directory..."
        rm -rf "$BUILD_DIR"
    fi

    # Clone repository
    log_step "Cloning NeoVim repository..."
    git clone --depth 1 "$NEOVIM_REPO" "$BUILD_DIR"
    cd "$BUILD_DIR"

    # Checkout version
    if [[ "$version" == "stable" ]]; then
        local tag
        tag="$(get_latest_stable_tag)"
        log_info "Latest stable: $tag"
        git fetch --depth 1 origin "refs/tags/$tag:refs/tags/$tag"
        git checkout "$tag"
    elif [[ "$version" == "nightly" ]] || [[ "$version" == "master" ]]; then
        log_info "Using latest master (nightly)"
        # Already on master from clone
    else
        # Specific version tag
        log_info "Checking out: $version"
        git fetch --depth 1 origin "refs/tags/$version:refs/tags/$version"
        git checkout "$version"
    fi

    # Build
    log_step "Building NeoVim (this may take a while)..."
    make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"

    # Install
    log_step "Installing NeoVim..."
    maybe_sudo make install

    # Cleanup
    log_info "Cleaning up build directory..."
    cd /
    rm -rf "$BUILD_DIR"

    log_success "NeoVim built and installed successfully"
}

# Install via AppImage (fallback for unsupported distros)
install_appimage() {
    local version="${1:-stable}"

    print_header "Installing NeoVim AppImage"

    local appimage_url
    if [[ "$version" == "stable" ]]; then
        appimage_url="https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
    elif [[ "$version" == "nightly" ]]; then
        appimage_url="https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage"
    else
        appimage_url="https://github.com/neovim/neovim/releases/download/${version}/nvim.appimage"
    fi

    # Create local bin directory
    mkdir -p "$HOME/.local/bin"

    # Download AppImage
    log_step "Downloading NeoVim AppImage..."
    curl -Lo "$HOME/.local/bin/nvim.appimage" "$appimage_url"
    chmod +x "$HOME/.local/bin/nvim.appimage"

    # Create wrapper script
    cat > "$HOME/.local/bin/nvim" << 'EOF'
#!/bin/bash
exec "$HOME/.local/bin/nvim.appimage" "$@"
EOF
    chmod +x "$HOME/.local/bin/nvim"

    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log_warn "Add ~/.local/bin to your PATH:"
        log_warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        log_warn "Add this to your ~/.bashrc or ~/.zshrc"
    fi

    log_success "NeoVim AppImage installed to ~/.local/bin/nvim"
}

# Install via package manager (quick but may be outdated)
install_via_package() {
    print_header "Installing NeoVim via Package Manager"

    case "$PKG_MANAGER" in
        apt)
            # Ubuntu PPA has newer versions
            log_info "Adding NeoVim PPA for latest version..."
            maybe_sudo apt-get install -y software-properties-common
            maybe_sudo add-apt-repository -y ppa:neovim-ppa/unstable
            maybe_sudo apt-get update
            maybe_sudo apt-get install -y neovim
            ;;
        pacman)
            pkg_install neovim
            ;;
        dnf|yum)
            pkg_install neovim
            ;;
        brew)
            brew install neovim
            ;;
        *)
            log_error "Package installation not supported for: $PKG_MANAGER"
            return 1
            ;;
    esac

    log_success "NeoVim installed via package manager"
}

# Verify installation
verify_installation() {
    log_step "Verifying installation..."

    if ! command_exists nvim; then
        log_error "NeoVim not found in PATH"

        # Check common locations
        for path in /usr/local/bin/nvim /usr/bin/nvim "$HOME/.local/bin/nvim"; do
            if [[ -x "$path" ]]; then
                log_info "Found at: $path (not in PATH)"
            fi
        done
        return 1
    fi

    local version
    version="$(nvim --version | head -1)"
    log_success "Installed: $version"

    # Quick health check
    log_info "NeoVim location: $(which nvim)"

    return 0
}

# Print help
print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Install NeoVim using various methods"
    echo ""
    echo "Options:"
    echo "  --method METHOD     Installation method: source, appimage, package (default: source)"
    echo "  --version VERSION   NeoVim version: stable, nightly, or tag (default: stable)"
    echo "  --prefix PATH       Installation prefix for source builds (default: /usr/local)"
    echo "  --remove            Remove existing NeoVim installation only"
    echo "  --check             Check current installation status"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Build latest stable from source"
    echo "  $0 --method appimage        # Install via AppImage"
    echo "  $0 --version nightly        # Build nightly from source"
    echo "  $0 --version v0.10.0        # Build specific version"
}

# Main function
main() {
    local method="$METHOD_SOURCE"
    local version="stable"
    local remove_only=false
    local check_only=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --method)
                method="$2"
                shift 2
                ;;
            --version)
                version="$2"
                shift 2
                ;;
            --prefix)
                INSTALL_PREFIX="$2"
                shift 2
                ;;
            --remove)
                remove_only=true
                shift
                ;;
            --check)
                check_only=true
                shift
                ;;
            --help|-h)
                print_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
    done

    # Detect OS
    detect_os

    # Check only
    if $check_only; then
        local installed
        installed="$(get_installed_version)"
        log_info "Installed version: $installed"
        if command_exists nvim; then
            log_info "Location: $(which nvim)"
        fi
        exit 0
    fi

    # Remove only
    if $remove_only; then
        remove_existing_nvim
        exit 0
    fi

    print_header "Installing NeoVim"
    log_info "Method: $method"
    log_info "Version: $version"
    echo ""

    # Remove existing installation
    remove_existing_nvim

    # Install based on method
    case "$method" in
        source)
            build_from_source "$version"
            ;;
        appimage)
            install_appimage "$version"
            ;;
        package)
            install_via_package
            ;;
        *)
            log_error "Unknown installation method: $method"
            log_info "Valid methods: source, appimage, package"
            exit 1
            ;;
    esac

    # Verify
    verify_installation
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
