# Perf baselines

Pinned numbers for `dot-bench` to gate against. Update only with justification
in the commit message ("baseline rewritten because <reason>").

`dot-bench` exits nonzero if any pinned key regresses >10%.

## Targets

| Metric | Target | Why |
|---|---|---|
| `first_prompt_lag_ms` | < 5 (Mac), < 30 (Pi) | P10k instant-prompt should make first prompt near-free. |
| `command_lag_ms` | < 5 | Time between Enter and next prompt for `echo hi`. Anything higher means hooks are heavy. |
| `prompt_redraw_lag_ms` | < 10 | gitstatusd should keep this constant regardless of repo size. |

## Pinned baseline

Format: `key: value_ms` — `dot-bench` greps for this.

<!-- BASELINE_START -->
first_prompt_lag_ms: 50
first_command_lag_ms: 200
command_lag_ms: 25
input_lag_ms: 10
<!-- BASELINE_END -->

## How to re-pin

```sh
dot-bench               # see current numbers
$EDITOR zsh/PERF.md     # update the values, explain in commit
git commit -m "perf(zsh): re-pin baseline after <change> — was X, now Y"
```

## Known floor: `first_command_lag_ms`

Pinned at 200, measures ~284. The baseline is deliberately left unmoved so it
keeps showing up rather than being papered over. Full profile 2026-07-26, via
an xtrace through the first prompt inside a pty (`zsh -c exit` exits before any
prompt renders, so it under-reports by ~250 ms and is useless here):

| Component | ms | Notes |
|---|---|---|
| deferred plugin load (`_zsh-defer-apply`) | ~113 | runs before the first command can execute |
| gitstatus daemon handshake (`sysread`) | ~37 | one-time per shell |
| p10k `_p9k_init_*` | ~40 | spread over ssh/params/cacheable |
| everything else | remainder | forks, /etc/zshrc, compinit |

What was ruled out, with evidence — don't re-chase these:

- **Not gitstatus being slow.** `POWERLEVEL9K_DISABLE_GITSTATUS=true` makes it
  *worse* (414 ms): p10k falls back to forking `git`. Benching outside a repo
  (`zsh-bench --git no`) saves only ~17 ms.
- **Not a stale gitstatusd.** The cached binary is v1.5.4, exactly what
  `gitstatus/install.info` pins for darwin-arm64. Its 2022 file date is the
  upstream release date.
- **Not a thrashing p10k cache.** `~/.cache/p10k-dump-*` is reused across
  starts (verified by mtime across three consecutive shells).
- **Byte-compiling the plugins does nothing.** Compiling f-sy-h,
  zsh-autosuggestions, fzf-tab and zsh-defer to `.zwc` moved the number by
  0.1 ms (272.5 vs 272.6). Not worth the untracked cruft in pinned plugin
  repos, so `dot-zcompile` deliberately does not do it.
- **Removing p10k** drops it to ~92 ms, but costs the git prompt and makes
  `first_prompt_lag` *worse* (64 ms vs 17 ms) — instant prompt is a net win.

Instant prompt makes this metric read worse than it feels: the prompt is
interactive at ~17 ms, and typed input is buffered and replayed.
`command_lag_ms` is the metric that tracks per-command feel.

Do not "fix" this by lowering the pin. Either reduce p10k's init or accept it.

### `has_autosuggestions=0` in zsh-bench output is expected

zsh-bench types its probe command at t=0, before zsh-defer has flushed its
queue, so it cannot see a deferred plugin. zsh-autosuggestions *is* loaded in a
real shell (verified in a pty: 101 `*autosuggest*` functions). Do not "fix"
this by making it eager.

`has_syntax_highlighting=0`, by contrast, was a real bug — see below.

## fast-syntax-highlighting must be loaded eagerly

f-sy-h does not survive `zsh-defer`. Deferred, it silently never loads:
`fast-theme` and `-fast-highlight-process` undefined, `FAST_HIGHLIGHT` empty,
`FAST_WORK_DIR` unset, and zsh-bench reporting `has_syntax_highlighting=0`.
Reproduced against a minimal zshrc containing nothing but zsh-defer and the
plugin, so it is not an interaction with anything else in this config:

```
zsh-defer source .../fast-syntax-highlighting.plugin.zsh   -> fast-theme absent
source           .../fast-syntax-highlighting.plugin.zsh   -> fast-theme present
```

It costs ~21 ms eagerly. zsh-autosuggestions defers fine and is loaded after
the highlighter, which is the order upstream recommends.

## How to investigate regression

```sh
ZSH_PROF=1 zsh -i -c exit | head -30   # which functions are hot
zsh -xv 2>&1 | head -100                # what's being sourced
dot-bench                                # repeat to confirm
```

Per-prompt cost (what drives `command_lag_ms`) is best found by timing prompt
segment functions directly — custom `prompt_*` segments in `.p10k.zsh` run on
every prompt, and a single `$(...)` in one is a fork per prompt:

```sh
zsh -l -i -c 'zmodload zsh/datetime
  s=$EPOCHREALTIME; for i in {1..20}; do prompt_<segment> >/dev/null 2>&1; done
  printf "%.3f ms/prompt\n" "$(( ($EPOCHREALTIME-s)*50 ))"'
```
