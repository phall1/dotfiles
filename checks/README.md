# checks/ — the doctor's plugin directory

The doctor is intentionally dumb. Health signal comes from files, not from code
inside `dot-doctor`. This keeps the substrate a **living organism**: adding a
new concern is a one-file change, not a refactor of the orchestrator.

## Adding a check

Drop a `*.sh` file here for global checks, or `dot-checks.sh` inside any
package directory (`zsh/`, `claude/`, etc.) for package-local checks.

Available helpers (exported by `dot-doctor` before sourcing):

| helper | use |
|---|---|
| `hdr "section"` | print a section header |
| `ok "msg"` | green check, no count |
| `warn "msg"` | yellow, increments warn count, exit 1 |
| `fail "msg"` | red, increments fail count, exit 2 |
| `require_bin foo "hint"` | fail if `foo` not on PATH |
| `want_bin foo "hint"` | warn if `foo` not on PATH |
| `file_age_h /path` | hours since file mtime (returns nonzero if missing) |

Variables available: `$DOTFILES`, `$STATE_DIR`, `$HOME`.

## Running

```sh
dot-doctor              # run everything
dot-doctor --list       # list discovered checks
DOT_SKIP=zsh,claude dot-doctor   # skip by package name or filename stem
```

## Discovery order

1. `$DOTFILES/checks/*.sh` (sorted — use `00-`, `10-`, `20-` prefixes for order)
2. `$DOTFILES/<pkg>/dot-checks.sh` (sorted by package name)

Disabled checks still print a `(skipped)` header so it's visible they exist
but weren't run. Silence is never a signal.

## Philosophy

- **Every check is data-driven.** Tweaking the `.zshenv` line limit is one var
  edit, not a code edit. Tools are listed, not coded.
- **Checks colocate with what they check.** `zsh/dot-checks.sh` lives next to
  the zsh package. Moving the package moves its checks.
- **The orchestrator never grows.** New concerns add files. If you find yourself
  editing `dot-doctor`, you're probably wrong.
