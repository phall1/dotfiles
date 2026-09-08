#!/usr/bin/env bash
# Real clean-machine install, then a second convergence. This script runs only
# inside the image; the host wrapper never mounts HOME, credentials or sockets.
set -euo pipefail
[[ "$(id -u)" != 0 && "$HOME" == /home/tester ]]
[[ ! -d "$HOME/.local/share/mise/installs" ]]
git config --global user.name 'Bootstrap Fixture'
git config --global user.email 'fixture@example.invalid'
shell_before="$(getent passwd tester | cut -d: -f7)"
git init --quiet "$HOME/fixture-repo"
bash scripts/bootstrap-linux.sh --yes --update
mise bootstrap dotfiles save
mise ls --current --json > /home/tester/first-tools.json
mise install --dry-run-code
chezmoi verify --exclude scripts
phig --repo "$HOME/fixture-repo" snapshot status >/dev/null
nvim --clean --headless '+quit'
opencode2 models > "$HOME/models.txt"
# The account-scoped catalog may be empty before /connect; command success
# still exercises the native CLI on this architecture without host credentials.
for mode in -c -ic -lic; do
  PATH=/usr/bin:/bin zsh "$mode" 'set -e; for tool in node uv opencode2 phux blackbird; do command -v "$tool"; done; node --version; uv --version; phux --version; blackbird --version' </dev/null
done
[[ ! -e "$HOME/.config/systemd/user/blackbird.service" ]]
[[ ! -e "$HOME/.config/systemd/user/phux.service" ]]
[[ "$(getent passwd tester | cut -d: -f7)" == "$shell_before" ]]
bash scripts/bootstrap-linux.sh --yes --skip repos
mise ls --current --json > /home/tester/second-tools.json
cmp /home/tester/first-tools.json /home/tester/second-tools.json
chezmoi verify --exclude scripts
bash tests/bootstrap/check.sh
uv run --script tests/bootstrap/history_test.py
echo 'PASS: real Linux installation, shell access, app config, and second-run convergence'
