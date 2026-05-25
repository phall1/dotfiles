# IDEAS

Half-baked. Not commitments. Things worth revisiting.

---

## Native agent-first diff-review TUI

**Date:** 2026-05-25

The pane that's missing in an agent-driven workflow is a fast, native,
agent-aware diff stream. `hunk` (modem-dev/hunk) has the right shape but the
wrong substrate — TypeScript on OpenTUI, every keystroke bounces through V8,
feels laggy at scale. The right version would be:

- **Native runtime.** Rust or Zig. Ratatui-level rendering. Sub-frame reload
  on file events. No GC pauses while an agent is hammering writes.
- **jj-native, not git-retrofitted.** Agents produce stacks of small changes;
  jj's data model treats that as the unit, git treats it as awkward. "Show me
  the agent's stack across these revsets" is much cleaner over jj.
- **MCP baked in, not a skill loaded as text.** Real bidirectional wire
  protocol — agent annotations as first-class messages, reply inline without
  leaving the diff. Hunk's skill is a clever retrofit; the real version is
  protocol-native.
- **$EDITOR-embedded for deep dives.** Don't try to be an editor. Shell out
  to nvim/helix/zed in a split when the diff isn't enough. The editor is the
  surgical tool, not the cockpit.
- **The diff stream as a first-class object.** Replayable, threadable,
  sharable. "Here's what the agent did in this session" should be one
  artifact, not something reconstructed from git log after the fact.

**Why this doesn't exist yet:** The shape only became obvious in the last
~12 months as Claude Code / MCP stabilized. Not enough lead time for someone
to ship a serious native TUI. Closest existing pieces:

- **Zed** — Rust + GPU, agent threads as a primary pane, but still
  editor-shaped.
- **Sapling ISL** — right data model, but web UI.
- **jj-aware TUI experiments** — none have merged the agent piece yet.

**Underlying architectural point:** Vim is structured around "you are the
author, here's a buffer to type in." Agent-native review wants "an agent is
the author, here's a review stream and a back-channel." Those want different
chrome. The current nvim setup is fine for the editor-as-surgical-tool role
in that future; the missing pane is the cockpit, and no one has built it.

**Concrete watch list:**
- Anything new with `jj` + Rust + TUI in the ecosystem
- Whether Zed's agent panel evolves into a standalone review surface
- Whether Anthropic ships a non-VS-Code reference review UI
- `hunk` rewrites (it'd be the canonical reference if anyone forks it native)

**If I ever build this:** start with jj + ratatui + a thin MCP client. First
milestone is `hunk diff --watch` parity but native. Second is inline agent
annotations over MCP, not file-based skill. Third is embedding $EDITOR.
