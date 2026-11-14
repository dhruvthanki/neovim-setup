# NeoVim Setup

A unified, self-contained repository for installing NeoVim with LazyVim configuration on any PC.

## Quick Start

```bash
git clone https://github.com/dhruvthanki/neovim-setup.git ~/neovim-setup
cd ~/neovim-setup
make install
```

## Prerequisites

`make install` does not fetch everything it needs. Have these ready:

- **`sudo` access** for package installs; on Linux the default Neovim install builds from source into `/usr/local`.
- **`git`, `curl` and a C compiler** (the build dependencies install the compiler on Linux). Treesitter parsers are compiled.
- **A Rust toolchain (`cargo`) on Ubuntu/Debian/Fedora.** It builds the tree-sitter CLI (>= 0.26.1) that nvim-treesitter needs to compile parsers. The script does not install Rust; without the CLI treesitter highlighting will not work. On Arch and macOS the package manager provides the CLI instead.
- **Node.js 22+**, not installed by the script. pyright and yaml-language-server run on it. yaml-language-server declares `>= 22.13`; Node 20 worked in testing for diagnostics. Distro packages can be too old, so use a source that gives a current Node (NodeSource, nvm, ...).
- **Network access.** First launch installs plugins, parsers and language servers in the background and takes a few minutes.

## What It Does

1. **Detects your OS** (Ubuntu, Debian, Arch, Fedora, macOS)
2. **Backs up** existing `~/.config/nvim` if present
3. **Installs dependencies** (cmake, ninja, gcc, ripgrep, fd, fzf, tree-sitter CLI, lazygit)
4. **Installs NeoVim** (built from source at the pinned version on Linux; Homebrew on macOS, which installs the current release)
5. **Symlinks configuration** from this repo to `~/.config/nvim`
6. **Auto-installs plugins** via lazy.nvim on first launch (Mason tools and treesitter parsers install in the background at the same time)

## Supported Platforms

| OS | Package Manager | Status |
|----|-----------------|--------|
| Ubuntu 22.04 | apt | Verified: the config, plugins, language servers and the individual install steps. A clean-machine `make install` has not been run end to end. |
| Other Debian/Ubuntu | apt | Implemented, untested |
| Arch Linux | pacman | Implemented, untested |
| Fedora | dnf | Implemented, untested |
| macOS | Homebrew | Implemented, untested |
| Other Linux | AppImage | Fallback, untested |

## Commands

### Installation

```bash
make install            # Full installation
make install-deps       # System dependencies only
make install-nvim       # NeoVim only (Homebrew on macOS, source on Linux)
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
| `<leader>ff` | Find files (Snacks picker) |
| `<leader>fg` | Find git-tracked files |
| `<leader>/` | Live grep |
| `<leader>gg` | Open Lazygit |
| `<C-/>` | Toggle terminal |
| `<S-h>` / `<S-l>` | Previous/Next buffer |

### Plugins Included

- **LazyVim** - Base configuration framework (needs Neovim 0.12+ for the current nvim-treesitter)
- **Gruvbox** - Colorscheme
- **Neo-tree** - File explorer (enabled via the `editor.neo-tree` extra so LazyVim's Snacks explorer does not compete for `<leader>e`)
- **Snacks.nvim** - Picker, lazygit, terminal
- **Treesitter** - Syntax highlighting (parsers are built with the tree-sitter CLI)
- **LSP** - Language servers via Mason; C++ (clangd), Python, CMake and YAML extras are enabled
- **Which-key** - Keybinding hints

LazyVim extras are listed in `nvim/lazyvim.json`; manage them with `:LazyExtras`.

### Agent workflow

Run the agent (e.g. Claude Code) in its own multiplexer pane; nvim auto-reloads files it edits.

- `<leader>gv` / `<leader>gV` - Diffview of the working tree / current file history
- `claudecode.nvim` (`provider = "none"`) lets a Claude running in another pane connect via `/ide`:
  `<leader>ab` add buffer, `<leader>as` send selection, `<leader>aa` / `<leader>ad` accept / deny a diff

### C/C++ in catkin workspaces

`nvim/lua/plugins/clangd.lua` roots clangd at the nearest `package.xml`, points it at
`<ws>/build/<pkg>/compile_commands.json`, and passes `--query-driver` so system headers resolve.
Build the package first so the compile database exists. Headers that only exist in a dev
container (e.g. `/opt/ros/...`) will still be reported as not found when editing on the host.

### Tested toolchain

What this config was last verified with (2026-11-14, Ubuntu 22.04). "Pinned" means the install
scripts install exactly that version; "recorded" means it floats and the number is for reference.

| Tool | Version | Status |
|------|---------|--------|
| Neovim | v0.12.6 | pinned in `scripts/install-neovim.sh` for source and AppImage installs; the Homebrew and apt-PPA routes install whatever is current. `make update` moves to latest stable: bump the pin after |
| tree-sitter CLI | 0.27.2 | pinned in `scripts/install-deps.sh` (cargo route; pacman/brew follow the distro) |
| lazygit | 0.66.3 | pinned in `scripts/install-deps.sh` (release-tarball route; pacman/brew follow the distro) |
| Plugins incl. LazyVim v16.0.2 | see `nvim/lazy-lock.json` | pinned to exact commits; `lazyvim.json` lists the extras |
| clangd, pyright, ruff, neocmakelsp, yaml-language-server | 23.1.0, 1.1.414, 0.17.5, 0.12.0, 2.0.0 | recorded: Mason installs language servers by name only, so they cannot be pinned from config |
| lua-language-server, stylua, shfmt | 3.16.4, 2.3.1, v3.12.0 | recorded (Mason) |
| cmakelint, cmakelang | 1.4.3, 0.6.13 | recorded (Mason, or `uv tool install` where Mason cannot build venvs) |

### Troubleshooting

- **Mason fails with `ensurepip` / venv errors** (Python tools such as `cmakelint`): a Python
  without `venv` is first on `PATH` (e.g. a uv-managed one). Install the tool another way, e.g.
  `uv tool install cmakelint cmakelang`.

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
        ├── colorscheme.lua  # Gruvbox
        ├── explorer.lua     # Neo-tree
        ├── ui.lua           # Snacks, which-key, lualine, bufferline
        └── clangd.lua       # catkin-aware clangd (compile databases, system headers)
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
    ├── lazyvim.json          # Enabled LazyVim extras
    ├── lazy-lock.json        # Plugin versions, pinned to exact commits
    └── lua/
        ├── config/           # options, keymaps, autocmds, lazy.nvim bootstrap
        └── plugins/          # one file per concern
```

## License

MIT
