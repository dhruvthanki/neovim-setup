# Makefile for NeoVim Setup
#
# Usage:
#   make install        - Full installation
#   make install-deps   - Install dependencies only
#   make install-nvim   - Install NeoVim only
#   make install-config - Setup configuration only
#   make help           - Show all commands

.PHONY: all install install-deps install-nvim install-config \
        backup restore uninstall clean health update help

# Default target
all: install

# Full installation
install:
	@./install.sh

# Install system dependencies only
install-deps:
	@./install.sh --deps-only

# Install NeoVim only
install-nvim:
	@./install.sh --nvim-only

# Install NeoVim via AppImage (fallback)
install-nvim-appimage:
	@./install.sh --nvim-only --method appimage

# Install NeoVim nightly
install-nvim-nightly:
	@./install.sh --nvim-only --version nightly

# Setup configuration symlink only
install-config:
	@./install.sh --config-only

# Force reinstall everything
reinstall:
	@./install.sh --force

# Backup current configuration
backup:
	@./scripts/lib/backup.sh backup

# Restore from most recent backup
restore:
	@./scripts/lib/backup.sh restore

# List available backups
list-backups:
	@./scripts/lib/backup.sh list

# Uninstall NeoVim and configuration
uninstall:
	@./uninstall.sh

# Uninstall everything including data
uninstall-all:
	@./uninstall.sh --all --force

# Remove only NeoVim, keep config
uninstall-nvim:
	@./uninstall.sh --nvim-only

# Remove only config, keep NeoVim
uninstall-config:
	@./uninstall.sh --config-only

# Clean cache and temporary files
clean:
	@echo "Cleaning NeoVim cache..."
	@rm -rf ~/.cache/nvim
	@rm -rf ~/.local/state/nvim
	@echo "Cache cleaned"

# Clean plugin data (requires reinstall of plugins)
clean-plugins:
	@echo "Cleaning plugin data..."
	@rm -rf ~/.local/share/nvim
	@echo "Plugin data cleaned"
	@echo "Run 'nvim' to reinstall plugins"

# Health check
health:
	@echo "==> NeoVim Setup Health Check"
	@echo ""
	@echo "NeoVim:"
	@command -v nvim >/dev/null 2>&1 && nvim --version | head -1 || echo "  Not installed"
	@echo ""
	@echo "Configuration:"
	@if [ -L ~/.config/nvim ]; then \
		echo "  Symlinked to: $$(readlink -f ~/.config/nvim)"; \
	elif [ -d ~/.config/nvim ]; then \
		echo "  Directory (not symlinked)"; \
	else \
		echo "  Not found"; \
	fi
	@echo ""
	@echo "Dependencies:"
	@command -v rg >/dev/null 2>&1 && echo "  ripgrep: installed" || echo "  ripgrep: MISSING"
	@(command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1) && echo "  fd: installed" || echo "  fd: MISSING"
	@command -v fzf >/dev/null 2>&1 && echo "  fzf: installed" || echo "  fzf: MISSING"
	@command -v git >/dev/null 2>&1 && echo "  git: installed" || echo "  git: MISSING"
	@command -v node >/dev/null 2>&1 && echo "  node: installed ($$(node --version))" || echo "  node: not installed (optional)"
	@echo ""

# Check installation status (alias for health)
status: health

# Update NeoVim to latest stable
update:
	@echo "==> Updating NeoVim..."
	@./scripts/install-neovim.sh --method source --version stable
	@echo ""
	@echo "==> Updating plugins..."
	@nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
	@echo "Update complete"

# Update to nightly
update-nightly:
	@echo "==> Updating to NeoVim nightly..."
	@./scripts/install-neovim.sh --method source --version nightly

# Update plugins only
update-plugins:
	@echo "==> Updating plugins..."
	@nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
	@echo "Plugins updated"

# Run NeoVim checkhealth
checkhealth:
	@nvim -c "checkhealth"

# Show help
help:
	@echo "NeoVim Setup - Available Commands"
	@echo ""
	@echo "Installation:"
	@echo "  make install              Full installation (deps + nvim + config)"
	@echo "  make install-deps         Install system dependencies only"
	@echo "  make install-nvim         Install NeoVim only (build from source)"
	@echo "  make install-nvim-appimage Install NeoVim via AppImage"
	@echo "  make install-config       Setup configuration symlink only"
	@echo "  make reinstall            Force reinstall everything"
	@echo ""
	@echo "Backup & Restore:"
	@echo "  make backup               Backup current configuration"
	@echo "  make restore              Restore from most recent backup"
	@echo "  make list-backups         List available backups"
	@echo ""
	@echo "Uninstallation:"
	@echo "  make uninstall            Remove NeoVim and config symlink"
	@echo "  make uninstall-all        Remove everything including plugin data"
	@echo "  make uninstall-nvim       Remove NeoVim only"
	@echo "  make uninstall-config     Remove config only"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean                Clean cache and state files"
	@echo "  make clean-plugins        Clean plugin data (triggers reinstall)"
	@echo "  make health               Check installation status"
	@echo "  make update               Update NeoVim and plugins"
	@echo "  make update-plugins       Update plugins only"
	@echo "  make checkhealth          Run NeoVim :checkhealth"
	@echo ""
