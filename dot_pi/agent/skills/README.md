# Pi Skills

On-demand capability packages following the [Agent Skills standard](https://agentskills.io).

## Quick Start

Create a subdirectory with a `SKILL.md`:

```
my-skill/
├── SKILL.md          # Required: frontmatter + instructions
├── scripts/          # Optional helper scripts
│   └── run.sh
└── references/       # Optional detailed docs
    └── api.md
```

### SKILL.md Format

```markdown
---
name: my-skill
description: What this skill does and when to use it. Be specific — this determines when the agent loads it.
---

# My Skill

Instructions the agent follows when this skill is activated.

## Usage

\`\`\`bash
./scripts/run.sh <input>
\`\`\`

See [API reference](references/api.md) for details.
```

## How It Works

1. Pi scans skill directories at startup, extracts names + descriptions
2. Descriptions are included in system prompt (progressive disclosure)
3. When a task matches, the agent uses `read` to load the full SKILL.md
4. Force-load with `/skill:name` command

## Frontmatter

| Field | Required | Notes |
|-------|----------|-------|
| `name` | Yes | Lowercase a-z, 0-9, hyphens. Must match directory name. Max 64 chars. |
| `description` | Yes | Max 1024 chars. Be specific — this is what the agent sees. |
| `license` | No | License name |
| `compatibility` | No | Environment requirements |
| `disable-model-invocation` | No | If true, only loadable via `/skill:name` |

## Name Rules

- Lowercase letters, numbers, hyphens only
- No leading/trailing hyphens, no consecutive hyphens
- Must match parent directory name

## Locations

- Global: `~/.pi/agent/skills/` and `~/.agents/skills/`
- Project: `.pi/skills/` and `.agents/skills/` (walks up to git root)
- Packages, settings, CLI: `--skill <path>`

## Reference

- Docs: https://pi.dev/docs/latest/skills
- Standard: https://agentskills.io/specification
