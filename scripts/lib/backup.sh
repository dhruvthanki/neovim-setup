#!/bin/bash
# backup.sh - Backup and restore utilities for NeoVim configuration

# Source common utilities
_BACKUP_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_BACKUP_SH_DIR/common.sh"

# Configuration paths
NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
NVIM_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
NVIM_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nvim"
NVIM_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"

BACKUP_BASE_DIR="${HOME}/.config"

# Generate backup timestamp
get_timestamp() {
    date +"%Y%m%d_%H%M%S"
}

# Backup NeoVim configuration
backup_nvim_config() {
    local timestamp
    timestamp="$(get_timestamp)"
    local backup_dir="${BACKUP_BASE_DIR}/nvim.backup.${timestamp}"

    if [[ -e "$NVIM_CONFIG_DIR" ]]; then
        # Check if it's a symlink
        if [[ -L "$NVIM_CONFIG_DIR" ]]; then
            local link_target
            link_target="$(readlink -f "$NVIM_CONFIG_DIR")"
            log_info "Config is a symlink to: $link_target"
            log_info "Removing symlink (target preserved)"
            rm "$NVIM_CONFIG_DIR"
            return 0
        fi

        log_step "Backing up existing NeoVim config to $backup_dir"
        mv "$NVIM_CONFIG_DIR" "$backup_dir"

        if [[ -d "$backup_dir" ]]; then
            log_success "Backup created: $backup_dir"
            echo "$backup_dir"
            return 0
        else
            log_error "Backup failed"
            return 1
        fi
    else
        log_info "No existing NeoVim config found at $NVIM_CONFIG_DIR"
        return 0
    fi
}

# Backup NeoVim data (plugins, etc.)
backup_nvim_data() {
    local timestamp
    timestamp="$(get_timestamp)"
    local backup_dir="${HOME}/.local/share/nvim.backup.${timestamp}"

    if [[ -d "$NVIM_DATA_DIR" ]]; then
        log_step "Backing up NeoVim data to $backup_dir"
        mv "$NVIM_DATA_DIR" "$backup_dir"
        log_success "Data backup created: $backup_dir"
        echo "$backup_dir"
    else
        log_info "No NeoVim data directory found"
    fi
}

# Clean NeoVim cache and state (without backup)
clean_nvim_cache() {
    log_step "Cleaning NeoVim cache and state..."

    if [[ -d "$NVIM_CACHE_DIR" ]]; then
        rm -rf "$NVIM_CACHE_DIR"
        log_info "Removed cache: $NVIM_CACHE_DIR"
    fi

    if [[ -d "$NVIM_STATE_DIR" ]]; then
        rm -rf "$NVIM_STATE_DIR"
        log_info "Removed state: $NVIM_STATE_DIR"
    fi
}

# List available backups
list_backups() {
    log_step "Available NeoVim backups:"

    local found=false

    # Config backups
    for backup in "${BACKUP_BASE_DIR}"/nvim.backup.*; do
        if [[ -d "$backup" ]]; then
            echo "  Config: $backup"
            found=true
        fi
    done

    # Data backups
    for backup in "${HOME}/.local/share"/nvim.backup.*; do
        if [[ -d "$backup" ]]; then
            echo "  Data:   $backup"
            found=true
        fi
    done

    if ! $found; then
        log_info "No backups found"
    fi
}

# Restore configuration from backup
restore_from_backup() {
    local backup_path="$1"

    if [[ -z "$backup_path" ]]; then
        log_error "No backup path specified"
        list_backups
        return 1
    fi

    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup not found: $backup_path"
        return 1
    fi

    # Determine if it's a config or data backup
    if [[ "$backup_path" == */.config/* ]] || [[ "$backup_path" == */nvim.backup.* && "$backup_path" != */.local/share/* ]]; then
        # Config backup
        log_step "Restoring config from $backup_path"

        # Remove current config if exists
        if [[ -e "$NVIM_CONFIG_DIR" ]]; then
            if [[ -L "$NVIM_CONFIG_DIR" ]]; then
                rm "$NVIM_CONFIG_DIR"
            else
                local timestamp
                timestamp="$(get_timestamp)"
                mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.pre-restore.${timestamp}"
            fi
        fi

        mv "$backup_path" "$NVIM_CONFIG_DIR"
        log_success "Config restored to $NVIM_CONFIG_DIR"

    elif [[ "$backup_path" == */.local/share/* ]]; then
        # Data backup
        log_step "Restoring data from $backup_path"

        if [[ -d "$NVIM_DATA_DIR" ]]; then
            rm -rf "$NVIM_DATA_DIR"
        fi

        mv "$backup_path" "$NVIM_DATA_DIR"
        log_success "Data restored to $NVIM_DATA_DIR"
    else
        log_error "Cannot determine backup type"
        return 1
    fi
}

# Get latest backup path
get_latest_backup() {
    local latest
    latest=$(ls -dt "${BACKUP_BASE_DIR}"/nvim.backup.* 2>/dev/null | head -1)

    if [[ -n "$latest" ]]; then
        echo "$latest"
        return 0
    fi
    return 1
}

# Full backup (config + data)
full_backup() {
    log_step "Creating full NeoVim backup..."
    local config_backup data_backup

    config_backup=$(backup_nvim_config)
    data_backup=$(backup_nvim_data)

    if [[ -n "$config_backup" || -n "$data_backup" ]]; then
        log_success "Full backup complete"
        [[ -n "$config_backup" ]] && log_info "Config: $config_backup"
        [[ -n "$data_backup" ]] && log_info "Data: $data_backup"
        return 0
    fi

    return 1
}

# Remove all backups (with confirmation)
clean_backups() {
    log_warn "This will remove ALL NeoVim backups!"

    local count=0
    for backup in "${BACKUP_BASE_DIR}"/nvim.backup.* "${HOME}/.local/share"/nvim.backup.*; do
        if [[ -d "$backup" ]]; then
            ((count++))
        fi
    done

    if [[ $count -eq 0 ]]; then
        log_info "No backups to remove"
        return 0
    fi

    log_info "Found $count backup(s)"

    if confirm "Remove all backups?"; then
        for backup in "${BACKUP_BASE_DIR}"/nvim.backup.* "${HOME}/.local/share"/nvim.backup.*; do
            if [[ -d "$backup" ]]; then
                rm -rf "$backup"
                log_info "Removed: $backup"
            fi
        done
        log_success "All backups removed"
    else
        log_info "Cancelled"
    fi
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        backup)
            full_backup
            ;;
        restore)
            restore_from_backup "${2:-$(get_latest_backup)}"
            ;;
        list)
            list_backups
            ;;
        clean)
            clean_backups
            ;;
        *)
            echo "Usage: $0 {backup|restore [path]|list|clean}"
            echo ""
            echo "Commands:"
            echo "  backup          Create full backup of config and data"
            echo "  restore [path]  Restore from backup (latest if no path given)"
            echo "  list            List available backups"
            echo "  clean           Remove all backups"
            exit 1
            ;;
    esac
fi
