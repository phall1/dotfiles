# .zshenv — ALWAYS sourced (every zsh invocation, interactive or not).
# Keep this MINIMAL. Doctor enforces <30 lines. Anything heavier belongs
# in .zprofile (login) or .zshrc (interactive).

# XDG base dirs (used by atuin, chezmoi, mise, fnm, …).
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
export XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME

# Editor — used by git, gh, claude, sudoedit, etc. Must be set everywhere
# (non-interactive scripts call $EDITOR too).
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"

# PATH essentials — only the bare minimum that non-interactive shells
# might need. The big PATH composition (cargo, go, bun, npm-global, etc.)
# happens in .zshrc — those are interactive concerns.
export PATH="$HOME/.local/bin:$PATH"

# Profiling gate — `ZSH_PROF=1 zsh -i -c exit` to capture zprof output.
[[ -n "${ZSH_PROF:-}" ]] && zmodload zsh/zprof
