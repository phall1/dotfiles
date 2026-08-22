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

install_formula() {
    local formula="$1"

    if brew list --formula "$formula" >/dev/null 2>&1; then
        echo "  ok: $formula"
    else
        brew install "$formula"
    fi
}

install_cask_app() {
    local cask="$1"
    shift

    if brew list --cask "$cask" >/dev/null 2>&1; then
        echo "  ok: $cask"
        return
    fi

    for app_path in "$@"; do
        if [[ -e "$app_path" ]]; then
            echo "  ok: $cask ($app_path already exists)"
            return
        fi
    done

    brew install --cask "$cask"
}

# Required substrate.
brew_formulae=(
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
    # Editor + git and local CI workflow
    neovim gh git tig gitui lazygit act
    # Misc
    direnv coreutils
)
brew_casks=(
    ghostty
    font-jetbrains-mono-nerd-font
)

echo "Installing brew formulae..."
for formula in "${brew_formulae[@]}"; do
    install_formula "$formula"
done

# Ensure an LTS Node/npm exists before provisioning the shared agent stack.
eval "$(fnm env --shell bash)"
if ! command -v npm >/dev/null 2>&1; then
    fnm install --lts --use
    fnm default "$(fnm current)"
    eval "$(fnm env --shell bash)"
fi
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install-agent-stack.sh"

# herdr owns its own agent-state hooks in ~/.claude/settings.json (and the
# opencode plugin). We deliberately do NOT track those hooks in chezmoi — they
# are versioned by herdr and regenerated here. The chezmoi modify_ script for
# settings.json merges our portable flags on top without clobbering them.
if command -v herdr >/dev/null 2>&1; then
    herdr integration install claude >/dev/null 2>&1 || true
fi

# coreutils for GNU versions on macOS (zprofile prepends them to PATH).
brew list coreutils >/dev/null 2>&1 || brew install coreutils
echo "Installing brew casks..."
for cask in "${brew_casks[@]}"; do
    case "$cask" in
    ghostty) install_cask_app "$cask" "/Applications/Ghostty.app" "$HOME/Applications/Ghostty.app" ;;
    *) install_cask_app "$cask" ;;
    esac
done

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
