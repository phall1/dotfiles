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
  if [ -f "brew.txt" ]; then
    xargs brew install < brew.txt
  fi
  brew install stow

  # Install antidote (zsh plugin manager)
  if [ ! -d "$(brew --prefix)/share/antidote" ]; then
    brew install antidote
  fi

  # Install starship
  if ! command -v starship &> /dev/null; then
    brew install starship
  fi

elif [ "$OS" == "linux" ]; then
  echo "📦 Checking Nix packages..."
  # Stow should be installed, but check just in case
  if ! command -v stow &> /dev/null; then
    nix profile install nixpkgs#stow
  fi

  # Install antidote via git on Linux
  if [ ! -d "$HOME/.antidote" ]; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
  fi

  # Starship is already installed via phall-dev playbook
fi

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
