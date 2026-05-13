# PLAYBOOKS.md

Per-task recipes with exact commands. When an agent gets pointed at this repo
with a task, the relevant playbook below is the canonical execution path.
**Skip the playbook only if the task explicitly demands deviation** — then
note the deviation in the commit.

Every playbook ends with the **change-loop tail**: `dot-doctor` + `dot-bench`
+ commit. That's not optional.

---

## P1. Adding a new zsh plugin

```sh
# 1. Find the plugin on GitHub. Get the SHA you want (preferably tagged release,
#    or HEAD of main if no releases).
sha=$(git ls-remote https://github.com/OWNER/REPO main | awk '{print $1}')
echo "$sha"

# 2. Add a line to plugins.lock in the right section (UX plugins, perf tools, etc.):
$EDITOR ~/dotfiles/plugins.lock
# Add: <local-name>  OWNER/REPO  <sha>

# 3. Clone it.
dot-install-zsh-plugins
# Verify the new plugin entry came back as ok=N+1 installed=1.

# 4. Wire it into dot_zshrc.
#    - If eager-load: source it after compinit, BEFORE deferred plugins.
#    - If deferred: zsh-defer source "$ZSH_PLUGIN_DIR/<name>/<file>"
#    - If completion-fpath only: fpath=(...) BEFORE compinit.
$EDITOR ~/dotfiles/dot_zshrc

# 5. Apply + verify.
chezmoi diff
chezmoi apply
zsh -i -c 'echo loaded'         # smoke-test the shell starts
dot-doctor                       # zsh plugins section should show new plugin green
dot-bench                        # baseline shouldn't regress >10%

# 6. Commit.
git add plugins.lock dot_zshrc
git commit -m "feat(zsh): add <plugin> for <reason>"
```

**Gotchas:**
- `fzf-tab` must load *after* compinit but *before* anything that overrides
  the `^I` widget.
- `fast-syntax-highlighting` MUST be loaded last among highlighters.
- Don't `zsh-defer` plugins that need to register completion widgets.

---

## P2. Bumping a plugin to a new SHA

```sh
# 1. Inspect upstream changes.
cd ~/.local/share/zsh/plugins/<name>
git fetch
git log --oneline HEAD..origin/main | head -20
# Read the diff. Trust nothing.

# 2. Pick a SHA. Prefer a tagged release if it exists.
git log --oneline HEAD..origin/main
new_sha=<sha>

# 3. Check out locally to verify it doesn't break our shell.
git checkout "$new_sha"
zsh -i -c 'echo plugin loaded'   # smoke
dot-bench                         # perf

# 4. Update plugins.lock.
$EDITOR ~/dotfiles/plugins.lock
# Replace the old SHA with the new one on the relevant row.

# 5. Verify doctor reports no drift.
dot-doctor   # zsh plugins: <name> @ <new-short-sha>

# 6. Commit.
cd ~/dotfiles
git add plugins.lock
git commit -m "chore(zsh): bump <name> to <short-sha>"
# Body: link to the upstream changelog/commit range if non-trivial.
```

---

## P3. Adding a doctor check

```sh
# 1. Decide: global or per-tool?
#    - Global (applies to repo as a whole)  → checks/<NN>-<topic>.sh
#    - Per-tool (only when that tool exists) → checks/<tool>.sh

# 2. Write the file. Use the exported helpers — don't re-implement.
cat > ~/dotfiles/checks/40-new-thing.sh <<'EOF'
# New thing checks.

hdr "new-thing"

if [[ -f "$HOME/.expected-file" ]]; then
  ok ".expected-file present"
else
  warn ".expected-file missing — run setup-new-thing"
fi
EOF

# 3. Test in isolation.
dot-doctor --list                # confirm it's discovered
dot-doctor                       # confirm it runs and outputs as expected
DOT_SKIP=new-thing dot-doctor    # confirm skip works

# 4. Commit.
git add checks/40-new-thing.sh
git commit -m "feat(doctor): check for <thing>"
```

**Helpers available** (sourced by orchestrator before each check file):
`hdr`, `ok`, `warn`, `fail`, `require_bin <name> [hint]`, `want_bin <name> [hint]`,
`file_age_h <path>`. Variables: `$DOTFILES`, `$STATE_DIR`, `$HOME`.

**See `checks/README.md`** for the full pattern.

---

## P4. Adding a bench metric

`dot-bench` runs `zsh-bench` and parses key=value lines from its output.
zsh-bench emits a fixed set of metrics — we don't add new ones to zsh-bench
itself. To gate against an additional metric:

```sh
# 1. Verify the metric appears in zsh-bench's output.
zsh-bench | grep new_metric
# If it does, no code change to dot-bench is needed.

# 2. Add a baseline pin in PERF.md between the BASELINE markers.
$EDITOR ~/dotfiles/PERF.md
# Add: new_metric_name: <ceiling_value>

# 3. Run.
dot-bench                        # confirm regression-gate fires on >10% diff

# 4. Commit.
git add PERF.md
git commit -m "perf: pin <metric> baseline at <value>"
```

For totally new metrics (zsh-bench doesn't measure it), you'd need to extend
`dot-bench` itself — keep it data-driven, don't hardcode metric names.

---

## P5. Adding a new $HOME file (config for a new tool)

```sh
# 1. Figure out the target $HOME path. Examples:
#    ~/.foorc                          → dot_foorc
#    ~/.config/foo/config              → dot_config/foo/config
#    ~/.local/share/foo/data           → dot_local/share/foo/data
#    ~/.foo/settings.json (private)    → dot_foo/private_settings.json
#    ~/.foo (symlink to /opt/foo)      → symlink_dot_foo (content = target path)

# 2. Create in chezmoi source.
mkdir -p ~/dotfiles/dot_config/foo
$EDITOR ~/dotfiles/dot_config/foo/config

# 3. Preview + apply.
chezmoi diff                     # confirm scope
chezmoi apply

# 4. Verify the new file landed.
ls -la ~/.config/foo/config

# 5. Commit.
git add dot_config/foo
git commit -m "feat(foo): add base config"
```

**If the new file needs templating** (different content per machine):

```sh
# Rename with .tmpl extension; chezmoi treats it as a Go template.
mv ~/dotfiles/dot_config/foo/config{,.tmpl}

# Use template syntax inside the file:
#   {{ .git.email }}              # from chezmoi.toml [data]
#   {{ .chezmoi.hostname }}       # built-in
#   {{ if eq .chezmoi.os "darwin" }}...{{ end }}

# Re-apply to verify rendering.
chezmoi diff
chezmoi apply
cat ~/.config/foo/config         # confirm template rendered correctly
```

---

## P6. Adding a brew package (Mac)

```sh
# 1. Add to scripts/bootstrap-darwin.sh.
$EDITOR ~/dotfiles/scripts/bootstrap-darwin.sh
# Add to the brew_packages array, grouped logically.

# 2. Install on this machine (so doctor sees it).
brew install <pkg>

# 3. If the tool needs shell-init (e.g. zoxide init zsh), wire into dot_zshrc.
#    If it's a dependency of an existing tool, no shell change needed.

# 4. Add a doctor check if it's load-bearing.
#    - Required tool (substrate must have it)  → checks/00-binaries.sh: require_bin
#    - Wanted tool (nice-to-have)               → checks/00-binaries.sh: want_bin

# 5. Apply (only if shell init was changed) and verify.
chezmoi diff
chezmoi apply
dot-doctor                       # new binary should show green

# 6. Commit.
git add scripts/bootstrap-darwin.sh checks/00-binaries.sh dot_zshrc
git commit -m "feat(toolchain): add <pkg> — <reason>"
```

For Pi/Linux, edit `scripts/bootstrap-linux.sh` — apt first, fall back to
nix if apt doesn't have it or has an outdated version.

---

## P7. Adding a Claude Code skill / agent / hook / MCP server

See **CLAUDE.md** for the full picture. Cheat sheet:

| Type | Source path | Activation |
|---|---|---|
| Skill | `dot_claude/skills/<name>/SKILL.md` | Auto-loaded on next session by Claude Code's skill discovery |
| Agent | `dot_claude/agents/<name>.md` | Tab to switch, or `@<name>` mention |
| Hook | Edit `dot_claude/settings.json` → `hooks` | Harness-executed on configured events |
| MCP server | Edit `dot_claude/settings.json` → `mcpServers` | Auto-connected on next session |
| Slash command | `dot_claude/commands/<name>.md` | `/<name>` in-session |

```sh
# Always edit in the chezmoi source, then apply.
$EDITOR ~/dotfiles/dot_claude/skills/<name>/SKILL.md   # or settings.json, etc.
chezmoi diff
chezmoi apply

# Confirm pickup.
claude-discover                   # new skill/agent/hook should appear with 🆕

git add dot_claude/
git commit -m "feat(claude): add <name> <skill|agent|hook|mcp>"
```

---

## P8. Adding a per-machine override

Three levels — pick the lowest one that covers the case.

```sh
# Level 1 — identity only: just edit chezmoi.toml.
$EDITOR ~/.config/chezmoi/chezmoi.toml
chezmoi apply

# Level 2 — multi-field per-host: branch in the template.
$EDITOR ~/dotfiles/dot_gitconfig.tmpl
# Add:
#   {{ if eq .chezmoi.hostname "<this-host>" }}
#   ...overrides...
#   {{ end }}

# Level 3 — work-vs-personal on the same machine: per-directory include.
cp ~/dotfiles/scripts/.gitconfig-work.example ~/.gitconfig-work
$EDITOR ~/.gitconfig-work   # untracked, machine-local
# The tracked template already includes:
#   [includeIf "gitdir:~/work/"]
#       path = ~/.gitconfig-work
```

---

## P9. Investigating a perf regression

```sh
# 1. Confirm the regression.
dot-bench
# Exit nonzero + a regressed metric named in the output.

# 2. Find the hot spot.
ZSH_PROF=1 zsh -i -c exit 2>&1 | head -30
# Sorted by self-time. The function at the top is your problem.

# 3. Trace what's being sourced.
zsh -xv 2>&1 | head -100
# Verbose load trace. Look for unexpected `source` lines.

# 4. Re-test in isolation.
zsh -f -i -c exit               # no rc files
zsh -i -c exit                  # full init
# Difference tells you where the cost is.

# 5. After fix:
dot-bench                       # confirm green
git add ...
git commit -m "perf(zsh): <what changed> — <metric> N → M"

# If the regression was justified (new feature with real value), re-pin
# the baseline instead — but justify in the commit body.
$EDITOR PERF.md                 # update key: value_ms
git commit -m "perf: re-pin <metric> baseline (was N, now M) — <reason>"
```

---

## P10. Onboarding a new machine

```sh
# 1. Install minimal prerequisites manually if needed.
xcode-select --install                  # mac only
# (Linux: nothing — bootstrap-linux.sh handles everything)

# 2. Clone the repo to ~/dotfiles.
git clone https://github.com/phall1/dotfiles.git ~/dotfiles

# 3. Run host bootstrap.
~/dotfiles/scripts/bootstrap-darwin.sh   # or bootstrap-linux.sh
# Bootstrap finishes with a copy-paste next-steps block.

# 4. Follow the printed steps:
~/dotfiles/scripts/setup-chezmoi.sh      # interactive identity setup
chezmoi apply                            # materialize $HOME
~/.local/bin/dot-doctor                  # verify
~/.local/bin/dot-bench                   # verify perf

# 5. Sign in to per-machine services.
gh auth login                            # GitHub
# (other per-machine tokens: do as needed)

# 6. Restart shell.
exec zsh
```

If any step fails, **don't paper over it**. Diagnose, fix the root cause,
update the docs.

---

## P11. Recovering from a broken `chezmoi apply`

```sh
# 1. See what's diverged.
chezmoi status                          # files modified / added / removed
chezmoi diff                            # exact content delta

# 2. If $HOME files were edited by hand and conflict with source:
chezmoi diff                            # decide which side wins
# To keep $HOME's version:
chezmoi merge <path>                    # opens 3-way merge in $EDITOR
# To force source over $HOME:
chezmoi apply --force <path>            # destructive; uses source as truth

# 3. After resolving:
dot-doctor                              # confirm green
```

**Never delete `$HOME/.zshrc` etc. as a "fix"** — re-apply from source.
The source repo is the truth.

---

## P12. Updating this doc

When you add a recipe, follow the structure:

1. Numbered heading (`P13. <task>`).
2. Imperative commands in order.
3. Verify steps + change-loop tail (`dot-doctor` + `dot-bench` + commit).
4. Gotchas section if there are non-obvious failure modes.

Don't add a playbook for a task that's already covered by an existing one.
Compose — don't fork.
