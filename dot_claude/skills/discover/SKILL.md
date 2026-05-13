---
name: discover
description: Surface the current Claude Code feature surface and report what's new since the last invocation. Run when the user types `/discover` or asks about enabled hooks, MCP servers, experimental flags, skills, agents, or "what's new in my setup".
---

# `/discover` — Claude Code substrate inventory

Run `claude-discover` (lives at `~/.local/bin/claude-discover`, installed by chezmoi) and present the markdown it produces to the user verbatim. The script:

1. Snapshots the current Claude Code surface (`~/.claude/settings.json`, installed skills, agents, slash commands, plus any `CLAUDE_CODE_*` / `ANTHROPIC_*` env vars in the shell).
2. Diffs that against the last snapshot at `$XDG_STATE_HOME/dotfiles/claude/known-features.json` (or `~/.local/state/dotfiles/claude/known-features.json`).
3. Marks anything new with 🆕.
4. Persists the fresh snapshot for next time.

## How to invoke

```bash
claude-discover
```

If the binary isn't on PATH, point at `~/.local/bin/claude-discover` directly.

## After running

- If anything new appears (🆕 markers), surface it conversationally — don't bury it. The whole point is zero-friction discovery.
- If nothing is new, say so briefly. Don't pad.
- If the user asks "what does X do," give them a one-liner. Don't dump docs.
- Snapshot path: `$XDG_STATE_HOME/dotfiles/claude/known-features.json`. Reset it (`rm` the file) if the user wants a fresh delta baseline.

## What it covers

- `CLAUDE_CODE_*` and `ANTHROPIC_*` env vars (experimental feature gates, fast-mode toggles, 1M-context flags).
- `settings.json`: enabledPlugins, hooks, mcpServers, statusLine.
- Skills installed under `~/.claude/skills/`.
- Custom agents under `~/.claude/agents/`.
- Slash commands under `~/.claude/commands/` (if any).
- Claude Code version (`claude --version`).

## What it does NOT cover (yet)

- Claude Teams / org-level features. Surfaced via the CLI eventually; for now the user should check the Anthropic console.
- The Anthropic API changelog. A future iteration could fetch and diff that too (no cron — would have to be triggered manually).
