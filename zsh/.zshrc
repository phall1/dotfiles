# . "$HOME/.local/bin/env"

# Nix
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
# End Nix

# Performance-optimized completion system
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_DUPS SHARE_HISTORY

# MISE let's let the mise tools win

# Antidote plugin management (works on both Intel and Apple Silicon Macs)
if [[ -f /opt/homebrew/share/antidote/antidote.zsh ]]; then
  source /opt/homebrew/share/antidote/antidote.zsh
elif [[ -f /usr/local/share/antidote/antidote.zsh ]]; then
  source /usr/local/share/antidote/antidote.zsh
fi
antidote load ~/.zsh_plugins.txt

# Use vi mode and set escape key timeout to avoid delays
set -o vi
KEYTIMEOUT=1

# coreutils
alias date=gdate

######## ALIASES
alias vim=nvim
alias zshrc='vim ~/.zshrc'
alias sz='source ~/.zshrc'
alias ghostconf='vim ~/.config/ghostty/config'
alias promptconf='vim ~/.config/starship.toml'
alias pc='process-compose'
alias coder='npx -y @just-every/code'



####################
# GIT
####################
alias gs='git status'
alias g='git'

# Listing files 
# # 1. The basic 'ls' replacement
# --icons: adds the file icons
# --group-directories-first: always puts folders at the top (cleaner)
alias ls='eza --icons --group-directories-first'

# 2. 'll' (Long List) - The most popular one
# -l: long format (permissions, size, etc.)
# --git: adds a column showing git status (dirty, new, ignored)
# --header: adds a header row (Permissions, Size, User, etc.)
alias ll='eza --icons --group-directories-first -l --git --header'

# 3. 'la' (List All) - For hidden files
# -a: all files (including .files)
alias la='eza --icons --group-directories-first -a'

# 4. 'lt' (Tree view)
# --tree: shows a directory tree (replaces the 'tree' command)
# --level=2: only goes 2 folders deep so it doesn't flood your screen
# alias lt='eza --icons --tree --level=2'
# alias ls='lsd'
# alias l='lsd -l'
# alias la='lsd -a'      # <--- This is likely the "lsa" you remember
# alias lla='lsd -la'
# alias lt='lsd --tree'
# alias ll='eza --icons --long --git'
#
#
# NEOVIM
alias nvimrc='nvim ~/.config/nvim/init.lua'

alias tmuxconf='vim ~/.tmux.conf'
alias ccusage='npx ccusage@latest'
alias awsd="source _awsd"
alias awsconf='vim ~/.aws/config'
alias cclip='pbpaste | pbcopy'

alias ghcrlogin='gh auth token | docker login ghcr.io -u $(gh api user --jq .login) --password-stdin'

alias nload='TERM=xterm-256color nload'
alias tealdeer='tldr'

# beadsviewer wrapper for git worktree support (stealth mode - not committed)
# bv doesn't auto-detect .beads in worktrees like bd does, so we help it
bv() {
  local git_common_dir beads_dir
  git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
  if [[ -n "$git_common_dir" && -d "$git_common_dir/../.beads" ]]; then
    beads_dir="$git_common_dir/../.beads"
  elif [[ -d ".beads" ]]; then
    beads_dir=".beads"
  fi
  BEADS_DIR="$beads_dir" command bv "$@"
}

#############
### Make LS colorful
#############
export CLICOLOR=1
export LSCOLORS="GxFxCxDxBxegedabagaced"

#############
# Custom modular configs (add this at the very end)
############
for file in ~/.zsh/{aliases,functions,work}.zsh; do
  [ -r "$file" ] && source "$file"
done

# Source local secrets (gitignored)
[ -f ~/.zsh_secrets ] && source ~/.zsh_secrets

# Add custom scripts to PATH
export PATH="$HOME/bin:$PATH"
export PATH="/opt/homebrew/bin/:$PATH"

# Lazy-load NVM (only loads when you actually use node/npm/nvm)
export NVM_DIR="$HOME/.nvm"
# Add default node to PATH if it exists (nvm alias default)
[[ -d "$NVM_DIR/alias/default" ]] && export PATH="$NVM_DIR/versions/node/$(cat "$NVM_DIR/alias/default")/bin:$PATH"

# Lazy load function - NVM will only initialize when you call it
nvm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}

node() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  node "$@"
}

npm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  npm "$@"
}

npx() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  npx "$@"
}

# pipx and local binaries
export PATH="$PATH:$HOME/.local/bin"


# Bun
export PATH="$HOME/.bun/bin:$PATH"



#############
# Stuff that's supposed to be at the end?
#############

# Lazy-load thefuck (only loads when you use it)
fuck() {
  unset -f fuck
  eval $(thefuck --alias)
  fuck "$@"
}

# Starship prompt (must be last)

# Activate mise if installed
command -v mise >/dev/null && eval "$(mise activate zsh)"

eval "$(direnv hook zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

# bun completions
[ -s "/Users/Patrick.Hall/.bun/_bun" ] && source "/Users/Patrick.Hall/.bun/_bun"


export PATH="$PATH:$HOME/go/bin"

# AsyncAPI CLI Autocomplete

# AsyncAPI CLI autocomplete
ASYNCAPI_AC_ZSH_SETUP_PATH="$HOME/Library/Caches/@asyncapi/cli/autocomplete/zsh_setup"
[[ -f "$ASYNCAPI_AC_ZSH_SETUP_PATH" ]] && source "$ASYNCAPI_AC_ZSH_SETUP_PATH"



# Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

alias claude-mem='bun "$HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/Patrick.Hall/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/Patrick.Hall/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/Patrick.Hall/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/Patrick.Hall/google-cloud-sdk/completion.zsh.inc'; fi
