#!/usr/bin/env bash
# Product installers own registration and services. A healthy live service is
# never reinstalled simply because bootstrap ran again.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
profile="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/profile.json"
export PATH="$HOME/.local/bin:${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims:$HOME/.cargo/bin:$PATH"

install_opencode() {
  command -v opencode >/dev/null && return
  # Official V2 CLI. Seed a released 2.x; native auto-update takes over,
  # outside mise's immutable tool-version directories. The pre-release
  # @opencode-ai/cli package only shipped `opencode2` and must not be reinstalled.
  npm install --global --prefix "$HOME/.local" '@opencode/cli@2.0.2'
}

install_rust() {
  if ! command -v rustup >/dev/null; then
    curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain stable
  fi
  if ! rustup show active-toolchain >/dev/null 2>&1; then rustup default stable; fi
  cargo install --path "$root/src/lstags" --locked --quiet
}

install_pi_extensions() {
  jq -r '.packages[] | if type == "object" then .source else . end | select(type == "string")' "$HOME/.pi/agent/settings.json" |
    while IFS= read -r package; do pi install "$package"; done
}

install_opencode
install_rust
bash "$root/scripts/bootstrap/harnesses.sh"
if jq -e '.harnesses | index("pi")' "$profile" >/dev/null; then install_pi_extensions; fi
bash "$root/scripts/bootstrap/services.sh"
