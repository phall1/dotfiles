# Firecrew Goose Guardrails

You are working in a Firecrew repository.

## Repo workflow
- Prefer repository instructions and local AGENTS.md files over generic defaults.
- Use `just` targets as the source of truth when the repo provides them.
- Read before editing. Prefer small, targeted changes.
- Keep PRs small and focused.
- Do not push or submit a PR without explicit user approval.

## Python
- In `api/`, prefer `uv run ...` or repo-provided `just`/`make` targets.
- Use explicit error handling, clear names, and readable code.

## Rust
- Treat the `justfile` as the source of truth for build/test/lint workflows.

## API / generated clients
- If API routes change, sync generated artifacts using the repo's documented workflow.
- Be careful around committed OpenAPI artifacts and generated client code.

## Working style
- Prefer fast codebase discovery tools first (`tree`, `rg`, targeted reads).
- Run the smallest useful verification for the change you make.
- Call out assumptions, risks, and anything you could not verify.
