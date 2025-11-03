# Dotfiles

My portable development environment configuration.

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## What's Included

- **Zsh**: Custom shell configuration with vi mode, history, and modular config files
- **Tmux**: Terminal multiplexer with vim-style navigation and custom theme
- **Git**: Global git configuration
- **Starship**: Modern, fast shell prompt
- **Scripts**: Custom utility scripts in `bin/`

## Structure

This repo uses [GNU Stow](https://www.gnu.org/software/stow/) for managing symlinks:

```
dotfiles/
├── zsh/              # Zsh configs → ~/
│   ├── .zshrc
│   ├── .zsh_plugins.txt
│   └── .zsh/         # Modular configs
├── tmux/             # Tmux config → ~/
│   └── .tmux.conf
├── git/              # Git config → ~/
│   └── .gitconfig
├── starship/         # Starship config → ~/.config/
│   └── .config/
│       └── starship.toml
├── bin/              # Scripts → ~/bin/
│   └── gh-actions-check
├── brew.txt          # Homebrew packages
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

## Secrets Management

API keys and secrets should go in `~/.zsh_secrets` (gitignored):

```bash
cp zsh/.zsh_secrets.example ~/.zsh_secrets
# Edit and add your secrets
```

## Customization

- **Git**: Update `git/.gitconfig` with your email
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
stow -D zsh tmux git starship bin  # Remove all symlinks
```
