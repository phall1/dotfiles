# shellcheck shell=bash
# OpenCode V2 configuration.
#
# OpenCode migrates legacy key names when it loads a config (permission ->
# permissions, provider -> providers, attachment -> media), so asserting key
# names against the raw file on disk reports a working config as broken. Ask
# the runtime what it resolved instead: `opencode2 debug config` is the only
# authority on the effective shape.

hdr "opencode"

if ! command -v opencode2 >/dev/null 2>&1; then
  warn "opencode2 missing — run mise bootstrap"
  return 0
fi

for config in "$HOME/.config/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.json"; do
  [[ -f "$config" ]] || continue
  jq -e 'type == "object"' "$config" >/dev/null 2>&1 \
    || fail "${config/#$HOME/\~} does not parse as JSON"
done

if ! resolved="$(opencode2 debug config 2>/dev/null)"; then
  fail "OpenCode could not resolve its configuration — opencode2 debug config"
  return 0
fi

# Multiple config documents load in order and shadow each other silently. One
# document is the intended shape; a second is usually a leftover.
documents="$(jq -r '[.[] | select(.type == "document")] | length' <<< "$resolved")"
if [[ "$documents" -le 1 ]]; then
  ok "single OpenCode config document"
else
  warn "$documents OpenCode config documents load and shadow each other: $(jq -r '[.[] | select(.type == "document") | .path | sub("^" + env.HOME; "~")] | join(", ")' <<< "$resolved")"
fi

if jq -e '[.[] | select(.type == "document") | .info] | add
          | (.permissions != null) and (.plugins != null) and (.mcp != null)' <<< "$resolved" >/dev/null 2>&1; then
  ok "resolved config carries native V2 permissions, plugins and MCP"
else
  fail "resolved OpenCode config is missing native V2 permissions/plugins/MCP"
fi

if services_enabled; then
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
  [[ -e "$path" || -L "$path" ]] && obsolete+=" ${path/#$HOME/\~}"
done

if [[ -z "$obsolete" ]]; then
  ok "legacy OpenCode and OpenAgent launchers absent"
else
  fail "legacy OpenCode/OpenAgent paths remain:$obsolete"
fi
