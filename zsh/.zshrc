# ============================================================================
# Zsh Configuration - Cross-Platform & Composable
# ============================================================================

# Source OS detection from .zprofile if available
[[ -f ~/.zprofile ]] && source ~/.zprofile

# Fallback OS detection
export DOTFILES_OS="${DOTFILES_OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

# ============================================================================
# Nix - only if available
# ============================================================================

if [[ -f /etc/profile.d/nix.sh ]]; then
  source /etc/profile.d/nix.sh
elif [[ -f ~/.nix-profile/etc/profile.d/nix.sh ]]; then
  source ~/.nix-profile/etc/profile.d/nix.sh
elif [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# ============================================================================
# PATH - composable additions
# ============================================================================

# Opencode
export PATH="$HOME/.opencode/bin:$PATH"

# Local binaries (user-installed)
export PATH="$HOME/.local/bin:$PATH"

# Cargo/rust
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"

# Go
[[ -d "$HOME/go/bin" ]] && export PATH="$HOME/go/bin:$PATH"

[[ -d "$HOME/.bun/bin" ]] && export PATH="$HOME/.bun/bin:$PATH"

# ============================================================================
# Tool Initializations - only if tools exist
# ============================================================================

# Starship prompt
command -v starship &>/dev/null && eval "$(starship init zsh)"

# Zoxide (smarter cd)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# Direnv
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# FZF
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# Atuin (shell history)
command -v atuin &>/dev/null && eval "$(atuin init zsh)"

# ============================================================================
# Modular Config Loading
# ============================================================================

# Load all .zsh files from ~/.zsh/ (alphabetical order)
if [[ -d ~/.zsh ]]; then
  for config_file in ~/.zsh/*.zsh; do
    [[ -f "$config_file" ]] && source "$config_file"
  done
fi

# Secrets (gitignored)
[[ -f ~/.zsh_secrets ]] && source ~/.zsh_secrets

# Machine-local overrides (gitignored)
[[ -f ~/.zsh_local ]] && source ~/.zsh_local

# ============================================================================
# Shell Options
# ============================================================================

# Vi mode
bindkey -v
export KEYTIMEOUT=1

# Enable color support
export CLICOLOR=1
[[ "$DOTFILES_OS" == "linux" ]] && alias ls='ls --color=auto'

# History
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# ============================================================================
# Editor
# ============================================================================

export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"


