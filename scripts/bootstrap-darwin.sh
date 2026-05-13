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
  # Editor + git workflow
  neovim gh git tig gitui lazygit
  # Misc
  direnv
)
echo "Installing brew packages..."
for pkg in "${brew_packages[@]}"; do
  brew list "$pkg" >/dev/null 2>&1 || brew install "$pkg"
done

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
