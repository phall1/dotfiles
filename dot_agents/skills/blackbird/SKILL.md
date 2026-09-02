---
name: blackbird
description: Coordinate durable multi-agent work, mail, handoffs, and path reservations through Blackbird.
---

# Blackbird coordination

Use Blackbird as the single durable coordination authority when its MCP tools
are available. It is shared memory for every agent working in one repository:
who is here, who holds which paths, and what the last agent left behind.

## The loop

1. **Register once per session.** `blackbird_agent_register` with `project_key`
   set to the repository's absolute path and a stable name for yourself. It
   provisions everything else itself on a path it has not seen before, so this
   is the only setup call there is.
2. **Keep the token.** Registration returns `registration_token`; every other
   tool takes that same string as `agent_token` — one value, two field names.
   Pass it back as `registration_token` to resume the same identity after a
   restart. Keep it in runtime state, never in the repository.
3. **Reserve before editing.** Acquire `exclusive` for writes and `shared` for
   reads, naming the narrowest selector that covers the change: `exact` for a
   single file, `subtree` only when the change genuinely spans a package. Hold
   the returned lease ID and fences.
4. **Renew long work** with the lease ID and the *current* fences; **release**
   when done rather than letting a lease expire, because an expiring lease
   blocks every other agent for its whole remaining TTL.
5. **One conversation per work item.** Open a conversation, then send and reply
   within it. Read the inbox and the thread before acting on a handoff.
6. **Acknowledge only your own obligations.** Read and acknowledgement facts
   belong to the recipient; never mark or acknowledge on another agent's behalf.

## On conflict

A lease conflict means another agent holds an overlapping lease. Do not retry
blindly and do not widen your selector — coordinate through a conversation, or
narrow your scope to a disjoint path. The conflict reports who holds the lease
and how long it has left; act on that rather than guessing.

## Scope

The available surface is registration, peer discovery, reservations,
conversations, and mail. There is no objective, work-unit, or run surface — use
harness-local delegation for ephemeral child execution, and your own tracker
for durable work items.

Never place registration tokens, cursors, session bindings, or Blackbird
database state in a repository. If Blackbird is unavailable, continue safe
local work and report that durable coordination was unavailable; do not invent
a competing mailbox protocol.
