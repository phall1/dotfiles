---
description: Review the current diff for correctness, security, and missing tests
---

Run a read-only code review over the current uncommitted changes. Report findings in severity order, each with a `file:line` reference and a concrete suggestion. Do not edit files or run commands.

!`git diff HEAD && git diff --cached && git status --short`

$ARGUMENTS
