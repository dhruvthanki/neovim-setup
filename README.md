# NeoVim Setup

A unified, self-contained repository for installing NeoVim with LazyVim configuration on any PC.

## Quick Start

```bash
git clone https://github.com/dhruvthanki/neovim-setup.git ~/neovim-setup
cd ~/neovim-setup
make install
```

## What It Does

1. **Detects your OS** (Ubuntu, Debian, Arch, Fedora, macOS)
2. **Backs up** existing `~/.config/nvim` if present
3. **Installs dependencies** (cmake, ninja, gcc, ripgrep, fd, fzf)
4. **Builds NeoVim** from source (latest stable)
5. **Symlinks configuration** from this repo to `~/.config/nvim`
6. **Auto-installs plugins** via lazy.nvim on first launch

## Supported Platforms

| OS | Package Manager | Status |
|----|-----------------|--------|
| Ubuntu/Debian | apt | Primary |
| Arch Linux | pacman | Primary |
| Fedora | dnf | Secondary |
| macOS | Homebrew | Secondary |
| Other Linux | AppImage | Fallback |

## Commands

### Installation

```bash
make install            # Full installation
make install-deps       # System dependencies only
make install-nvim       # NeoVim only (build from source)
make install-config     # Configuration symlink only
```

### Maintenance

```bash
make update             # Update NeoVim and plugins
make update-plugins     # Update plugins only
make health             # Check installation status
make checkhealth        # Run NeoVim :checkhealth
make clean              # Clean cache files
```

### Backup & Restore

```bash
make backup             # Backup current configuration
make restore            # Restore from backup
make list-backups       # Show available backups
```

### Uninstallation

```bash
make uninstall          # Remove NeoVim and config
make uninstall-all      # Remove everything including data
```

## Configuration

The NeoVim configuration lives in `~/neovim-setup/nvim/` and is symlinked to `~/.config/nvim`.

### Key Bindings

| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `<leader>e` | Toggle file explorer (Neo-tree) |
| `<leader>ff` | Find files (Telescope) |
| `<leader>fg` | Live grep (Telescope) |
| `<leader>gg` | Open Lazygit |
| `<C-/>` | Toggle terminal |
| `<S-h>` / `<S-l>` | Previous/Next buffer |

### Plugins Included

- **LazyVim** - Base configuration framework
- **Gruvbox** - Colorscheme
- **Neo-tree** - File explorer
- **Snacks.nvim** - QoL improvements
- **Telescope** - Fuzzy finder
- **Treesitter** - Syntax highlighting
- **LSP** - Language server support
- **Which-key** - Keybinding hints

### Customization

Edit files in `~/neovim-setup/nvim/lua/`:

```
nvim/
├── init.lua                 # Entry point
└── lua/
    ├── config/
    │   ├── lazy.lua         # Plugin manager setup
    │   ├── options.lua      # Editor options
    │   ├── keymaps.lua      # Key bindings
    │   └── autocmds.lua     # Auto commands
    └── plugins/
        └── theme.lua        # Theme & UI plugins
```

Changes take effect immediately (no need to reinstall).

## Advanced Options

### Install NeoVim via AppImage

```bash
./install.sh --method appimage
```

### Install Nightly Build

```bash
./install.sh --version nightly
```

### Install Specific Version

```bash
./install.sh --version v0.10.0
```

### Force Reinstall

```bash
make reinstall
# or
./install.sh --force
```

## Syncing Across Machines

1. **Initial setup**: Clone and install on your first machine
2. **Push changes**: Commit and push any config changes
3. **New machine**: Clone repo and run `make install`
4. **Sync config**: `git pull` to get latest changes

```bash
# On new machine
git clone https://github.com/dhruvthanki/neovim-setup.git ~/neovim-setup
cd ~/neovim-setup
make install

# After making config changes
git add -A && git commit -m "Update config" && git push

# On other machines
cd ~/neovim-setup && git pull
```

## Troubleshooting

### NeoVim not found after install

Add to your shell config (`~/.bashrc` or `~/.zshrc`):

```bash
export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
```

### Build fails

Try the AppImage method:

```bash
make uninstall-nvim
./install.sh --nvim-only --method appimage
```

### Plugin errors on first launch

```bash
# Clean plugin data and reinstall
make clean-plugins
nvim  # Plugins will reinstall
```

### Check system health

```bash
make health      # Quick check
nvim -c "checkhealth"  # Full check inside NeoVim
```

## File Structure

```
~/neovim-setup/
├── README.md                 # This file
├── Makefile                  # User-friendly interface
├── install.sh                # Main installation script
├── uninstall.sh              # Cleanup script
├── scripts/
│   ├── lib/
│   │   ├── common.sh         # Shared utilities
│   │   ├── detect-os.sh      # OS detection
│   │   └── backup.sh         # Backup utilities
│   ├── install-deps.sh       # Install dependencies
│   ├── install-neovim.sh     # Build/install NeoVim
│   └── setup-config.sh       # Setup config symlink
└── nvim/                     # NeoVim configuration
    ├── init.lua
    └── lua/
        ├── config/
        └── plugins/
```

## License

MIT
