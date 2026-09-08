# Native history migration evidence — 2026-09-08

## Scope and executed checks

- Official mise 2026.9.3 macOS arm64 archive verified against its published
  `SHASUMS256.txt` before use. Linux fresh installation uses the same release.
- `mise run check` passed: all three platform fixtures preserve application
  runtime fields and preexisting preferences on first apply; missing preferences
  receive seeds. Live-owned edits/deletions survive two later chezmoi applies.
- `tests/bootstrap/history_test.py` passed with real native mise commands:
  autosave after atomic file replacement, rollback/undo, fresh adoption, two-home
  exchange, conflict resolution, deletion, and consistent watcher directories.
- A real zsh regression compiles startup files and a module, deletes their source,
  and verifies that bytecode cleanup prevents deleted configuration from running.
- The final Linux arm64 `container,pi` run passed real installation, history
  enrollment, repeat convergence, native application checks and history tests.
- Native [CI run 34253606391](https://github.com/phall1/dotfiles/actions/runs/34253606391)
  passed amd64 and arm64/Pi container acceptance plus macOS/Linux configuration
  and history tests at `6bb2056`. Dependency validation passed separately.
- Independent source review identified the native bootstrap history-lock
  reentrancy issue, active-operation status semantics, service-off reconciliation,
  and the macOS cache-root mismatch. All were addressed without custom watchers
  or a replacement synchronization protocol.
- Before live capture, the native paths preview reported 37 entries and no
  invalid, incomplete or omitted paths. The first live preference checkpoint
  covered 64 files. All 63 preexisting preference files compared byte-for-byte
  equal to the private pre-cutover snapshot (the tracking config was new).
- The native launchd watcher autosaved a harmless test file's creation and
  deletion. It also automatically published creation/deletion of a separate
  probe to private `phall1/dotfiles-history`, without explicit save/sync calls.
- A second isolated native client restored the real private history without
  receiving host credentials. Its edit and deletion were relayed to the private
  origin with parent-authenticated Git; the live watcher automatically applied
  both. A temporary five-second local fetch interval was removed afterward.
- Chezmoi verification passed after enrollment. Doctor checks native history,
  watcher status, reported sync errors and the ownership-set intersection.
- Live Mac repeat `mise bootstrap --yes` passed after enrollment and origin
  connection. Native status reports a running watcher, zero pending operations,
  zero conflicts and no synchronization errors.

## Complexity

Measured using `uvx --from radon==6.0.1 radon cc -s`:

| Function | Before | After |
|---|---:|---:|
| `configure` | 8 | 9 |
| `tracking_entries` | — | 3 |
| `history_config` | — | 1 |
| `watcher_directories` | — | 2 |
| `enable_history` | — | 3 |
| `_compile` (zsh, manual decision count) | 5 | 5 |

No existing public API was removed. The new functions separate enrollment data,
portable native configuration, and machine-local service directories. The
existing private/atomic TOML writer is reused. The zsh guard retains its branching
complexity while removing derived bytecode for absent sources.

## Performance

No performance baseline was repinned. The initial comparison shows no new
>10% regression, but the prior first-command absolute gate remains open:

| Measurement (10 iterations) | Command | Input | First command | First prompt |
|---|---:|---:|---:|---:|
| Before history (`1788882278.json`) | 27.4 ms | 5.1 ms | 248.8 ms | 41.8 ms |
| After history (`1788885195.json`) | 21.8 ms | 5.5 ms | 230.4 ms | 34.2 ms |
| Final recovery validation (`1788886988.json`) | 22.1 ms | 5.1 ms | 247.0 ms | 33.4 ms |

The first-command ceiling is 220 ms. Other metrics pass. Records are in
`~/.local/state/dotfiles/bench/`. Follow-up isolated profiling found no verified
whole-shell improvement; no speculative performance changes were applied.

## Single-command onboarding follow-up

`scripts/onboard.sh` is standalone and assumes existing Homebrew/Git/gh/mise,
Git identity and GitHub authentication. The documented download-first command
executes only after a complete successful transfer. The entrypoint establishes
cache/state roots, invokes native adoption, checkpoints outside the bootstrap
transaction, synchronizes and runs both doctor and bench. Final checks include
newly installed mise shims and Cargo tools in PATH.

Acceptance coverage:

- Eight onboarding boundary tests cover prerequisites, directory overrides,
  newly installed tool visibility, partial-download rejection in Bash and zsh,
  the documented successful download command, native-operation failures and
  health/performance exit-status handling.
- The released mise integration suite exercises actual adoption through the new
  entrypoint, then runs it again with a live edit and verifies preservation.
- Five real benchmark tests execute through platform `/bin/bash`, including
  stock macOS Bash 3.2. Valid measurements persist the existing JSON schema;
  regressions, missing/invalid measurements and malformed baselines fail.
- Independent review's PATH, download-failure and benchmark compatibility findings
  are resolved. No remaining P1/P2 findings were reported.

The benchmark now uses indexed arrays compatible with Bash 3.2, validates every
declared baseline and requires every pinned measurement before certifying a pass.
This fixes false-success paths without changing any `PERF.md` threshold.

Manual shell cyclomatic complexity (Python fixture methods measured with Radon
remain at most 4):

| Function | Before | After |
|---|---:|---:|
| `measure` | 4 | 4 |
| `measurement_error` | — | 1 |
| `record_result` | — | 2 |
| `validate_baseline` | — | 3 |
| `require_pinned_results` | — | 5 |
| `require_command` | — | 2 |
| `check_git_identity` | — | 4 |
| `check_prerequisites` | — | 5 |
| `verify_setup` | — | 6 |
