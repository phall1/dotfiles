#!/usr/bin/env bash
# Source validation and offline clean-home tests. No host services or installers.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
jq empty renovate.json dot_config/opencode/opencode.jsonc dot_config/opencode/create_package.json
for file in mise*.toml mise*.lock .miserc.toml; do yq -p=toml -o=json '.' "$file" >/dev/null; done
find scripts/bootstrap tests/bootstrap -type f -name '*.sh' -print0 |
  while IFS= read -r -d '' file; do bash -n "$file"; done
for file in dot_zshenv dot_zprofile dot_zshrc dot_zsh/aliases.zsh dot_zsh/functions.zsh; do zsh -n "$file"; done
bash tests/bootstrap/fixtures.sh
bash tests/bootstrap/services.sh
bash tests/bootstrap/retirement.sh
uv run --script tests/bootstrap/configure_test.py
echo 'PASS: source syntax and isolated configuration contracts'
