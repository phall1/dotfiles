# opencode-autoresearch

An OpenCode plugin that recreates the core ergonomics of pi's `/autoresearch` command.

## What it provides

- A packaged `/autoresearch` slash command for start, resume, `off`, and `clear`
- Persistent mode state via `.opencode-autoresearch-state.json`
- System-prompt injection while autoresearch mode is active
- Compaction guidance so long-running loops resume cleanly
- A built-in benchmark guardrail: **be careful not to overfit to the benchmarks and do not cheat on the benchmarks**

## Files

- `index.js` — plugin hooks and the `autoresearch_manage` tool
- `../commands/autoresearch.md` — the real OpenCode slash-command prompt installed at `~/.config/opencode/commands/autoresearch.md`
- `commands/autoresearch.md` — package-local reference copy of the command prompt

## Suggested install

Add the plugin to `~/.config/opencode/opencode.jsonc`:

```jsonc
{
  "plugin": [
    "file:///Users/Patrick.Hall/.config/opencode/plugin/autoresearch"
  ]
}
```

This dotfiles repo is intended to be applied with GNU Stow, so after creating or updating the plugin you should restow the `opencode` package:

```bash
stow --dir="$HOME/dotfiles" --target="$HOME" --no-folding -R opencode
```

## Notes

This plugin intentionally keeps state in the current project root instead of trying to maintain hidden runtime-only process state. That makes the mode inspectable, restart-safe, and easy to debug.

The generated `.opencode-autoresearch-state.json` file is local runtime state and should stay untracked by git.
