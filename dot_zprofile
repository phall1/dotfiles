# ============================================================================
# Platform-specific initialization
# ============================================================================

# Detect OS once and store it
export DOTFILES_OS="${DOTFILES_OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

# Nix setup (Determinate Nix, official installer, single-user, multi-user)
for nix_profile in \
  /etc/profile.d/nix.sh \
  "$HOME/.nix-profile/etc/profile.d/nix.sh" \
  /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

do
  if [[ -f "$nix_profile" ]]; then
    source "$nix_profile"
    break
  fi
done

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

# Note: Completions moved to .zshrc - compdef requires completion system to be initialized first

