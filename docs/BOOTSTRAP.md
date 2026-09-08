# Workstation bootstrap

## Ownership

For another already-equipped machine, run the standalone onboarding entrypoint:

```sh
onboard=$(curl -fsSL https://raw.githubusercontent.com/phall1/dotfiles/feat/mise-workstation/scripts/onboard.sh) && bash <<< "$onboard"
```

It adopts the shared private setup and runs the final checks using existing
tools and authentication. [Onboarding details](SELF-SAVING-DOTFILES.md#shared-repository-and-another-machine).

`mise bootstrap` is the provisioning entrypoint. Native mise history owns enrolled live
preferences and automatically saves/synchronizes edits. Chezmoi renders the
remaining machine-specific files and reconciles explicit integration keys. Native
applications own authentication, databases, sessions, pairing and their service
definitions. Bootstrap never copies these between hosts.

| Inventory | Authority | Update policy |
|---|---|---|
| Portable tools | `mise.toml`, `mise.lock` | Exact versions; reviewed pin changes and lock refresh |
| Linux packages/tools | `mise.linux.toml`, `mise.linux.lock` | apt for host dependencies; mise for release binaries |
| Mac host tools/personal tap | `provision/Brewfile` | Real Homebrew; bootstrap installs missing packages without upgrading |
| Mac desktop apps | `provision/Brewfile.desktop` | Real Homebrew casks and their native auto-updaters |
| Pi coding harness | `mise.pi.toml`, `mise.pi.lock` | Optional exact CLI version; native Pi package installation |
| OpenCode V2 | Official `@opencode-ai/cli` installer | Seed version in `integrations.sh`; then native auto-update |
| Other selected harnesses | `scripts/bootstrap/harnesses.sh` | Native installer; existing installations are retained |
| Rust | rustup | Native toolchains and project `rust-toolchain.toml` |
| Editable preferences | Native mise tracking, initially selected by `provision/dotfiles-history.json` | Edit live → autosave → private two-way sync |
| Templates and integrations | Remaining chezmoi `dot_*` sources | Preview → apply → verify |
| Phux/Blackbird services | Native product installers | Healthy services are retained; Phux adoption preserves live panes |

The minimum mise release is **2026.9.3**. Its `brew:` backend is an independent
installer and cannot consume the personal tap's Ruby-only metadata. This is why
Mac package installation deliberately calls real Homebrew. Rolling mise web docs
describe some later features; this setup uses released commands.

## Fresh machine

Clone this repository into `~/dotfiles`. macOS needs Xcode Command Line Tools;
Linux needs Debian 13 / Raspberry Pi OS Trixie (64-bit), or an apt-based host
with Git >=2.45.1. Configure a real Git
identity before provisioning:

```sh
git config --global user.name 'Your Name'
git config --global user.email 'you@example.com'
cd ~/dotfiles
bash scripts/bootstrap-darwin.sh --yes   # macOS
# or:
bash scripts/bootstrap-linux.sh --yes --update
```

These seed scripts obtain mise and prerequisites, then invoke **the same**
`mise bootstrap` used for subsequent convergence. No Nix or fnm installation is
needed. Existing Nix installations and project flakes remain independently owned.

Bootstrap's final task:

1. Preserves machine-local chezmoi data and records the source directory.
2. Previews and applies the selected configuration.
3. Installs the rendered global tool inventory and refreshes shell init caches.
4. Installs missing native harnesses, builds lstags and reconciles services.
5. Reconciles installer-written config, then relinquishes ownership of enrolled
   live preferences and reconciles the native history watcher.
6. Compiles the live shell and verifies generated files, history health and doctor.

Native bootstrap holds its history transaction until exit. Its watcher captures
new enrollment after that transaction finishes. In a service-free container,
follow initial enrollment with `mise bootstrap dotfiles save` explicitly.
See [the self-saving workflow](SELF-SAVING-DOTFILES.md) for sharing and recovery.

Provider logins remain per-machine: use OpenCode's `/connect`, `gh auth login`,
and the selected applications' normal login commands. Bootstrap does not invent
credentials or require an authenticated model request to install a workstation.

## Profiles

Platform environment selection is native mise `auto_env` in `.miserc.toml`.
`mise.linux.toml` loads on Linux. The optional **Pi coding agent** is unrelated to
the Raspberry Pi hardware platform.

Default: OpenCode V2, Blackbird, Phux, the shell/editor tools, and Mac desktop
applications on macOS. To add optional harnesses:

```sh
mise run configure pi claude       # persists the complete optional selection
mise bootstrap --yes
# For a fresh machine, this also installs and selects Pi:
mise -E pi bootstrap --yes
```

Accepted optional harnesses: `pi`, `claude`, `hermes`, `goose`, `grok`.
`mise run configure opencode` returns the managed selection to core-only.
Deselection stops managing optional files; it does not delete existing runtime
state, uninstall applications, or revoke authentication.

Selections live under `[data]` in `~/.config/chezmoi/chezmoi.toml`:

```toml
harnesses = ["opencode", "pi"]
services = true
```

The generated `~/.config/dotfiles/profile.json` lets doctor use the same selection.
The generated `~/.config/mise/conf.d/dotfiles.toml` supplies global tool versions,
so tools work outside this repository; project configs override personal defaults.

Use `mise -E server bootstrap` on a Mac without the desktop bundle. Use
`mise -E container bootstrap` in a disposable environment to disable service
installation by default. `mise run configure -- --services off` explicitly
persists that choice on an existing machine. Disabling setup does not stop an
existing application-owned service; use its native lifecycle commands for that.

## Disposable test rig

```sh
mise run check
bash tests/bootstrap/container.sh linux/arm64
bash tests/bootstrap/container.sh linux/amd64
bash tests/bootstrap/container.sh linux/arm64 container,pi
bash tests/bootstrap/goal-plugin.sh
uv run --script tests/bootstrap/history_test.py
```

The Docker rig **copies** the checkout into an image, creates a non-root test
user and fresh HOME, then runs real installation and a second convergence. It
does not mount HOME, the Docker socket, SSH agents or credentials. Containers
are removed on exit. Images are named `dotfiles-bootstrap:arm64` / `:amd64` and
can be removed with `docker image rm` after testing.

For amd64 runtime validation, use a native x64 host with AVX support. Phui's
published x64 executable embeds Bun and currently crashes under this Mac's
non-AVX Linux emulator. The rig deliberately retains the runtime smoke check.
See [migration acceptance evidence](BOOTSTRAP-VALIDATION.md) for the executed
checks and outstanding performance/native-amd64 gates.

Coverage:

- real Linux packages and declared tool downloads;
- source-to-HOME materialization and a clean second apply;
- noninteractive, interactive and login zsh tool access from a minimal PATH;
- no Phux/Blackbird service units and no login-shell changes in container mode;
- Darwin arm64, Linux arm64 and Linux amd64 template fixtures;
- preservation of app-owned JSON/TOML/YAML fields and create-only package data;
- private machine-data writes, selected-harness changes and malformed-input handling;
- the pinned V2 goal plugin's tests and type compatibility with our SDK.

Fixtures use real jq/yq/chezmoi/uv executables, not mise shims, inside an empty
environment. The pinned TOML parser is provisioned before fixture execution;
fixture uv calls then use offline mode and the dependency cache. They exclude
chezmoi **run scripts**, which prevents a macOS fixture
from reaching the host's launchd domain. They still execute real `modify_` file
transformations. CI runs native Mac/Linux fixtures and both Linux architectures.

Containers do not validate macOS app installation, launchd behavior, authenticated
provider routes, or host performance. Those checks run on the actual workstation
after the isolated rig passes. `PERF.md` remains the host's performance gate.

## Daily operations

```sh
mise bootstrap --dry-run              # preview declarative provisioning
mise bootstrap status --missing       # native mise resources
mise run audit                        # includes chezmoi and tool inventory
chezmoi diff
chezmoi apply
chezmoi verify --exclude scripts
mise run doctor
mise run bench
```

Mise's structured bootstrap plan does not inspect the internals of custom tasks.
`--dry-run` prints those tasks; it does not replace the chezmoi fixture suite.
Like other mise tasks, `mise run check` may first install missing declared tools
and parser dependencies into caches; the configuration tests themselves use
disposable homes.

To update a tool, edit its version in the owning mise manifest, refresh its
lockfile (`mise lock --platform macos-arm64,linux-arm64,linux-x64`), run the rig,
then bootstrap. Linux and Pi locks are refreshed with `mise -E linux,pi lock
--platform linux-arm64,linux-x64`. npm backend entries have exact package versions
but no downloadable-artifact lock entries; do not claim universal `--locked`
support for this mixed inventory.

Use `brew upgrade <package>` for Homebrew-owned packages. Phux's CLI upgrade and
live-server handover remain separate: follow with `phux upgrade` deliberately.
Linux Blackbird's Homebrew update timer is disabled when mise owns its binary.
Mise bootstrap does not run package pruning or uninstall former package owners.

## Preferences and recovery

- **Phux:** chezmoi appends `layers/dotfiles.toml` to `extends`, preserving existing
  distro and host entries. `phux config check` validates the composed config.
- **Cockpit:** sparse XDG config; Settings UI changes are intentional drift to
  review and import. Device/session selection remains local.
- **Phui:** merge the generic workspace mapping and portable theme; preserve
  specific mappings and editor settings. `projects.toml` remains local.
- **Phig:** strict, portable TOML; validate with `phig config check`.
- **Token Tach:** portable preferences only, not usage history.
- **OpenCode:** CLI UI preferences merge with unknown local fields. V2 server
  config remains explicitly fully managed. Goal mode is pinned to a reviewed Git
  commit; the former V1 autoresearch plugin and launchers are retired.
  Bootstrap removes only checksum-matching retired copies; locally edited copies
  stop retirement with the exact path to review.
- **Blackbird:** MCP uses port 8081; push delivery uses port 8080. The global push
  plugin retains its existing central-inbox scope at `~/workspace/blackbird`,
  not automatic current-project routing. Use explicitly project-scoped plugin
  settings for other inboxes. MCP coordination tools can join projects separately.

Keep a persistent checkout at `~/dotfiles` on every host. Archive-based
`mise bootstrap remote` uses temporary staging, so do not point chezmoi source or
long-lived symlinks into that staging directory. For a Pi already reachable over
SSH, clone/update its persistent checkout and invoke bootstrap there. For the
shared history setup use `mise bootstrap --adopt phall1/dotfiles-history`.
Mise 2026.9.3 calls this `--adopt`; the article's `--from-git` is a deprecated alias.

Back up Blackbird's database, Phux host identity and application history through
an operational backup system. They are recovery data, not portable preferences.
