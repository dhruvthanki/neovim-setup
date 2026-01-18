#!/bin/bash
# install.sh - Main installation script for NeoVim setup
#
# Usage: ./install.sh [OPTIONS]
#
# This script orchestrates the full NeoVim installation:
# 1. Detects your OS and package manager
# 2. Backs up existing configuration
# 3. Installs build and runtime dependencies
# 4. Builds NeoVim from source (or uses AppImage)
# 5. Symlinks configuration from this repository
# 6. Initializes plugins via lazy.nvim

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "$SCRIPT_DIR/scripts/lib/common.sh"
source "$SCRIPT_DIR/scripts/lib/detect-os.sh"
source "$SCRIPT_DIR/scripts/lib/backup.sh"

# Default options
INSTALL_DEPS=true
INSTALL_NVIM=true
INSTALL_CONFIG=true
INIT_PLUGINS=true
NVIM_METHOD="source"
NVIM_VERSION="stable"
FORCE=false
VERBOSE=false

# Print banner
print_banner() {
    echo ""
    echo -e "${MAGENTA}"
    echo "  _   _            __     ___           "
    echo " | \\ | | ___  ___  \\ \\   / (_)_ __ ___  "
    echo " |  \\| |/ _ \\/ _ \\  \\ \\ / /| | '_ \` _ \\ "
    echo " | |\\  |  __/ (_) |  \\ V / | | | | | | |"
    echo " |_| \\_|\\___|\\___/    \\_/  |_|_| |_| |_|"
    echo ""
    echo "        Unified Setup Installer"
    echo -e "${NC}"
}

# Print help
print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Install NeoVim with LazyVim configuration"
    echo ""
    echo "Options:"
    echo "  --deps-only         Install dependencies only"
    echo "  --nvim-only         Install NeoVim only"
    echo "  --config-only       Setup configuration only"
    echo "  --no-deps           Skip dependency installation"
    echo "  --no-nvim           Skip NeoVim installation"
    echo "  --no-config         Skip configuration setup"
    echo "  --no-plugins        Skip plugin initialization"
    echo "  --method METHOD     NeoVim install method: source, appimage, package"
    echo "  --version VERSION   NeoVim version: stable, nightly, or tag"
    echo "  --force             Force reinstall even if already installed"
    echo "  --verbose           Show detailed output"
    echo "  --help, -h          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                        # Full installation"
    echo "  $0 --config-only          # Only setup configuration"
    echo "  $0 --method appimage      # Use AppImage instead of building"
    echo "  $0 --version nightly      # Install nightly build"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --deps-only)
                INSTALL_DEPS=true
                INSTALL_NVIM=false
                INSTALL_CONFIG=false
                INIT_PLUGINS=false
                shift
                ;;
            --nvim-only)
                INSTALL_DEPS=false
                INSTALL_NVIM=true
                INSTALL_CONFIG=false
                INIT_PLUGINS=false
                shift
                ;;
            --config-only)
                INSTALL_DEPS=false
                INSTALL_NVIM=false
                INSTALL_CONFIG=true
                INIT_PLUGINS=true
                shift
                ;;
            --no-deps)
                INSTALL_DEPS=false
                shift
                ;;
            --no-nvim)
                INSTALL_NVIM=false
                shift
                ;;
            --no-config)
                INSTALL_CONFIG=false
                shift
                ;;
            --no-plugins)
                INIT_PLUGINS=false
                shift
                ;;
            --method)
                NVIM_METHOD="$2"
                shift 2
                ;;
            --version)
                NVIM_VERSION="$2"
                shift 2
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
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
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."

    # Must have git
    if ! command_exists git; then
        die "git is required but not installed"
    fi

    # Must have curl
    if ! command_exists curl; then
        die "curl is required but not installed"
    fi

    # Check for sudo if needed
    if ! is_root && [[ "$INSTALL_DEPS" == true || "$INSTALL_NVIM" == true ]]; then
        if ! command_exists sudo; then
            log_warn "sudo not found - may need to run as root"
        fi
    fi

    log_success "Prerequisites satisfied"
}

# Install dependencies
do_install_deps() {
    if [[ "$INSTALL_DEPS" != true ]]; then
        log_info "Skipping dependency installation"
        return 0
    fi

    "$SCRIPT_DIR/scripts/install-deps.sh"
}

# Install NeoVim
do_install_nvim() {
    if [[ "$INSTALL_NVIM" != true ]]; then
        log_info "Skipping NeoVim installation"
        return 0
    fi

    # Check if already installed (unless force)
    if command_exists nvim && [[ "$FORCE" != true ]]; then
        local current_version
        current_version="$(nvim --version | head -1)"
        log_info "NeoVim already installed: $current_version"

        if ! confirm "Reinstall NeoVim?" "n"; then
            log_info "Keeping existing installation"
            return 0
        fi
    fi

    "$SCRIPT_DIR/scripts/install-neovim.sh" --method "$NVIM_METHOD" --version "$NVIM_VERSION"
}

# Setup configuration
do_install_config() {
    if [[ "$INSTALL_CONFIG" != true ]]; then
        log_info "Skipping configuration setup"
        return 0
    fi

    "$SCRIPT_DIR/scripts/setup-config.sh" setup
}

# Initialize plugins
do_init_plugins() {
    if [[ "$INIT_PLUGINS" != true ]]; then
        log_info "Skipping plugin initialization"
        return 0
    fi

    "$SCRIPT_DIR/scripts/setup-config.sh" init
}

# Final verification
do_verify() {
    print_header "Verification"

    local all_good=true

    # Check NeoVim
    if command_exists nvim; then
        log_success "NeoVim: $(nvim --version | head -1)"
    else
        log_error "NeoVim: not found"
        all_good=false
    fi

    # Check config symlink
    if [[ -L "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" ]]; then
        log_success "Config: symlinked to $(readlink -f "${XDG_CONFIG_HOME:-$HOME/.config}/nvim")"
    else
        log_warn "Config: not symlinked"
    fi

    # Check runtime tools
    for tool in rg fzf; do
        if command_exists "$tool"; then
            log_success "$tool: installed"
        else
            log_warn "$tool: not found (optional)"
        fi
    done

    # fd has different names
    if command_exists fd || command_exists fdfind; then
        log_success "fd: installed"
    else
        log_warn "fd: not found (optional)"
    fi

    echo ""
    if $all_good; then
        log_success "Installation complete!"
        echo ""
        echo "Next steps:"
        echo "  1. Run 'nvim' to start NeoVim"
        echo "  2. Plugins will install automatically on first launch"
        echo "  3. Run ':checkhealth' inside NeoVim to verify setup"
        echo ""
    else
        log_warn "Installation completed with warnings"
        echo "Some components may need manual installation"
    fi
}

# Main function
main() {
    print_banner

    parse_args "$@"

    # Detect OS first
    log_step "Detecting operating system..."
    detect_os
    print_os_info
    echo ""

    # Check if OS is supported
    if ! is_supported_os; then
        log_warn "Your OS may not be fully supported"
        log_info "Will attempt AppImage installation for NeoVim"
        NVIM_METHOD="appimage"
    fi

    # Run checks
    check_prerequisites

    # Run installation steps
    do_install_deps
    do_install_nvim
    do_install_config
    do_init_plugins

    # Verify
    do_verify
}

# Run main
main "$@"
