# REVERSIBLES.md

Every **system-wide mutation** this repo or its setup scripts have made,
paired with the exact command to undo it.

This is for state that lives **outside the repo** — `defaults write`,
`csrutil`, system permissions, launchd installs, font installs, anything
that survives a `chezmoi apply` revert. Config files don't go here; they're
already tracked by chezmoi/git and revertable via `git revert`.

**Convention:** when Claude (or you) makes a system mutation, add an entry
here with date, what, why, apply command, and revert command. Newest entries
at the top.

---

## 2026-05-24 — macOS menu bar auto-hide

**What:** the macOS menu bar now auto-hides; cursor to the top edge to
reveal it.

**Why:** sketchybar already shows time, battery, and volume, so the macOS
bar was visually doubling the top of the screen during initial rice setup.

**Apply:**
```sh
defaults write NSGlobalDomain _HIHideMenuBar -bool true
killall SystemUIServer
```

**Revert:**
```sh
defaults write NSGlobalDomain _HIHideMenuBar -bool false
killall SystemUIServer
```

**Verify:** `defaults read NSGlobalDomain _HIHideMenuBar` → `1` when enabled,
`0` when reverted.

---

## Not yet applied — SIP partial-disable (yabai scripting addition)

Listed here so it's tracked in one place if/when you do it. See
`docs/RICE.md` for the recovery-boot procedure. Until applied, cross-space
window move, opacity, and animations are off.

**Revert path:** boot to recovery → `csrutil enable` → reboot → `sudo yabai
--uninstall-sa`.

---

## How to add an entry

```markdown
## YYYY-MM-DD — short title

**What:** one-sentence description of the user-visible effect.
**Why:** the reason, ideally referencing the setup step or feature that needed it.
**Apply:** the exact command(s) that made the change.
**Revert:** the exact command(s) to undo.
**Verify:** how to check current state.
```

Skip entries for things that revert themselves naturally (e.g.,
`brew uninstall <pkg>` for an installed formula — `brew list` tells you what's
installed). This file is for **mutations that aren't obviously inventoried
elsewhere**.
