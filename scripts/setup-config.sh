#!/bin/bash
# setup-config.sh - Deploy NeoVim configuration via symlink

set -e

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/backup.sh"

# Configuration
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_NVIM_CONFIG="$REPO_ROOT/nvim"
NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

# Check if repository config exists
check_repo_config() {
    if [[ ! -d "$REPO_NVIM_CONFIG" ]]; then
        log_error "Repository config not found: $REPO_NVIM_CONFIG"
        return 1
    fi

    if [[ ! -f "$REPO_NVIM_CONFIG/init.lua" ]]; then
        log_error "init.lua not found in repository config"
        return 1
    fi

    log_success "Repository config verified: $REPO_NVIM_CONFIG"
    return 0
}

# Create symlink for configuration
setup_symlink() {
    log_step "Setting up NeoVim configuration symlink..."

    # Ensure .config directory exists
    mkdir -p "$(dirname "$NVIM_CONFIG_DIR")"

    # Check if already correctly linked
    if [[ -L "$NVIM_CONFIG_DIR" ]]; then
        local current_target
        current_target="$(readlink -f "$NVIM_CONFIG_DIR")"

        if [[ "$current_target" == "$REPO_NVIM_CONFIG" ]]; then
            log_info "Symlink already correct: $NVIM_CONFIG_DIR -> $REPO_NVIM_CONFIG"
            return 0
        fi

        log_info "Removing existing symlink (pointed to: $current_target)"
        rm "$NVIM_CONFIG_DIR"
    elif [[ -e "$NVIM_CONFIG_DIR" ]]; then
        # Backup existing config
        log_info "Existing config found, backing up..."
        backup_nvim_config
    fi

    # Create symlink
    ln -s "$REPO_NVIM_CONFIG" "$NVIM_CONFIG_DIR"
    log_success "Created symlink: $NVIM_CONFIG_DIR -> $REPO_NVIM_CONFIG"
}

# Remove symlink (for uninstall)
remove_symlink() {
    if [[ -L "$NVIM_CONFIG_DIR" ]]; then
        local target
        target="$(readlink -f "$NVIM_CONFIG_DIR")"
        log_info "Removing symlink: $NVIM_CONFIG_DIR -> $target"
        rm "$NVIM_CONFIG_DIR"
        log_success "Symlink removed"
    elif [[ -e "$NVIM_CONFIG_DIR" ]]; then
        log_warn "Config exists but is not a symlink: $NVIM_CONFIG_DIR"
        log_warn "Manual removal required"
    else
        log_info "No config to remove"
    fi
}

# Verify symlink setup
verify_symlink() {
    if [[ ! -L "$NVIM_CONFIG_DIR" ]]; then
        log_error "Config is not a symlink"
        return 1
    fi

    local target
    target="$(readlink -f "$NVIM_CONFIG_DIR")"

    if [[ "$target" != "$REPO_NVIM_CONFIG" ]]; then
        log_error "Symlink points to wrong target: $target"
        log_error "Expected: $REPO_NVIM_CONFIG"
        return 1
    fi

    if [[ ! -f "$NVIM_CONFIG_DIR/init.lua" ]]; then
        log_error "init.lua not accessible via symlink"
        return 1
    fi

    log_success "Symlink verified: $NVIM_CONFIG_DIR -> $REPO_NVIM_CONFIG"
    return 0
}

# Initialize lazy.nvim and plugins on first run
init_plugins() {
    log_step "Initializing plugins (first run)..."

    if ! command_exists nvim; then
        log_warn "NeoVim not installed, skipping plugin initialization"
        return 0
    fi

    # Run headless plugin install
    log_info "Running lazy.nvim sync (this may take a moment)..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || {
        log_info "Plugin sync completed (some warnings are normal)"
    }

    log_success "Plugins initialized"
}

# Print configuration status
print_config_status() {
    echo ""
    log_info "Configuration Status:"

    if [[ -L "$NVIM_CONFIG_DIR" ]]; then
        echo "  Config type: Symlink"
        echo "  Target:      $(readlink -f "$NVIM_CONFIG_DIR")"
    elif [[ -d "$NVIM_CONFIG_DIR" ]]; then
        echo "  Config type: Directory"
        echo "  Location:    $NVIM_CONFIG_DIR"
    else
        echo "  Config type: Not found"
    fi

    # List backup if exists
    local latest_backup
    latest_backup=$(ls -dt "${HOME}/.config"/nvim.backup.* 2>/dev/null | head -1)
    if [[ -n "$latest_backup" ]]; then
        echo "  Latest backup: $latest_backup"
    fi
    echo ""
}

# Print help
print_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup       Create symlink (default)"
    echo "  remove      Remove symlink"
    echo "  verify      Verify symlink is correct"
    echo "  init        Initialize plugins"
    echo "  status      Show configuration status"
    echo "  help        Show this help message"
}

# Main function
main() {
    local command="${1:-setup}"

    case "$command" in
        setup)
            print_header "Setting Up NeoVim Configuration"
            check_repo_config || exit 1
            setup_symlink
            print_config_status
            ;;
        remove)
            print_header "Removing NeoVim Configuration"
            remove_symlink
            ;;
        verify)
            verify_symlink
            ;;
        init)
            init_plugins
            ;;
        status)
            print_config_status
            ;;
        help|--help|-h)
            print_help
            ;;
        *)
            log_error "Unknown command: $command"
            print_help
            exit 1
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
