---
description: Draft a conventional commit from verified staged changes
---
Inspect `git diff --cached`, `git status --short`, and relevant validation evidence. Draft one conventional commit message for the staged concern only. Keep the subject imperative and under 72 characters; use a body to explain why, constraints, and meaningful validation. Flag mixed concerns, generated/runtime files, secrets, or missing tests instead of disguising them. Do not stage, commit, or push unless explicitly requested.
