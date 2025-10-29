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

## How to investigate regression

```sh
ZSH_PROF=1 zsh -i -c exit | head -30   # which functions are hot
zsh -xv 2>&1 | head -100                # what's being sourced
dot-bench                                # repeat to confirm
```
