---
description: Stage and commit current changes with a scoped conventional-commit message
---

Review the current diff and draft a conventional commit: a tight `type(scope):` first line and a body explaining the why, not the what. Show me the exact staged file set plus the full message and get my OK before staging. When approved, stage explicit paths only — never `git add -A` — and commit.

!`git status --short && git diff --stat`

$ARGUMENTS
