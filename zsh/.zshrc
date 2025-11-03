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


#############
# Stuff that's supposed to be at the end?
#############

eval $(thefuck --alias)

# Starship prompt (must be last)

eval "$(mise activate zsh)"
eval "$(starship init zsh)"
