# ============================================================================
# Zsh Configuration - Cross-Platform & Composable
# ============================================================================
#
#

####################
# EPHEMERAL PROBLY REMOVE THESE AT SOME POTINS
# ###################
export TASK_X_REMOTE_TASKFILES=1

# Source OS detection from .zprofile if available
[[ -f ~/.zprofile ]] && source ~/.zprofile

# Fallback OS detection
export DOTFILES_OS="${DOTFILES_OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

# ============================================================================
# Nix
# ============================================================================

# Nix setup lives in ~/.zprofile so login shells and interactive shells share it.

# ============================================================================
# PATH - composable additions
# ============================================================================
#
export PATH="/Users/Patrick.Hall/.firecrew/bin:$PATH"

# Opencode
export PATH="$HOME/.opencode/bin:$PATH"

# Local binaries (user-installed)
export PATH="$HOME/.local/bin:$PATH"

# Cargo/rust
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"

# Go
[[ -d "$HOME/go/bin" ]] && export PATH="$HOME/go/bin:$PATH"

[[ -d "$HOME/.bun/bin" ]] && export PATH="$HOME/.bun/bin:$PATH"

# npm global (writable prefix for Nix-managed node)
[[ -d "$HOME/.npm-global/bin" ]] && export PATH="$HOME/.npm-global/bin:$PATH"

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

command -v fuck &>/dev/null && eval "$(thefuck --alias)"

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

# ============================================================================
# Completion System
# ============================================================================

# Initialize completion system
autoload -Uz compinit && compinit

# gt (graphite CLI) completions
if command -v gt &>/dev/null; then
  _gt_yargs_completions() {
    local reply
    local si=$IFS
    IFS=$'\n' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" gt --get-yargs-completions "${words[@]}"))
    IFS=$si
    _describe 'values' reply
  }
  compdef _gt_yargs_completions gt
fi

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



# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Warp terminal
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# OpenFang
[[ -d "$HOME/.openfang/bin" ]] && export PATH="$HOME/.openfang/bin:$PATH"

# Google Cloud SDK
[ -f "$HOME/Downloads/google-cloud-sdk/path.zsh.inc" ] && source "$HOME/Downloads/google-cloud-sdk/path.zsh.inc"
[ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ] && source "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
