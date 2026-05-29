#!/usr/bin/env bash
# bootstrap-darwin.sh — install host-level dependencies on macOS.
# Idempotent. Re-run any time.

set -euo pipefail

# Brew itself.
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Ricing taps:
#   koekeishiya/formulae  — yabai (skhd is on this tap too but in maintenance mode; we use the Zig rewrite below)
#   FelixKratz/formulae   — sketchybar, borders
#   jackielii/tap         — skhd-zig (actively-maintained drop-in replacement for skhd)
brew tap koekeishiya/formulae 2>/dev/null || true
brew tap FelixKratz/formulae 2>/dev/null || true
brew tap jackielii/tap 2>/dev/null || true

# Required substrate.
brew_packages=(
  # Core tools
  chezmoi age stow
  # Shell substrate
  atuin fzf fd eza git-delta zoxide bat ripgrep jq
  # Language toolchains
  uv fnm rustup-init
  # Terminal stack
  ghostty tmux sesh
  # AI agent multiplexer (self-manages its Claude/opencode hooks via
  # `herdr integration install` — see the integration step below).
  herdr
  # Editor + git workflow
  neovim gh git tig gitui lazygit
  # Misc
  direnv
  # Ricing — window manager, hotkeys, status bar, window borders.
  # SIP is NOT disabled by default; see docs/RICE.md for the SIP upgrade path.
  # skhd-zig auto-reloads on config change (no manual restart needed).
  yabai skhd-zig sketchybar borders
)
echo "Installing brew packages..."
for pkg in "${brew_packages[@]}"; do
  brew list "$pkg" >/dev/null 2>&1 || brew install "$pkg"
done

# Casks (fonts for sketchybar icons + nerd-font glyphs).
brew_casks=(
  font-jetbrains-mono-nerd-font
  font-sketchybar-app-font
)
echo "Installing brew casks..."
for cask in "${brew_casks[@]}"; do
  brew list --cask "$cask" >/dev/null 2>&1 || brew install --cask "$cask"
done

# herdr owns its own agent-state hooks in ~/.claude/settings.json (and the
# opencode plugin). We deliberately do NOT track those hooks in chezmoi — they
# are versioned by herdr and regenerated here. The chezmoi modify_ script for
# settings.json merges our portable flags on top without clobbering them.
if command -v herdr >/dev/null 2>&1; then
  herdr integration install claude >/dev/null 2>&1 || true
fi

# coreutils for GNU versions on macOS (zprofile prepends them to PATH).
brew list coreutils >/dev/null 2>&1 || brew install coreutils

cat <<'EOF'

==========================================================================
  ✓ Host bootstrap complete (Darwin)
==========================================================================

Next steps — copy/paste these in order:

  1. Configure this machine's git identity (interactive):

       ~/dotfiles/scripts/setup-chezmoi.sh

  2. Apply dotfiles to $HOME (idempotent; safe to re-run):

       chezmoi apply

  3. Verify the substrate is healthy:

       ~/.local/bin/dot-doctor      # 0 failures expected
       ~/.local/bin/dot-bench       # numbers under PERF.md baselines

  4. Restart your shell:

       exec zsh

Daily flow from here:
  $EDITOR ~/dotfiles/dot_zshrc      # source-of-truth lives in ~/dotfiles
  chezmoi diff                      # preview what would change
  chezmoi apply                     # propagate to $HOME

Full guide: ~/dotfiles/docs/setup.md
==========================================================================
EOF
