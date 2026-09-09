# Pi agent-stack checks. Runtime-owned state is inspected, never reconciled here.

harness_enabled pi || return 0
hdr "pi agent stack"

pi_settings="$HOME/.pi/agent/settings.json"
pi_modify="$DOTFILES/dot_pi/private_agent/modify_settings.json"
subagent_config="$HOME/.pi/agent/extensions/subagent/config.json"
goal_config="$HOME/.pi/agent/pi-goal.json"
module_bridge="$HOME/.pi/agent/node_modules"
mcp_config="$HOME/.config/mcp/mcp.json"

# The managed package pins are declared in modify_settings.json. Restating them
# here made this check a lockstep-edit detector: it could only ever catch "you
# edited one file and not the other", never real drift. Derive them instead --
# and the retired-package assertion below derives its own name the same way.
managed_packages="$(sed -n "/^managed_packages='/,/^]'$/p" "$pi_modify" | sed "s/^managed_packages='//; s/^]'$/]/")"
if ! jq -e 'type == "array"' <<< "$managed_packages" >/dev/null 2>&1; then
  fail "cannot read managed_packages from dot_pi/private_agent/modify_settings.json"
  return 0
fi
npm_pins="$(jq -r '[.[] | select(startswith("npm:"))]' <<< "$managed_packages")"
retired_packages="$(sed -n "/^retired_packages='/,/^]'$/p" "$pi_modify" | sed "s/^retired_packages='//; s/^]'$/]/")"
jq -e 'type == "array"' <<< "$retired_packages" >/dev/null 2>&1 || retired_packages='[]'

if command -v pi >/dev/null 2>&1; then
  version="$(pi --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  pi_pin="$(yq -p=toml -o=json -r '.tools."npm:@earendil-works/pi-coding-agent"' "$DOTFILES/mise.pi.toml")"
  if [[ -n "$pi_pin" && "$version" == "$pi_pin" ]]; then
    ok "Pi matches the installer pin ($version)"
  else
    warn "Pi is ${version:-unknown}; mise.pi.toml pins ${pi_pin:-unknown}"
  fi
fi

if command -v node >/dev/null 2>&1 && node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit(major > 22 || (major === 22 && minor >= 19) ? 0 : 1)' >/dev/null 2>&1; then
  ok "Node satisfies Pi runtime floor ($(node --version))"
else
  fail "Pi 0.84.x requires Node >=22.19.0"
fi

if [[ -f "$pi_settings" ]] && jq -e 'type == "object"' "$pi_settings" >/dev/null 2>&1; then
  ok "settings.json parses"
  [[ "$(jq -r '.defaultProjectTrust // empty' "$pi_settings")" == always ]] && ok "project trust defaults to always" || fail "defaultProjectTrust is not always"
  missing="$(jq -r --argjson pins "$npm_pins" '$pins - (.packages // []) | .[]' "$pi_settings")"
  [[ -z "$missing" ]] && ok "portable Pi package pins present" || fail "missing managed Pi package pin(s): ${missing//$'\n'/, }"
  still_present="$(jq -r --argjson retired "$retired_packages" '
    [(.packages // [])[] | if type == "object" then .source else . end | select(type == "string")] as $configured
    | [$retired[] | select(. as $name | $configured | map(contains($name)) | any)] | .[]' "$pi_settings")"
  if [[ -z "$still_present" ]]; then
    ok "retired packages absent"
  else
    fail "retired package(s) still configured: ${still_present//$'\n'/, }"
  fi
else
  fail "~/.pi/agent/settings.json missing or invalid"
fi

if [[ -x "$pi_modify" ]]; then
  # Feed it a stale pin, a retired package and an unmanaged entry, then assert
  # the contract: runtime keys survive, every managed pin lands, retired names go.
  synthetic="$(jq -nc --argjson retired "$retired_packages" '{
    defaultProvider: "local", defaultModel: "keep-me", defaultThinkingLevel: "low",
    runtime: {token: "keep"},
    packages: (["npm:pi-subagents@old", "git:example/tool"] + [$retired[] | "npm:" + . + "@1.0.0"])
  }')"
  roundtrip="$(printf '%s' "$synthetic" | "$pi_modify" 2>/dev/null)"
  if jq -e --argjson pins "$npm_pins" --argjson retired "$retired_packages" '
      [(.packages // [])[] | if type == "object" then .source else . end | select(type == "string")] as $out
      | .defaultProvider == "local" and .defaultModel == "keep-me"
      and .defaultThinkingLevel == "low" and .runtime.token == "keep"
      and ($out | index("git:example/tool"))
      and (($pins - $out) | length == 0)
      and ([$retired[] | select(. as $n | $out | map(contains($n)) | any)] | length == 0)
      and .subagents.watchdog.enabled == true and .subagents.watchdog.main.enabled == true
      and .defaultProjectTrust == "always"' <<<"$roundtrip" >/dev/null 2>&1; then
    ok "modify_settings preserves runtime keys and enforces managed values"
  else
    fail "modify_settings semantic roundtrip failed"
  fi
else
  fail "Pi modify_settings source is not executable"
fi

if [[ -L "$module_bridge" ]] && [[ "$(readlink "$module_bridge")" == "npm/node_modules" ]]; then
  ok "Pi extension module bridge"
else
  fail "~/.pi/agent/node_modules must link to npm/node_modules"
fi

if [[ -f "$subagent_config" ]] && jq -e '.artifactDir=="session" and .maxSubagentDepth==4 and .maxSubagentSpawnsPerSession==0 and .asyncByDefault==true and .intercomBridge.mode=="always"' "$subagent_config" >/dev/null 2>&1; then
  ok "subagent artifacts, delegation, and coordination configured"
else
  fail "subagent config missing or inconsistent"
fi

if [[ -f "$pi_settings" ]] && jq -e '.subagents.watchdog.enabled==true and .subagents.watchdog.main.enabled==true and .subagents.watchdog.children.enabled==false and .subagents.watchdog.autoFollow.blockers==true and .subagents.watchdog.autoFollow.maxAttempts==2 and .subagents.watchdog.autoFollow.stalemateRepeats==2' "$pi_settings" >/dev/null 2>&1; then
  ok "main-session adversarial watchdog configured"
else
  fail "subagent watchdog config missing or inconsistent"
fi

if [[ -f "$goal_config" ]] && jq -e '.toolVisibility=="always" and .experimental.goals==true and .rpc.enabled==false and .continuationLimits.automaticTurns==100 and .continuationLimits.noProgressTurns==3' "$goal_config" >/dev/null 2>&1; then
  ok "autonomous goal continuation configured"
else
  fail "pi-goal config missing or inconsistent"
fi

if [[ -f "$mcp_config" ]] && jq -e '.mcpServers.blackbird.url=="http://127.0.0.1:8081" and .mcpServers.blackbird.directTools==true and .mcpServers.blackbird.toolPrefix=="none"' "$mcp_config" >/dev/null 2>&1; then
  ok "shared Blackbird MCP endpoint configured"
else
  fail "shared Blackbird MCP config missing or inconsistent"
fi

if [[ -d "$HOME/.pi/agent/npm/node_modules" ]]; then
  while IFS= read -r spec; do
    pkg="${spec%@*}"; expected="${spec##*@}"; manifest="$HOME/.pi/agent/npm/node_modules/$pkg/package.json"
    if [[ ! -f "$manifest" ]]; then warn "$pkg not installed yet"
    elif [[ "$(jq -r .version "$manifest")" == "$expected" ]]; then ok "$pkg@$expected installed"
    else warn "$pkg installed version differs from $expected"
    fi
  done < <(jq -r '.[] | sub("^npm:"; "")' <<< "$npm_pins")
fi
