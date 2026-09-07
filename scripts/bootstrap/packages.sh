#!/usr/bin/env bash
# Runs before mise installs tools, so only seed-host commands are available.
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || exit 0
command -v brew >/dev/null || { echo 'Homebrew is required: run scripts/bootstrap-darwin.sh first.' >&2; exit 1; }
export HOMEBREW_NO_AUTO_UPDATE=1
brew bundle --file=provision/Brewfile --no-upgrade
case ",${MISE_ENV:-}," in
  *,server,*|*,container,*) ;;
  *) brew bundle --file=provision/Brewfile.desktop --no-upgrade ;;
esac
