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
want_bin mise           "workstation bootstrap and tool versions"
want_bin sesh           "tmux session picker"
want_bin opencode2      "OpenCode V2 CLI"
want_bin blackbird      "durable agent coordination"
want_bin phux           "persistent terminal server"
want_bin phux-mcp       "terminal MCP integration"
want_bin phig           "Git history browser"
want_bin phui           "GitHub workflow UI"
want_bin open-websearch "harness-neutral web research"
want_bin lstags         "ls + Finder tags (cargo install via run_onchange)"

case "$(uname -s)" in
  Darwin)
    want_bin ghostty "Mac terminal"
    want_bin act     "local GitHub Actions runner"
    ;;
  Linux) ;;
esac
