# . "$HOME/.local/bin/env"

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

# Antidote plugin management
source $(brew --prefix)/share/antidote/antidote.zsh
antidote load ~/.zsh_plugins.txt

set -o vi

######## ALIASES
alias vim=nvim
alias zshrc='vim ~/.zshrc'
alias sz='source ~/.zshrc'
alias ghostconf='vim ~/.config/ghostty/config'
alias promptconf='vim ~/.config/starship.toml'


# NEOVIM
alias nvimrc='nvim ~/.config/nvim/init.lua'

alias tmuxconf='vim ~/.tmux.conf'
alias ccusage='npx ccusage@latest'
alias awsd="source _awsd"
alias awsconf='vim ~/.aws/config'
alias cclip='pbpaste | pbcopy'

alias ghcrlogin='gh auth token | docker login ghcr.io -u $(gh api user --jq .login) --password-stdin'

alias nload='TERM=xterm-256color nload'


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

# Atuin shell history
[ -f "$HOME/.atuin/bin/env" ] && source "$HOME/.atuin/bin/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Created by `pipx` on 2025-09-23 17:58:04
export PATH="$PATH:/Users/Patrick.Hall/.local/bin"
export PATH="$NVM_DIR/versions/node/$(nvm current)/bin:$PATH"
nvm use default >/dev/null




#############
# Stuff that's supposed to be at the end?
#############

eval $(thefuck --alias)

# Starship prompt (must be last)

# Only activate mise if we're in or under a directory with a .mise.toml or .tool-versions
if mise direnv activate >/dev/null 2>&1; then
  eval "$(mise activate bash)"  # or zsh/fish depending on your shell
fi

eval "$(starship init zsh)"

# bun completions
[ -s "/Users/Patrick.Hall/.bun/_bun" ] && source "/Users/Patrick.Hall/.bun/_bun"

. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"
