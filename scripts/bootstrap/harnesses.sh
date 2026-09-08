#!/usr/bin/env bash
# Optional native installers retain their own update and credential contracts.
set -euo pipefail
profile="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/profile.json"

run_installer() (
  set -euo pipefail
  local url="$1" installer
  shift
  installer="$(mktemp "${TMPDIR:-/tmp}/dotfiles-installer.XXXXXX")"
  trap 'rm -f "$installer"' EXIT
  curl --proto '=https' --tlsv1.2 -fsSL "$url" -o "$installer"
  bash "$installer" "$@"
)

install_hermes() (
  set -euo pipefail
  local installer stage
  installer="$(mktemp "${TMPDIR:-/tmp}/dotfiles-hermes.XXXXXX")"
  trap 'rm -f "$installer"' EXIT
  curl --proto '=https' --tlsv1.2 -fsSL https://hermes-agent.nousresearch.com/install.sh -o "$installer"
  # Its monolithic installer can start a messaging gateway. Explicit stages
  # provision the CLI without an auth flow, gateway or shell-rc rewrite.
  for stage in prerequisites repository venv python-deps node-deps config complete; do
    bash "$installer" --stage "$stage" --non-interactive \
      --commit 4281151ae859241351ba14d8c7682dc67ff4c126 \
      --skip-setup --skip-browser --skip-computer-use
  done
  ln -s "$HOME/.hermes/hermes-agent/venv/bin/hermes" "$HOME/.local/bin/hermes"
)

install_harness() {
  command -v "$1" >/dev/null && return
  case "$1" in
    claude) run_installer https://claude.ai/install.sh 2.1.260 ;;
    goose) CONFIGURE=false GOOSE_VERSION=v1.44.0 GOOSE_BIN_DIR="$HOME/.local/bin" \
      run_installer https://github.com/aaif-goose/goose/releases/download/v1.44.0/download_cli.sh ;;
    grok) SHELL=/bin/sh GROK_BIN_DIR="$HOME/.local/bin" run_installer https://x.ai/cli/install.sh 1.0.13 ;;
    hermes) install_hermes ;;
    pi) echo 'Pi is selected but missing from the global mise inventory.' >&2; return 1 ;;
    *) echo "Unknown harness: $1" >&2; return 1 ;;
  esac
}

while IFS= read -r harness; do install_harness "$harness"; done < <(jq -r '.harnesses[] | select(. != "opencode")' "$profile")
