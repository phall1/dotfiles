# Global binary checks. Sourced by dot-doctor. Uses exported helpers.

hdr "Required binaries"
require_bin zsh
require_bin git
require_bin atuin       "history substrate"
require_bin fzf
require_bin rg          "ripgrep"
require_bin yq          "structured config merge"
require_bin fd
require_bin bat
require_bin eza
require_bin delta       "git diff pager"
require_bin zoxide
require_bin gh
require_bin nvim
require_bin tmux

hdr "Wanted binaries"
want_bin chezmoi        "dotfile manager (task #7)"
want_bin age            "secret encryption"
want_bin uv             "Python toolchain"
want_bin fnm            "Node toolchain"
want_bin sesh           "tmux session picker"
want_bin claude         "Claude Code CLI"
want_bin pi             "Pi coding agent"
want_bin blackbird      "durable agent coordination"
want_bin open-websearch "harness-neutral web research"
want_bin lstags         "ls + Finder tags (cargo install via run_onchange)"

case "$(uname -s)" in
  Darwin)
    want_bin ghostty "Mac terminal"
    want_bin act     "local GitHub Actions runner"
    ;;
  Linux)  want_bin wezterm "Pi terminal (optional)" ;;
esac
