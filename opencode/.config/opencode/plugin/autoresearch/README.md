# opencode-autoresearch

An OpenCode plugin that recreates the core ergonomics of pi's `/autoresearch` command.

## What it provides

- A packaged `/autoresearch` slash command for start, resume, `off`, and `clear`
- Persistent mode state via `.opencode-autoresearch-state.json`
- System-prompt injection while autoresearch mode is active
- Compaction guidance so long-running loops resume cleanly
- A built-in benchmark guardrail: **be careful not to overfit to the benchmarks and do not cheat on the benchmarks**

## Files

- `index.js` — plugin hooks
- `commands/autoresearch.md` — slash command prompt template

## Suggested install

Add the plugin to `~/.config/opencode/opencode.jsonc`:

```jsonc
{
  "plugin": [
    "file:///Users/Patrick.Hall/.config/opencode/plugin/autoresearch"
  ]
}
```

## Notes

This plugin intentionally keeps state in the current project root instead of trying to maintain hidden runtime-only process state. That makes the mode inspectable, restart-safe, and easy to debug.
