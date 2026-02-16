# Custom aliases

# ============================================================================
# OS Detection Helpers
# ============================================================================

alias is-macos='[[ "$DOTFILES_OS" == "darwin" ]] && echo "yes" || echo "no"'
alias is-linux='[[ "$DOTFILES_OS" == "linux" ]] && echo "yes" || echo "no"'

# ============================================================================
# Platform-Specific Aliases
# ============================================================================

if [[ "$DOTFILES_OS" == "darwin" ]]; then
  # macOS-specific
  alias ls='ls -G'
  alias flush-dns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
  alias show-hidden='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
  alias hide-hidden='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'
  alias battery='pmset -g batt'
  alias wifi='networksetup -getairportnetwork en0'
  
  # Quick look from terminal
  ql() { qlmanage -p "$@" &>/dev/null; }
  
  # OpenCode - run built binary from dev branch (macOS ARM)
  alias ocsrc='~/workspace/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode'
  alias opencode-dev='bun run --cwd ~/workspace/opencode/packages/opencode --conditions=browser src/index.ts'
  alias cdoc='cd ~/workspace/opencode'
  
elif [[ "$DOTFILES_OS" == "linux" ]]; then
  # Linux-specific
  alias ls='ls --color=auto'
  alias open='xdg-open 2>/dev/null || echo "xdg-open not available"'
  alias pbcopy='xclip -selection clipboard -in 2>/dev/null || wl-copy 2>/dev/null || echo "Clipboard tool not found"'
  alias pbpaste='xclip -selection clipboard -out 2>/dev/null || wl-paste 2>/dev/null || echo "Clipboard tool not found"'
  alias update='sudo apt update && sudo apt upgrade -y 2>/dev/null || sudo pacman -Syu 2>/dev/null || echo "Unknown package manager"'
  alias ports='ss -tuln'
  alias mem='free -h'
  alias cpu='lscpu | grep "Model name"'
  alias disk='df -h'
  
  # Process management
  alias psa='ps auxf'
fi

# ============================================================================
# Universal Aliases (work everywhere)
# ============================================================================

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# Listing
alias l='ls -lah'
alias la='ls -lah'
alias ll='ls -lh'
alias lt='ls -lahrt'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Utils
alias grep='grep --color=auto'
alias mkdirp='mkdir -p'
alias cls='clear'
alias h='history'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias gl='git log --oneline --graph'
alias glog='git log --oneline --graph --all --decorate'

# Tmux shortcuts
alias tm='tmux'
alias tma='tmux attach'
alias tml='tmux list-sessions'
alias tmk='tmux kill-session'

# Editor
alias vim='nvim'

# Quick config access
alias sz='source ~/.zshrc'
alias zshrc='${EDITOR:-nvim} ~/.zshrc'
alias vimrc='${EDITOR:-nvim} ~/.config/nvim/init.lua'
alias nvimrc='${EDITOR:-nvim} ~/.config/nvim/init.lua'
alias tmuxconf='${EDITOR:-nvim} ~/.tmux.conf'
alias ghostconf='${EDITOR:-nvim} ~/.config/ghostty/config'
alias promptconf='${EDITOR:-nvim} ~/.config/starship.toml'

# GitHub PR workflow
alias prs='gh pr list --search "is:open sort:updated-desc"'
alias myprs='gh pr list --author @me --search "is:open sort:updated-desc"'
alias reviewme='gh pr list --review-requested @me --search "is:open sort:updated-desc"'
alias prv='gh pr view --web=false'
alias prd='gh pr diff'
