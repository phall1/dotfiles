# Pi agent stack

The portable global stack is managed here and installed with
`scripts/install-agent-stack.sh`.

Runtime-only follow-ups are intentionally not tracked:

- authenticate model providers with Pi on each machine;
- configure optional web provider keys in `~/.pi/web-search.json`;
- keep Blackbird registration tokens, cursors, sessions, and database state local;
- use an OS/container sandbox when isolation is required (Pi tool allowlists are capability controls, not process sandboxes).

Run `dot-doctor` after `chezmoi apply`; use `pi list` and the `subagent` doctor action for deeper package diagnostics.

## Release blocker

Blackbird v0.1.3 omits the root `type: object` on composite MCP output schemas,
so pi-mcp-adapter 2.23.0 rejects its tools/list response. The minimal upstream
fix (`semanticOutputSchema.Type = "object"`) and a tools/list regression
assertion were tested against the v0.1.3 source: focused Go tests pass and Pi
directly called `blackbird_agent_register` against an isolated patched server. Keep the
portable v0.1.3 pin until a fixed Blackbird release is published and approved;
do not add a protocol proxy or patch npm internals.
