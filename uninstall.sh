#!/bin/bash
# uninstall.sh - Remove NeoVim and configuration
#
# Usage: ./uninstall.sh [OPTIONS]
#
# This script removes:
# - NeoVim binary (from source build or AppImage)
# - Configuration symlink
# - Plugin data (optional)
# - Cache and state files (optional)

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "$SCRIPT_DIR/scripts/lib/common.sh"
source "$SCRIPT_DIR/scripts/lib/detect-os.sh"
source "$SCRIPT_DIR/scripts/lib/backup.sh"

# Configuration paths
NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
NVIM_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
NVIM_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nvim"
NVIM_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
INSTALL_PREFIX="/usr/local"

# Options
REMOVE_NVIM=true
REMOVE_CONFIG=true
REMOVE_DATA=false
REMOVE_CACHE=false
KEEP_BACKUPS=true
FORCE=false

# Print help
print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Uninstall NeoVim and configuration"
    echo ""
    echo "Options:"
    echo "  --nvim-only      Remove NeoVim only, keep config"
    echo "  --config-only    Remove config only, keep NeoVim"
    echo "  --all            Remove everything including plugins and cache"
    echo "  --keep-data      Keep plugin data (~/.local/share/nvim)"
    echo "  --remove-backups Also remove backup directories"
    echo "  --force          Don't ask for confirmation"
    echo "  --help, -h       Show this help message"
    echo ""
    echo "By default, this removes NeoVim and the config symlink but"
    echo "preserves plugin data and backups."
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --nvim-only)
                REMOVE_CONFIG=false
                shift
                ;;
            --config-only)
                REMOVE_NVIM=false
                shift
                ;;
            --all)
                REMOVE_DATA=true
                REMOVE_CACHE=true
                shift
                ;;
            --keep-data)
                REMOVE_DATA=false
                shift
                ;;
            --remove-backups)
                KEEP_BACKUPS=false
                shift
                ;;
            --force)
                FORCE=true
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

# Remove NeoVim binary
remove_nvim() {
    if [[ "$REMOVE_NVIM" != true ]]; then
        return 0
    fi

    log_step "Removing NeoVim..."

    # Detect OS for package manager
    detect_os

    # Remove package manager installation
    case "$PKG_MANAGER" in
        apt)
            if dpkg -l neovim &>/dev/null 2>&1; then
                log_info "Removing apt package..."
                maybe_sudo apt-get remove -y neovim neovim-runtime 2>/dev/null || true
            fi
            ;;
        pacman)
            if pacman -Qi neovim &>/dev/null 2>&1; then
                log_info "Removing pacman package..."
                maybe_sudo pacman -Rs --noconfirm neovim 2>/dev/null || true
            fi
            ;;
        dnf|yum)
            if rpm -q neovim &>/dev/null 2>&1; then
                log_info "Removing dnf/yum package..."
                maybe_sudo $PKG_MANAGER remove -y neovim 2>/dev/null || true
            fi
            ;;
        brew)
            if brew list neovim &>/dev/null 2>&1; then
                log_info "Removing Homebrew package..."
                brew uninstall neovim 2>/dev/null || true
            fi
            ;;
    esac

    # Remove source build installation
    if [[ -f "$INSTALL_PREFIX/bin/nvim" ]]; then
        log_info "Removing source build from $INSTALL_PREFIX..."
        maybe_sudo rm -f "$INSTALL_PREFIX/bin/nvim"
        maybe_sudo rm -rf "$INSTALL_PREFIX/share/nvim"
        maybe_sudo rm -rf "$INSTALL_PREFIX/lib/nvim"
    fi

    # Remove AppImage
    if [[ -f "$HOME/.local/bin/nvim" ]]; then
        log_info "Removing AppImage wrapper..."
        rm -f "$HOME/.local/bin/nvim"
    fi
    if [[ -f "$HOME/.local/bin/nvim.appimage" ]]; then
        log_info "Removing AppImage..."
        rm -f "$HOME/.local/bin/nvim.appimage"
    fi

    # Verify removal
    if command_exists nvim; then
        log_warn "NeoVim still found at: $(which nvim)"
        log_warn "Manual removal may be required"
    else
        log_success "NeoVim removed"
    fi
}

# Remove configuration
remove_config() {
    if [[ "$REMOVE_CONFIG" != true ]]; then
        return 0
    fi

    log_step "Removing configuration..."

    if [[ -L "$NVIM_CONFIG_DIR" ]]; then
        local target
        target="$(readlink -f "$NVIM_CONFIG_DIR")"
        log_info "Removing symlink: $NVIM_CONFIG_DIR -> $target"
        rm "$NVIM_CONFIG_DIR"
        log_success "Configuration symlink removed"
    elif [[ -d "$NVIM_CONFIG_DIR" ]]; then
        log_warn "Config is a directory, not a symlink"
        if $FORCE || confirm "Remove directory $NVIM_CONFIG_DIR?"; then
            rm -rf "$NVIM_CONFIG_DIR"
            log_success "Configuration directory removed"
        else
            log_info "Keeping configuration directory"
        fi
    else
        log_info "No configuration found at $NVIM_CONFIG_DIR"
    fi
}

# Remove plugin data
remove_data() {
    if [[ "$REMOVE_DATA" != true ]]; then
        log_info "Keeping plugin data at $NVIM_DATA_DIR"
        return 0
    fi

    log_step "Removing plugin data..."

    if [[ -d "$NVIM_DATA_DIR" ]]; then
        rm -rf "$NVIM_DATA_DIR"
        log_success "Plugin data removed: $NVIM_DATA_DIR"
    else
        log_info "No plugin data found"
    fi
}

# Remove cache and state
remove_cache() {
    if [[ "$REMOVE_CACHE" != true ]]; then
        return 0
    fi

    log_step "Removing cache and state..."

    if [[ -d "$NVIM_CACHE_DIR" ]]; then
        rm -rf "$NVIM_CACHE_DIR"
        log_info "Removed: $NVIM_CACHE_DIR"
    fi

    if [[ -d "$NVIM_STATE_DIR" ]]; then
        rm -rf "$NVIM_STATE_DIR"
        log_info "Removed: $NVIM_STATE_DIR"
    fi

    log_success "Cache and state removed"
}

# Remove backups
remove_backups() {
    if $KEEP_BACKUPS; then
        # List backups for reference
        local backup_count=0
        for backup in "${HOME}/.config"/nvim.backup.* "${HOME}/.local/share"/nvim.backup.*; do
            if [[ -d "$backup" ]]; then
                ((backup_count++))
            fi
        done

        if [[ $backup_count -gt 0 ]]; then
            log_info "Keeping $backup_count backup(s)"
            log_info "Run '$0 --remove-backups' to remove them"
        fi
        return 0
    fi

    log_step "Removing backups..."

    for backup in "${HOME}/.config"/nvim.backup.* "${HOME}/.local/share"/nvim.backup.*; do
        if [[ -d "$backup" ]]; then
            rm -rf "$backup"
            log_info "Removed: $backup"
        fi
    done

    log_success "Backups removed"
}

# Print summary
print_summary() {
    echo ""
    print_header "Uninstall Summary"

    if ! command_exists nvim; then
        log_success "NeoVim: removed"
    else
        log_info "NeoVim: $(nvim --version | head -1)"
    fi

    if [[ -e "$NVIM_CONFIG_DIR" ]]; then
        log_info "Config: still exists at $NVIM_CONFIG_DIR"
    else
        log_success "Config: removed"
    fi

    if [[ -d "$NVIM_DATA_DIR" ]]; then
        log_info "Data: preserved at $NVIM_DATA_DIR"
    else
        log_success "Data: removed"
    fi

    echo ""
}

# Main function
main() {
    print_header "NeoVim Uninstaller"

    parse_args "$@"

    # Confirm before proceeding
    if ! $FORCE; then
        echo "This will remove:"
        $REMOVE_NVIM && echo "  - NeoVim binary"
        $REMOVE_CONFIG && echo "  - Configuration (symlink at $NVIM_CONFIG_DIR)"
        $REMOVE_DATA && echo "  - Plugin data ($NVIM_DATA_DIR)"
        $REMOVE_CACHE && echo "  - Cache and state files"
        ! $KEEP_BACKUPS && echo "  - All backups"
        echo ""

        if ! confirm "Proceed with uninstall?"; then
            log_info "Cancelled"
            exit 0
        fi
    fi

    # Run removal steps
    remove_nvim
    remove_config
    remove_data
    remove_cache
    remove_backups

    # Summary
    print_summary
}

# Run main
main "$@"
