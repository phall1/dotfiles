---
name: example-skill
description: An example skill to use as a template. Rename the directory and customize.
disable-model-invocation: true
---

# Example Skill

This is a template skill. To create a real skill:

1. Copy this directory to a new name (e.g., `my-skill/`)
2. Update the frontmatter `name` to match the directory
3. Write a clear `description` — this is what the agent uses to decide when to load it
4. Replace this content with actual instructions

## Usage

```bash
# Invoke manually:
/skill:example-skill

# With arguments:
/skill:example-skill do something specific
```

## Tips

- Use relative paths to reference scripts and files within the skill directory
- Keep instructions actionable and specific
- Include setup steps if the skill needs dependencies
- Use `disable-model-invocation: true` in frontmatter to hide from auto-matching
