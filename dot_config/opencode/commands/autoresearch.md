---
description: Start, stop, clear, or resume autoresearch mode
---

Interpret `$ARGUMENTS` like pi's `/autoresearch` command.

## Behavior

- If `$ARGUMENTS` is empty, explain usage:
  - `/autoresearch <goal>` — start or resume autoresearch
  - `/autoresearch off` — turn autoresearch mode off without deleting history
  - `/autoresearch clear` — delete `autoresearch.jsonl` and clear mode state
- If `$ARGUMENTS` is `off`:
  1. Prefer calling the `autoresearch_manage` tool with `action: "off"`.
  2. If the tool is unavailable, update `.opencode-autoresearch-state.json` so `active` is `false`.
  3. Confirm that autoresearch mode is off and stop.
- If `$ARGUMENTS` is `clear`:
  1. Prefer calling the `autoresearch_manage` tool with `action: "clear"`.
  2. If the tool is unavailable, delete `autoresearch.jsonl` if it exists and remove `.opencode-autoresearch-state.json`.
  3. Confirm what was cleared and stop.
- Otherwise this is a start/resume request:
  1. Prefer calling the `autoresearch_manage` tool with `action: "start"` and `goal: "$ARGUMENTS"`.
  2. If the tool is unavailable, write `.opencode-autoresearch-state.json` with `active: true`, the goal text, and the benchmark guardrail.
  3. If `autoresearch.md` already exists, resume the loop by reading it and continuing immediately.
  4. If `autoresearch.md` does not exist, set up a new autoresearch session:
     - infer or clarify the goal, benchmark command, metric, files in scope, and constraints
     - create `autoresearch.md`
     - create `autoresearch.sh`
     - create `autoresearch.checks.sh` when correctness checks are required
     - run the baseline
     - continue the loop autonomously

## Hard rule

Be careful not to overfit to the benchmarks and do not cheat on the benchmarks.
