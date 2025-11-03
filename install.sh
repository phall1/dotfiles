#!/usr/bin/env bash

set -e

echo "📦 Installing Homebrew packages..."
if [ -f "brew.txt" ]; then
  cat brew.txt | xargs brew install
else
  echo "⚠️  brew.txt not found, skipping package installation"
fi

echo ""
echo "🔗 Installing GNU Stow..."
brew install stow

echo ""
echo "📝 Linking dotfiles with stow..."
stow zsh tmux git starship bin

echo ""
echo "🎨 Installing additional dependencies..."

# Install antidote (zsh plugin manager)
if [ ! -d "$(brew --prefix)/share/antidote" ]; then
  brew install antidote
fi

# Install TPM (tmux plugin manager)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Install starship
if ! command -v starship &> /dev/null; then
  brew install starship
fi

echo ""
echo "✅ Done!"
echo ""
echo "Next steps:"
echo "  1. Copy zsh/.zsh_secrets.example to ~/.zsh_secrets and add your API keys"
echo "  2. Update git/.gitconfig with your personal email if needed"
echo "  3. Restart your terminal or run: source ~/.zshrc"
echo "  4. Open tmux and press 'Ctrl-a + I' to install tmux plugins"
echo ""
