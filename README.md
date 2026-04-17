# Dotfiles

Portable development environment configuration.

## How It Works

This repo uses [GNU Stow](https://www.gnu.org/software/stow/) to manage symlinks. Each top-level directory is a "package" that mirrors the structure of your home directory. When you run `stow <package>`, it creates symlinks from your home directory to the files in that package.

```
~/dotfiles/starship/.config/starship.toml  →  ~/.config/starship.toml
~/dotfiles/zsh/.zshrc                      →  ~/.zshrc
```

Stow figures out the target path by removing the package name prefix. This keeps configs organized and version-controlled while your system sees them in the expected locations.

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh configure.sh
./install.sh
```

The installer will prompt for your user-specific settings (git name, email, GitHub username) on first run.

## What's Included

- **Zsh**: Shell config with vi mode, history, and modular config files
- **Neovim**: Editor config with LSP, Treesitter, and Twenty theme
- **Ghostty**: Terminal config with Twenty theme (hacker edition)
- **Starship**: Fast shell prompt with Twenty theme
- **Tmux**: Terminal multiplexer with vim-style navigation
- **Git**: Global git configuration
- **Nix**: Portable `~/.config/nix/nix.conf` plus shell initialization for common installers

## Structure

```
dotfiles/
├── ghostty/          # Ghostty terminal → ~/.config/
│   └── .config/
│       └── ghostty/
│           ├── config
│           └── themes/
│               ├── twenty.ghostty
│               └── twenty-dark
├── neovim/           # Neovim → ~/.config/
│   └── .config/
│       └── nvim/
│           ├── init.lua
│           └── colors/
│               └── twenty.lua
├── starship/         # Starship prompt → ~/.config/
│   └── .config/
│       └── starship.toml
├── zsh/              # Zsh configs → ~/
│   ├── .zshrc
│   ├── .zsh_plugins.txt
│   └── .zsh/
├── tmux/             # Tmux config → ~/
│   └── .tmux.conf
├── git/              # Git config → ~/
│   └── .gitconfig
├── nix/              # Nix config → ~/.config/
│   └── .config/
│       └── nix/
│           └── nix.conf
├── brew.txt          # Homebrew packages
├── stow-all.sh       # Stow all packages
└── install.sh        # Setup script
```

## Manual Setup

If you don't want to use the install script:

```bash
# Install dependencies
brew install stow antidote starship

# Link configs (run from dotfiles directory)
./stow-all.sh

# Install tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

## Nix Setup

This repo tracks the portable parts of Nix setup:

- `nix/.config/nix/nix.conf`
- shell init in `zsh/.zprofile` for common Nix install layouts

It intentionally does **not** track machine-specific installer state like launch daemons,
APFS volume setup, or installer receipts.

If you want the same installer again, use Determinate Nix:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

For a few more notes on what is and is not tracked, see `docs/nix.md`.

Then restow the repo:

```bash
./stow-all.sh
```

## Secrets Management

API keys and secrets should go in `~/.zsh_secrets` (gitignored):

```bash
cp zsh/.zsh_secrets.example ~/.zsh_secrets
# Edit and add your secrets
```

## Customization

- **User Settings**: Run `./configure.sh` to update git name/email and GitHub username
- **Zsh**: Add machine-specific configs to `zsh/.zsh/work.zsh`
- **Aliases**: Add custom aliases to `zsh/.zsh/aliases.zsh`
- **Functions**: Add custom functions to `zsh/.zsh/functions.zsh`

## Updating

```bash
cd ~/dotfiles
git pull
./stow-all.sh  # Restow every package
```

## Uninstalling

```bash
cd ~/dotfiles
./stow-all.sh -D  # Remove all symlinks
```
