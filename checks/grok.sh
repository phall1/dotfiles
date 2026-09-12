# shellcheck shell=bash
# Grok Build. config.toml is reconciled by a modify_ script: Grok writes
# installer metadata, marketplaces, and BYOK providers live, so chezmoi
# merges portable managed keys and leaves everything else alone.

harness_enabled grok || return 0
hdr "grok"

config="$HOME/.grok/config.toml"
template="$DOTFILES/.chezmoitemplates/grok.toml"

if [[ ! -f "$config" ]]; then
  warn "~/.grok/config.toml missing — run 'chezmoi apply'"
elif ! yq -p=toml -o=json '.' "$config" >/dev/null 2>&1; then
  fail "~/.grok/config.toml does not parse as TOML"
else
  ok "config.toml parses"
fi

if [[ ! -f "$template" ]]; then
  fail ".chezmoitemplates/grok.toml missing"
elif [[ -f "$config" ]]; then
  live_json="$(yq -p=toml -o=json '.' "$config" 2>/dev/null || echo '{}')"
  want_json="$(yq -p=toml -o=json '.' "$template" 2>/dev/null || echo '{}')"
  if jq -n -e --argjson live "$live_json" --argjson want "$want_json" '
    def get($o; $p): $o | getpath($p);
    [
      ["ui","permission_mode"],
      ["ui","theme"],
      ["ui","status_line","type"],
      ["models","default"],
      ["models","default_reasoning_effort"],
      ["features","lsp_tools"],
      ["features","web_fetch"],
      ["features","telemetry"],
      ["memory_v2","enabled"],
      ["mcp_servers","blackbird","url"],
      ["mcp_servers","linear-server","url"]
    ] as $paths
    | all($paths[]; get($live; .) == get($want; .))
  ' >/dev/null 2>&1; then
    ok "managed grok keys are applied"
  else
    warn "managed grok keys diverge — run 'chezmoi apply'"
  fi
fi

statusline="$HOME/.grok/statusline.sh"
if [[ -x "$statusline" ]]; then
  mock='{"model":{"display_name":"Grok 4.6"},"workspace":{"current_dir":"/tmp"},"context_window":{"remaining_percentage":72}}'
  out="$(printf '%s' "$mock" | "$statusline" 2>/dev/null || true)"
  if [[ "$out" == *Grok* && "$out" == *72%* ]]; then
    ok "statusline.sh renders"
  else
    fail "statusline.sh did not render the mock line"
  fi
else
  warn "~/.grok/statusline.sh missing or not executable — run 'chezmoi apply'"
fi

if [[ -f "$HOME/.grok/lsp.json" ]] && jq -e '.["rust-analyzer"].command == "rust-analyzer"' "$HOME/.grok/lsp.json" >/dev/null 2>&1; then
  ok "lsp.json has rust-analyzer"
else
  warn "~/.grok/lsp.json missing rust-analyzer — run 'chezmoi apply'"
fi

if [[ -f "$HOME/.grok/pager.toml" ]]; then
  ok "pager.toml present"
else
  warn "~/.grok/pager.toml missing — run 'chezmoi apply'"
fi

if [[ -f "$HOME/.grok/rules/working-agreement.md" ]]; then
  ok "working-agreement rule is applied"
else
  warn "~/.grok/rules/working-agreement.md missing — run 'chezmoi apply'"
fi
