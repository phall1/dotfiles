hdr "blackbird"
if ! command -v blackbird >/dev/null; then
  fail "Blackbird missing — run mise bootstrap"
  return 0
fi
config="$HOME/.config/opencode/opencode.jsonc"
if jq -e '.mcp.servers.blackbird.url == "http://127.0.0.1:8081" and any(.plugins[]; type == "object" and .package == "blackbird-opencode@0.1.3" and .options.baseUrl == "http://127.0.0.1:8080" and (.options | has("token") | not))' "$config" >/dev/null; then
  ok "MCP and push-delivery connections configured without literal credentials"
else
  fail "Blackbird V2 integration invalid"
fi
if services_enabled; then
  if blackbird doctor >/dev/null 2>&1; then ok "native doctor healthy"
  else fail "Blackbird service needs attention — blackbird doctor"; fi
else
  ok "service lifecycle disabled by this machine profile"
fi
