# Bootstrap migration acceptance — 2026-09-07

## Executed checks

| Check | Evidence |
|---|---|
| Native mise orchestration | `mise run check` and `mise bootstrap --yes` passed on macOS arm64 with mise 2026.9.1 |
| Linux arm64 | Debian 13 non-root fresh HOME, `container,pi`; real installs, strict shell checks and second-run convergence passed |
| Linux amd64 | Earlier installation/configuration/shell convergence passed. Final strengthened runtime check fails at `phui --version` under this Mac's emulator; native amd64 acceptance remains open |
| Runtime config preservation | Darwin arm64, Linux arm64 and Linux amd64 chezmoi fixtures each applied and verified twice |
| Native applications | Phux composed configuration and Phig configuration passed; Phig performed repository status in containers and on the Mac |
| Live services | Blackbird and Phux daemon PIDs were identical before and after Mac bootstrap |
| Failure-path service policy | Stubbed native boundaries cover Blackbird doctor/schema/probe failures, existing unhealthy Phux units, absent-unit adoption and services-off; live processes are retained |
| File retirement | Exact known copies are retired; a locally modified copy fails closed and survives |
| Machine profile writer | Three regression tests cover private permissions, identity/unknown-data preservation, repeat convergence, selection changes and malformed TOML |
| V2 goal plugin | Exact Git pin passed its Node tests and TypeScript check; check repeated against SDK beta-19157 |
| OpenCode login boundary | Final arm64 container executes the native CLI and enumerates its account-scoped catalog without credentials (empty is valid); Astra is checked when OpenAI is connected |
| Existing checks | `tests/gha-local-smoke.sh`, warning-level ShellCheck, Renovate semantic validator 44.26.0 and `git diff --check` passed |
| lstags | `cargo test --locked --manifest-path src/lstags/Cargo.toml` passed; the crate currently contains zero unit tests |
| Mac configuration drift | `chezmoi verify --exclude scripts` passed after live bootstrap |
| Real project activation | A PTY-backed interactive zsh entered a trusted temporary mise project, selected Node 24.20.0 and its environment, then restored the environment on leaving |

Linux acceptance uses the published GitHub release artifacts, not host binaries
or credentials. Exact tool versions and available artifact checksums/URLs are in
the mise lockfiles. Both architectures exercised actual Phig repository access;
the earlier Bookworm rig exposed Git's minimum-version incompatibility, which
is why the supported clean Linux base is Trixie.

CI definitions execute these lanes on native Mac/Linux runners and Linux
amd64/arm64 containers. The local runs above are the migration evidence; CI
publication is a separate repository operation.

## Complexity evidence

No project-native Bash complexity analyzer is configured. Shell counts below
use CC = 1 + conditionals, loops, short-circuit guards and non-default case arms.
Python was measured with `uvx --from radon==6.0.1 radon cc -s
scripts/bootstrap/configure.py`.

| Function | Before | After | Method |
|---|---:|---:|---|
| Old `install_formula` | 2 | removed | Manual; replaced by native Homebrew Bundle |
| Old `install_cask_app` | 4 | removed | Manual; replaced by native Homebrew Bundle |
| `_mise_lazy_load` | 6 | 6 | Manual; duplicate eager hook call removed without adding branches |
| `prompt_mise` | 3 | 5 | Manual; recognizes the same three project config locations as activation |
| New `configure` | — | 8 | Radon B; initial implementation was also 8 |
| New `harness_name` | — | 2 | Radon A |
| New `git_identity` | — | 1 | Radon A |
| New `write_private_config` | — | 1 | Radon A |
| New `install_harness` | — | 7 | Manual; explicit native-installer dispatch |
| New `reconcile_blackbird` | — | 8 | Manual; includes the boolean operator inside the jq predicate |
| New `blackbird_is_absent` | — | 4 | Manual; requires both connection refusal and no matching process |
| New `disable_linux_brew_updater` | — | 3 | Manual |
| New `reconcile_phux` | — | 4 | Manual |
| New fixture `resolve_binary` | — | 5 | Manual; excludes inactive shims when resolving native fallback binaries |

The service functions retain clear guard clauses; no helper exceeds the default
refactor threshold. The Phux TOML modifier uses a single conditional and a
comment-preserving parser instead of hand-written TOML text surgery.

## Performance acceptance: still failing under host contention

`PERF.md` was **not repinned**. All four pinned metrics already failed before
the migration. Mac and Linux arm64 functional acceptance passed; absolute shell
performance acceptance remains open alongside native amd64 runtime acceptance.

| Measurement | Command | Input | First command | First prompt |
|---|---:|---:|---:|---:|
| Before migration, 10 iterations (`1788674636.json`) | 54.4 ms | 11.3 ms | 797.4 ms | 61.5 ms |
| First post-apply run, 10 iterations (`1788678719.json`) | 129.3 ms | 11.8 ms | 1704.1 ms | 69.6 ms |
| Later loaded-host run, 10 iterations (`1788746322.json`) | 104.6 ms | 12.6 ms | 2471.7 ms | 156.9 ms |
| Old startup files, 3-iteration diagnostic (`1788747124.json`) | 221.3 ms | 72.9 ms | 2940.2 ms | 467.2 ms |

Raw records live in `~/.local/state/dotfiles/bench/`. The last row used the old
`.zshenv`, `.zprofile` and `.zshrc` in a temporary ZDOTDIR with current installed
tools; it is a diagnostic, not a replacement for the ten-iteration gate. Its
paired new-source run was interrupted by a server restart. These measurements
do not establish a reliable relative performance difference.

Observed interference included load averages of 26–31 on a 14-core machine,
an unrelated multi-process Rust build, and six orphaned shells with revoked
terminal descriptors. Even absolute `/usr/bin/true` showed 29–88 ms wall time
for 3–5 ms CPU. Temporarily suspending the orphaned shells did not yield a
successful controlled run; all six were explicitly resumed afterward. No user
workload was killed.

Repeat `dot-bench` when unrelated host activity is quiet. A passing result is
required before claiming the performance gate is green; the available evidence
does not justify changing its thresholds or redesigning activation to chase
these noisy numbers.

## Native amd64 runtime acceptance: pending

The final stricter `phui --version` smoke check exposes a crash in the published
Phui v0.15.0 x64 executable under this Mac's emulator. The embedded Bun v1.3.14
reports missing AVX support and terminates with signal 4 (exit 132). The same
application check passes on Linux arm64. Earlier amd64 convergence evidence did
not execute Phui, so it is insufficient to declare the final amd64 lane green.

Run `bash tests/bootstrap/container.sh linux/amd64` on a native amd64 host with
AVX support, or run the configured native GitHub CI job after publication. No
runtime check is bypassed for emulation. A missing Docker cache snapshot after
a server restart was separately resolved by rebuilding this task's amd64 image
with `--no-cache`; that did not resolve the CPU-instruction limitation.

## Validation boundaries

- Optional Claude/Hermes/Goose/Grok installer commands were checked against
  official installer source and local installation conventions. Their complete
  first-install flows are not covered by the core/Pi container matrix.
- Container services are deliberately disabled. Native service first-install
  behavior belongs to the products; this repo tests boundary decisions and
  verifies that migration preserves the live Mac daemons.
- Cockpit and Token Tach preference keys were checked against their native
  parsers' supported surfaces. This migration did not drive their graphical UI.
- The workstation's provider credentials and existing optional-harness runtime
  state were retained. No authenticated model call is needed by bootstrap.
