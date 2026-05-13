# Pi Prompt Templates

Reusable prompts as Markdown files. Type `/name` to expand (filename without `.md`).

## Quick Start

Create a `.md` file here:

```markdown
---
description: Review code for common issues
---
Review this code for bugs, security issues, and performance problems.
Focus on: $@
```

## Usage

```
/review                      → expands the template
/review error handling       → $@ = "error handling", $1 = "error handling"
/component Button onClick    → $1 = "Button", $2 = "onClick", $@ = "Button onClick"
```

## Arguments

| Syntax | Meaning |
|--------|---------|
| `$1`, `$2` | Positional arguments |
| `$@` or `$ARGUMENTS` | All arguments joined |
| `${@:N}` | Args from Nth position |
| `${@:N:L}` | L args starting at N |

## Format

- Filename = command name (`review.md` → `/review`)
- `description` frontmatter is optional (first non-empty line used as fallback)
- Plain markdown body, expanded as the user message

## Locations

- Global: `~/.pi/agent/prompts/*.md`
- Project: `.pi/prompts/*.md`
- Packages, settings, CLI

## Reference

- Docs: https://pi.dev/docs/latest/prompt-templates
