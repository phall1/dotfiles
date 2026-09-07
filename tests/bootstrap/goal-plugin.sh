#!/usr/bin/env bash
# Exercise the exact V2 goal plugin pin against both its own and our SDK.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
spec="$(jq -r '.plugins[] | select(type == "object") | .package | select(startswith("github:phall1/opencode-goal-mode#"))' "$root/dot_config/opencode/opencode.jsonc")"
revision="${spec##*#}"
[[ "$revision" =~ ^[a-f0-9]{40}$ ]]
scratch="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-goal-test.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
curl --proto '=https' --tlsv1.2 -fsSL "https://codeload.github.com/phall1/opencode-goal-mode/tar.gz/$revision" | tar -xz --strip-components=1 -C "$scratch"
cd "$scratch"
npm ci --ignore-scripts
npm test
npm run check
sdk="$(jq -r '.dependencies["@opencode-ai/plugin"]' "$root/dot_config/opencode/create_package.json")"
npm install --ignore-scripts --no-save --package-lock=false "@opencode-ai/plugin@$sdk"
npm run check
