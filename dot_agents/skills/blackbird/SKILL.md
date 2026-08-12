---
name: blackbird
description: Coordinate durable multi-agent work, mail, handoffs, and path reservations through Blackbird.
---

# Blackbird coordination

Use Blackbird as the single durable coordination authority when its MCP tools are available.

1. Start or resume a session for the absolute repository path; keep returned tokens in runtime state only.
2. Discover peers before addressing work. Use one conversation per work item.
3. Send concise messages with decisions, evidence, blockers, and exact requested action. Reply in-thread.
4. Fetch the inbox and thread before acting on a handoff. Mark read and acknowledge only after the stated obligation is understood or completed.
5. Before parallel edits, reserve the narrowest paths possible. Renew long work and always release reservations at completion.
6. Use Blackbird objectives/work/runs for durable multi-session missions; use harness-local delegation for ephemeral child execution.

Never place registration tokens, cursors, session bindings, or Blackbird database state in a repository. If Blackbird is unavailable, continue safe local work and report that durable coordination was unavailable; do not invent a competing mailbox protocol.
