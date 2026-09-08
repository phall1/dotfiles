#!/usr/bin/env bash
# Invoked only after mise's tools phase. No tasks depend on each other in
# parallel: configuration must precede application registration.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/.local/bin:${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims:$HOME/.cargo/bin:$PATH"
bash "$root/scripts/bootstrap/configure.sh"
bash "$root/scripts/bootstrap/retire-legacy.sh"
chezmoi diff --source "$root"
chezmoi apply --source "$root"
mise trust "${XDG_CONFIG_HOME:-$HOME/.config}/mise/conf.d/dotfiles.toml"
# Install the selected optional inventories from the rendered global config.
mise -C "$HOME" install --yes
bash "$root/scripts/bootstrap/refresh-shell.sh"
bash "$root/scripts/bootstrap/integrations.sh"
# Optional native installers can seed config. Reconcile managed keys while
# preserving their runtime fields before the final drift gate.
chezmoi diff --source "$root"
chezmoi apply --source "$root"
bash "$root/scripts/bootstrap/history.sh"
"$HOME/.local/bin/dot-zcompile"
bash "$root/scripts/bootstrap/verify.sh"
