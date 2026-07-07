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

## 2026-07-07 — removed macOS rice stack

**What:** yabai, skhd, sketchybar, and borders are no longer managed by this
repo. Native macOS window management and the native menu bar are the default
again.

**Why:** the custom tiling and top bar setup was too intrusive for daily use.

**Apply:** remove the tracked configs, stop the launchd services, and uninstall
the packages:

```sh
yabai --stop-service
skhd --stop-service
launchctl bootout "gui/$(id -u)/homebrew.mxcl.sketchybar"
launchctl bootout "gui/$(id -u)/homebrew.mxcl.borders"
rm -f ~/Library/LaunchAgents/{com.asmvik.yabai,com.jackielii.skhd,homebrew.mxcl.sketchybar,homebrew.mxcl.borders}.plist
brew uninstall --force yabai sketchybar borders
brew uninstall --cask --force skhd-zig font-sketchybar-app-font
brew untap jackielii/tap FelixKratz/formulae koekeishiya/formulae
```

**Revert:** restore the removed files from git history, run
`scripts/bootstrap-darwin.sh`, then start the services you want.

**Verify:** `launchctl list | grep -E "yabai|skhd|sketchybar|borders"` should
return no running service rows.

---

## 2026-05-24 — macOS menu bar auto-hide

**What:** the macOS menu bar auto-hides; cursor to the top edge to reveal it.

**Why:** sketchybar showed time, battery, and volume, so the macOS bar visually
doubled the top of the screen. This is obsolete now that sketchybar is removed.

**Apply (macOS 13 Ventura and later — must use System Settings UI):**
The `defaults write NSGlobalDomain _HIHideMenuBar` key is silently ignored
on Ventura+. The setting is in a sandboxed pref store that only the
Settings app can write reliably.

  1. System Settings → Control Center
  2. Scroll to "Menu Bar Only"
  3. "Automatically hide and show the menu bar" → **Always**

**Revert:** same path, set to **Never** (or "On Desktop Only" / "In Full
Screen Only" for a middle ground). These defaults set the same "Never" state
on current macOS releases:
`defaults write NSGlobalDomain _HIHideMenuBar -bool false && defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool true && killall SystemUIServer`.

**Verify:** move cursor away from the top of the screen — bar should
disappear within ~1s. Move back to top edge — it reveals.

**Pre-Ventura legacy command (kept for reference; doesn't work on macOS 26):**
`defaults write NSGlobalDomain _HIHideMenuBar -bool true && killall SystemUIServer`

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
