#!/usr/bin/env bash
# Enrollment is local. An origin is connected explicitly after reviewing the
# first checkpoint; the native watcher owns all later saves and synchronization.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
uv run --quiet --script "$root/scripts/bootstrap/history.py"
config="${XDG_CONFIG_HOME:-$HOME/.config}/mise/conf.d/dotfiles-history.toml"
mise trust "$config"
chezmoi diff "$HOME/.config/dotfiles/profile.json"
chezmoi apply "$HOME/.config/dotfiles/profile.json"
# The enclosing native bootstrap holds its history transaction until exit.
# Its watcher captures the enrolled files after that transaction completes.
# Reconcile both running and absent immediately using our machine-local global
# declaration. System and HOME project configuration retain native precedence.
MISE_GLOBAL_CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/mise/conf.d/zz-dotfiles-services.local.toml" \
  mise -C "$HOME" bootstrap services apply --yes
