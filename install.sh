#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if user config exists, prompt to configure if not
if [ ! -f "$SCRIPT_DIR/.user.conf" ]; then
    echo "No user configuration found."
    echo "Running configure.sh to set up your personal settings..."
    echo ""
    "$SCRIPT_DIR/configure.sh"
    echo ""
fi

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
  echo "🍎 macOS detected"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS="linux"
  echo "🐧 Linux detected"
else
  echo "❌ Unsupported OS: $OSTYPE"
  exit 1
fi

if [ "$OS" == "macos" ]; then
  echo "📦 Installing Homebrew packages..."
  brew install stow
  # Brewfile lands in task #7 (chezmoi migration). Until then, packages are
  # provisioned by phall-dev playbook (macOS) and apt/nix (Linux).

elif [ "$OS" == "linux" ]; then
  echo "📦 Checking Linux dependencies..."
  if ! command -v stow &> /dev/null; then
    if command -v nix &> /dev/null; then
      nix profile install nixpkgs#stow
    else
      echo "❌ stow is required and Nix is not installed."
      echo "   Install stow with your distro package manager, or install Nix first:"
      echo "   curl -fsSL https://install.determinate.systems/nix | sh -s -- install"
      exit 1
    fi
  fi
fi

# Zsh plugins (raw — no plugin manager). Bootstrap clones into
# $XDG_DATA_HOME/zsh/plugins/ per zsh/plugins.lock.
echo ""
echo "🔌 Installing zsh plugins..."
"$SCRIPT_DIR/bin/.local/bin/dot-install-zsh-plugins"

echo ""
echo "📥 Initializing git submodules..."
git submodule update --init --recursive

echo ""
echo "🔗 Linking dotfiles with stow..."

# On Linux, skip ghostty (macOS only terminal)
if [ "$OS" == "linux" ]; then
  echo "Skipping ghostty (macOS only)..."
  stow -R $(ls -d */ | grep -v ghostty | sed 's/\///')
else
  ./stow-all.sh
fi

echo ""
echo "🎨 Installing additional dependencies..."

# TPM (tmux plugin manager) - works on both
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

echo ""
echo "✅ Done!"
echo ""
echo "Next steps:"
echo "  1. Copy zsh/.zsh_secrets.example to ~/.zsh_secrets and add your API keys"
echo "  2. Restart your terminal or run: source ~/.zshrc"
echo "  3. Open tmux and press 'Ctrl-a + I' to install tmux plugins"
echo ""
echo "To reconfigure user settings (git name/email), run: ./configure.sh"
echo ""
