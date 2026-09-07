#!/usr/bin/env bash
# OpenCode V2-only configuration and direct OpenAI model exposure.

hdr "opencode"

config="$HOME/.config/opencode/opencode.jsonc"

if [[ -f "$config" ]] && jq -e '
  .permissions
  and .mcp.servers
  and (.update == "auto")
  and .plugins
  and (has("permission") | not)
  and (has("provider") | not)
  and (has("plugin") | not)
' "$config" >/dev/null 2>&1; then
  ok "native V2 config with automatic updates"
else
  fail "OpenCode config is missing native V2 shape or automatic updates"
fi

if services_enabled && command -v opencode2 >/dev/null 2>&1; then
  if ! opencode_models="$(opencode2 models 2>/dev/null)"; then
    fail "OpenCode could not enumerate its model catalog"
  elif grep -qx 'openai/gpt-6-astra' <<< "$opencode_models"; then
    ok "OpenAI GPT-6 Astra is selectable"
  elif [[ -n "${OPENAI_API_KEY:-}" ]] || jq -e 'has("openai")' "${XDG_DATA_HOME:-$HOME/.local/share}/opencode/auth.json" >/dev/null 2>&1; then
    fail "OpenAI GPT-6 Astra is absent from the runtime model catalog"
  else
    ok "OpenAI is not connected yet — use /connect to enable its model catalog"
  fi
fi

obsolete=''
for path in \
  "$HOME/.config/oc" \
  "$HOME/.local/bin/opencode-ohmy" \
  "$HOME/.local/bin/opencode-safe"
do
  [[ -e "$path" || -L "$path" ]] && obsolete+=" ${path/#$HOME/~}"
done

if [[ -z "$obsolete" ]]; then
  ok "legacy OpenCode and OpenAgent launchers absent"
else
  fail "legacy OpenCode/OpenAgent paths remain:$obsolete"
fi
