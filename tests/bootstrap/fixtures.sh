#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-fixtures.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin"
# Provision the parser once; actual fixture runs are explicitly offline.
uv run --script "$root/dot_config/phux/modify_config.toml" </dev/null >/dev/null
uv_cache="$(uv cache dir)"
uv_python="$(uv python find '>=3.11')"

resolve_binary() {
  local binary="$1" resolved directory
  local shim_dir="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"
  local -a directories
  if resolved="$(mise which "$binary" 2>/dev/null)"; then
    printf '%s\n' "$resolved"
    return
  fi
  # An installed but inactive tool can still have a shim. Resolve its system
  # fallback ourselves; the isolated HOME cannot resolve that orphaned shim.
  IFS=: read -r -a directories <<< "$PATH"
  for directory in "${directories[@]}"; do
    [[ "$directory" == "$shim_dir" ]] && continue
    [[ -x "$directory/$binary" ]] || continue
    printf '%s\n' "$directory/$binary"
    return
  done
  return 1
}

for binary in chezmoi jq yq gh bash git uv; do
  # A mise shim would resolve against the empty fixture HOME and require trust
  # there. Fixtures need the actual preinstalled executable, not its launcher.
  resolved="$(resolve_binary "$binary")"
  ln -s "$resolved" "$scratch/bin/$binary"
done

cm() {
  env -i HOME="$home" XDG_CONFIG_HOME="$home/.config" XDG_CONFIG_DIRS="$home/.config" \
    XDG_DATA_HOME="$home/.local/share" XDG_DATA_DIRS="$home/.local/share" \
    XDG_STATE_HOME="$home/.local/state" XDG_CACHE_HOME="$home/.cache" \
    PATH="$scratch/bin:/usr/bin:/bin" TMPDIR="$scratch" \
    UV_CACHE_DIR="$uv_cache" UV_PYTHON="$uv_python" UV_OFFLINE=true \
    "$scratch/bin/chezmoi" --source "$root" --destination "$home" \
    --config "$case_dir/config.toml" --persistent-state "$case_dir/state.db" \
    --cache "$case_dir/cache" --override-data-file "$case_dir/override.json" \
    --no-tty --no-pager --color=false --use-builtin-diff "$@"
}

seed_runtime() {
  mkdir -p "$home/.config/opencode" "$home/.config/phux" "$home/.config/phui" "$home/.claude" "$home/.pi/agent" "$home/.hermes"
  printf '%s\n' '{"scripts":{"mine":"keep"}}' > "$home/.config/opencode/package.json"
  printf '%s\n' '{"attention":{"volume":0.3},"tabs":{"mine":true}}' > "$home/.config/opencode/cli.json"
  printf '%s\n' '{"repoPaths":{"private/project":"~/private"},"editorCommand":"keep"}' > "$home/.config/phui/config.json"
  printf '%s\n' 'extends = ["local.toml"]' '[defaults]' 'session-name = "fixture"' '# native annotated defaults survive' > "$home/.config/phux/config.toml"
  printf '%s\n' '# local distro remains local' > "$home/.config/phux/local.toml"
  printf '%s\n' '{"hooks":{"runtime":true},"env":{"LOCAL":"keep"}}' > "$home/.claude/settings.json"
  printf '%s\n' '{"defaultModel":"keep","packages":["git:example/custom"],"runtime":{"keep":true}}' > "$home/.pi/agent/settings.json"
  printf '%s\n' 'model: local' 'unknown: keep' > "$home/.hermes/config.yaml"
}

assert_runtime() {
  jq -e '.scripts.mine == "keep"' "$home/.config/opencode/package.json" >/dev/null
  jq -e '.attention.volume == 0.3 and .tabs.mine and .tabs.scope == "cwd"' "$home/.config/opencode/cli.json" >/dev/null
  jq -e '.repoPaths["private/project"] == "~/private" and .editorCommand == "keep" and .repoPaths[":owner/:repo"] == "~/workspace/:repo"' "$home/.config/phui/config.json" >/dev/null
  yq -p=toml -o=json '.' "$home/.config/phux/config.toml" | jq -e '.extends == ["local.toml", "layers/dotfiles.toml"] and .defaults["session-name"] == "fixture"' >/dev/null
  grep -qx '# native annotated defaults survive' "$home/.config/phux/config.toml"
  jq -e '.hooks.runtime and .env.LOCAL == "keep"' "$home/.claude/settings.json" >/dev/null
  jq -e '.defaultModel == "keep" and .runtime.keep and (.packages | index("git:example/custom"))' "$home/.pi/agent/settings.json" >/dev/null
  yq -e '.model == "local" and .unknown == "keep"' "$home/.hermes/config.yaml" >/dev/null
  cm managed | grep -Eq '^(tests|scripts|provision|mise\.toml)' && { echo 'Source tooling leaked into HOME' >&2; return 1; }
  return 0
}

for target in darwin/arm64 linux/arm64 linux/amd64; do
  case_dir="$scratch/${target//\//-}"
  home="$case_dir/home"
  mkdir -p "$home" "$case_dir/cache"
  cat > "$case_dir/config.toml" <<EOF
[data]
harnesses = ["opencode", "pi", "claude", "hermes", "goose", "grok"]
services = false
[data.git]
name = "Fixture"
email = "fixture@example.invalid"
EOF
  jq -n --arg os "${target%/*}" --arg arch "${target#*/}" '{chezmoi:{os:$os,arch:$arch}}' > "$case_dir/override.json"
  seed_runtime
  cm apply --exclude scripts
  assert_runtime
  cm verify --exclude scripts
  [[ -z "$(cm diff --exclude scripts)" ]]
  cm apply --exclude scripts
  assert_runtime
  echo "PASS: $target preserves app state and converges twice"
  # Native history owns these live paths after enrollment. Both subsequent
  # applies must preserve edits and intentional deletions rather than reseeding.
  sed '/^\[data\]$/a\
history = true\
' "$case_dir/config.toml" > "$case_dir/enrolled.toml"
  mv "$case_dir/enrolled.toml" "$case_dir/config.toml"
  printf '\n# live-owned fixture edit\n' >> "$home/.zshrc"
  rm "$home/.config/lazygit/config.yml"
  cm apply --exclude scripts
  cm apply --exclude scripts
  grep -qx '# live-owned fixture edit' "$home/.zshrc"
  [[ ! -e "$home/.config/lazygit/config.yml" ]]
  cm managed > "$case_dir/managed.txt"
  if grep -Eq '^\.zshrc$|^\.config/nvim(/|$)|^\.agents/skills(/|$)' "$case_dir/managed.txt"; then
    echo 'Native history and chezmoi own overlapping paths' >&2; exit 1
  fi
  cm verify --exclude scripts
  echo "PASS: $target live edits and deletions survive repeated chezmoi apply"
done

# A core-only installation must not provision optional harnesses.
printf '%s\n' '[data]' 'harnesses = ["opencode"]' 'services = false' '[data.git]' 'name = "Fixture"' 'email = "fixture@example.invalid"' > "$case_dir/config.toml"
if cm managed | grep -Eq '^\.(pi|claude|hermes|grok)(/|$)|^\.config/goose'; then
  echo 'Optional harness leaked into core profile' >&2; exit 1
fi
echo 'PASS: optional harness selection'
[[ -f "$home/.config/opencode/skill/repo-onboarding/SKILL.md" ]]
[[ "$(printf '%s' 'malformed-json' | "$root/dot_pi/private_agent/modify_settings.json")" == malformed-json ]]
[[ "$(printf '%s' 'malformed-json' | "$root/dot_pi/private_agent/modify_private_models.json")" == malformed-json ]]
[[ "$(printf '%s' 'not: [valid' | "$root/dot_hermes/modify_private_config.yaml")" == 'not: [valid' ]]
echo 'PASS: shared skill resolves and malformed Pi state survives'
