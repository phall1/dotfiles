# Pi agent stack

The portable global stack is managed here and installed with
`scripts/install-agent-stack.sh`.

Runtime-only follow-ups are intentionally not tracked:

- authenticate model providers with Pi on each machine;
- configure optional web provider keys in `~/.pi/web-search.json`;
- keep Blackbird registration tokens, cursors, sessions, and database state local;
- use an OS/container sandbox when isolation is required (Pi tool allowlists are capability controls, not process sandboxes).

Run `dot-doctor` after `chezmoi apply`; use `pi list` and the `subagent` doctor action for deeper package diagnostics.

## Resolved compatibility note

Blackbird v0.1.4 fixed the composite MCP output-schema root type and added the
regression assertion proven during the original integration. The portable stack
now pins v0.2.0, including the first-class Pi companion. No local proxy or npm
adapter patch is required.
