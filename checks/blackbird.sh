# Blackbird durable coordination. Assertions target what the runtime resolved,
# not one hand-picked spelling of the config: OpenCode accepts MCP servers both
# at .mcp.<name> and .mcp.servers.<name>, and a check that hardcodes one of them
# reports a healthy daemon as broken.
hdr "blackbird"
if ! command -v blackbird >/dev/null; then
  fail "Blackbird missing — run mise bootstrap"
  return 0
fi

if ! command -v opencode2 >/dev/null 2>&1; then
  warn "OpenCode absent — Blackbird delivery integration unverified"
elif ! mcp_list="$(opencode2 mcp list 2>/dev/null)"; then
  fail "OpenCode could not enumerate MCP servers"
elif grep -qE '^\s*✓\s+blackbird\b' <<< "$mcp_list"; then
  ok "Blackbird MCP endpoint connected"
elif grep -qE '^\s*[⚠○]\s+blackbird\b' <<< "$mcp_list"; then
  fail "Blackbird MCP server is registered but not connected — blackbird doctor"
else
  fail "Blackbird MCP server is not registered with OpenCode"
fi

# The push-delivery plugin must load and must not carry a literal credential.
if command -v opencode2 >/dev/null 2>&1; then
  if opencode2 plugin list 2>/dev/null | grep -qE '^\S*blackbird\s'; then
    ok "Blackbird push-delivery plugin loaded"
  else
    fail "Blackbird OpenCode plugin is not loaded — opencode2 plugin list"
  fi
fi

bb_credential_leak=0
for config in "$HOME/.config/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.json"; do
  [[ -f "$config" ]] || continue
  if ! jq -e '[(.plugins // [])[] | select(type == "object" and (.package // "" | startswith("blackbird-opencode"))) | .options // {}] | all(has("token") | not)' "$config" >/dev/null 2>&1; then
    fail "Blackbird plugin options carry a literal token in ${config/#$HOME/\~} — use the credential store"
    bb_credential_leak=1
  fi
done
(( bb_credential_leak )) || ok "no literal Blackbird credentials in OpenCode config"

if services_enabled; then
  if blackbird doctor >/dev/null 2>&1; then ok "native doctor healthy"
  else fail "Blackbird service needs attention — blackbird doctor"; fi
else
  ok "service lifecycle disabled by this machine profile"
fi
