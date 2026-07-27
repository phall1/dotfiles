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

This metric is pinned at 200 and currently measures ~280. The gap is **p10k's
own init**, not our config, and the baseline is deliberately left unmoved so it
keeps showing up rather than being papered over. Measured 2026-07-26:

- Commenting out p10k entirely drops it 326 -> 92 ms. Everything else in
  `.zshrc` combined accounts for well under 100 ms.
- It is not gitstatus: `POWERLEVEL9K_DISABLE_GITSTATUS=true` makes it *worse*
  (414 ms) because p10k falls back to forking `git`. Benching outside a repo
  (`zsh-bench --git no`) only saves ~17 ms.
- The cached `gitstatusd` is v1.5.4, exactly the version `gitstatus/install.info`
  pins for darwin-arm64. Its 2022 file date is the upstream release date, not
  staleness.
- p10k's `~/.cache/p10k-dump-*` is correctly reused across starts (verified by
  mtime); it is not regenerating on every shell.

Note that instant prompt makes this metric read worse than it feels: the prompt
is interactive at ~38 ms (`first_prompt_lag_ms`), and typed input is buffered
and replayed. `command_lag_ms` is the metric that tracks per-command feel.

Do not "fix" this by lowering the pin. Either reduce p10k's init or accept it.

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
