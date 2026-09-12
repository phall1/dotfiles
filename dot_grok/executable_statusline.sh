#!/bin/sh
# Grok status line — model, cwd, git (p10k-style dirty), worktree, ctx, cost.
# Fast and silent: no output except the final line, no errors outside a repo.

set -eu

input="$(cat 2>/dev/null || true)"

fields="$(printf '%s' "$input" | jq -r '
  [
    (.model.display_name // "Grok"),
    (.workspace.current_dir // .cwd // ""),
    (.context_window.remaining_percentage // empty | floor | tostring),
    (.cost.total_cost_usd // empty | tostring),
    (.workspace.git_worktree // .worktree.name // ""),
    (.effort.level // "")
  ] | @tsv' 2>/dev/null || true)"

model="$(printf '%s' "$fields" | cut -f1)"
dir="$(printf '%s' "$fields" | cut -f2)"
ctx="$(printf '%s' "$fields" | cut -f3)"
cost="$(printf '%s' "$fields" | cut -f4)"
worktree="$(printf '%s' "$fields" | cut -f5)"
effort="$(printf '%s' "$fields" | cut -f6)"

[ -n "$model" ] || model="Grok"

git_raw=""
if [ -n "$dir" ] && [ -d "$dir" ]; then
  git_raw="$(git -C "$dir" --no-optional-locks status --porcelain=v2 --branch --show-stash 2>/dev/null || true)"
fi

git_fields="$(printf '%s\n' "$git_raw" | awk '
  BEGIN { branch=""; ahead=0; behind=0; staged=0; unstaged=0; untracked=0; conflicted=0; stashed=0 }
  /^# branch\.head / { branch=$3 }
  /^# branch\.ab / { ahead=$3+0; behind=$4+0; if (behind<0) behind=-behind }
  /^# stash / { stashed=$3+0 }
  /^1 / || /^2 / {
    x=substr($2,1,1); y=substr($2,2,1)
    if (x != ".") staged++
    if (y != ".") unstaged++
  }
  /^u / { conflicted++ }
  /^\? / { untracked++ }
  END { printf "%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", branch, ahead, behind, staged, unstaged, untracked, conflicted, stashed }
')"

branch="$(printf '%s' "$git_fields" | cut -f1)"
ahead="$(printf '%s' "$git_fields" | cut -f2)"
behind="$(printf '%s' "$git_fields" | cut -f3)"
staged="$(printf '%s' "$git_fields" | cut -f4)"
unstaged="$(printf '%s' "$git_fields" | cut -f5)"
untracked="$(printf '%s' "$git_fields" | cut -f6)"
conflicted="$(printf '%s' "$git_fields" | cut -f7)"
stashed="$(printf '%s' "$git_fields" | cut -f8)"

[ "$branch" = "(detached)" ] && branch=""

git_seg=""
if [ -n "$branch" ]; then
  git_seg="$branch"
  [ "$behind" -gt 0 ] && git_seg="$git_seg ⇣$behind"
  [ "$ahead" -gt 0 ] && git_seg="$git_seg ⇡$ahead"
  [ "$stashed" -gt 0 ] && git_seg="$git_seg *$stashed"
  [ "$conflicted" -gt 0 ] && git_seg="$git_seg ~$conflicted"
  [ "$staged" -gt 0 ] && git_seg="$git_seg +$staged"
  [ "$unstaged" -gt 0 ] && git_seg="$git_seg !$unstaged"
  [ "$untracked" -gt 0 ] && git_seg="$git_seg ?$untracked"
fi

case "$dir" in
  "$HOME") dir="~" ;;
  "$HOME"/*) dir="~${dir#"$HOME"}" ;;
esac

# Cost under half a cent is noise (matches Grok's builtin cost item).
cost_seg=""
if [ -n "$cost" ] && [ "$cost" != "null" ]; then
  cost_ok="$(awk -v c="$cost" 'BEGIN { if (c+0 >= 0.005) print "1" }')"
  if [ -n "$cost_ok" ]; then
    cost_seg="$(awk -v c="$cost" 'BEGIN { printf "$%.2f", c+0 }')"
  fi
fi

line="$model"
[ -n "$effort" ] && line="$line  $effort"
[ -n "$dir" ] && line="$line  $dir"
[ -n "$worktree" ] && line="$line  wt:$worktree"
[ -n "$git_seg" ] && line="$line  $git_seg"
[ -n "$ctx" ] && line="$line  ${ctx}% ctx"
[ -n "$cost_seg" ] && line="$line  $cost_seg"

printf '%s' "$line"
