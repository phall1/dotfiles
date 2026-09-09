# shellcheck shell=bash
# Shared skills and their per-harness adapters.
#
# Harnesses that do not read ~/.agents/skills natively get chezmoi symlink
# adapters. A symlink into a missing file is silent at every layer above the
# filesystem -- the harness simply never loads the skill -- so the adapters are
# resolved here rather than merely counted.
hdr "shared skills"

live="$HOME/.agents/skills"
seeds="$DOTFILES/dot_agents/skills"

missing=''
while IFS= read -r -d '' source; do
  relative="${source#"$seeds"/}"
  [[ -e "$live/$relative" ]] || missing+=" $relative"
done < <(find "$seeds" -type f -print0 2>/dev/null)

if [[ -z "$missing" ]]; then
  ok "every tracked shared skill file is present in ~/.agents/skills"
else
  fail "shared skill files absent from the live tree:$missing — run 'mise bootstrap' (scripts/bootstrap/skills.sh)"
fi

dangling=''
for adapter in \
  "$HOME"/.claude/skills/*/SKILL.md \
  "$HOME"/.config/opencode/skill/*/SKILL.md \
  "$HOME"/.hermes/skills/*/SKILL.md
do
  [[ -L "$adapter" ]] || continue
  [[ -e "$adapter" ]] && continue
  dangling+=" ${adapter#"$HOME"/}"
done

if [[ -z "$dangling" ]]; then
  ok "all harness skill adapters resolve"
else
  fail "dangling skill adapters:$dangling"
fi
