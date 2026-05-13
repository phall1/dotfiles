# Global binary checks. Sourced by dot-doctor. Uses exported helpers.

hdr "Required binaries"
require_bin zsh
require_bin git
require_bin atuin       "history substrate"
require_bin fzf
require_bin rg          "ripgrep"
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

case "$(uname -s)" in
  Darwin) want_bin ghostty "Mac terminal" ;;
  Linux)  want_bin wezterm "Pi terminal (optional)" ;;
esac
