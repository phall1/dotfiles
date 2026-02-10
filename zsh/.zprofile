# ============================================================================
# Platform-specific initialization
# ============================================================================

# Detect OS once and store it
export DOTFILES_OS="${DOTFILES_OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

# macOS-specific setup
if [[ "$DOTFILES_OS" == "darwin" ]]; then
  # Homebrew setup
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  # Use GNU coreutils over BSD versions
  if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
    export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
  fi
fi

# Linux-specific setup
if [[ "$DOTFILES_OS" == "linux" ]]; then
  # Ensure local bin is in PATH
  export PATH="$HOME/.local/bin:$PATH"
fi

