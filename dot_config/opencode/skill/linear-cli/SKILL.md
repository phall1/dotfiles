---
name: linear-cli
description: Interact with Linear project management via CLI
---

<skill>
You are a Linear CLI assistant that helps users manage their Linear issues and projects through the command line.

## Prerequisites Check

Before using any Linear commands, verify the CLI is installed:

```bash
which linear
```

If the CLI is NOT installed, you MUST prompt the user to install it:

> ⚠️ **Linear CLI not found!** Would you like me to install it for you?
>
> Run this command:
> ```bash
> brew install schpet/tap/linear
> ```
>
> After installation, you'll need to authenticate:
> ```bash
> linear auth login
> ```
>
> Then create an API key at: https://linear.app/settings/account/security

## Post-Install Setup

After installation, check if authenticated:

```bash
linear auth status
```

If not authenticated, prompt the user:

> 🔑 **Linear CLI needs authentication**
>
> 1. Create an API key at: https://linear.app/settings/account/security
> 2. Run: `linear auth login`
> 3. Paste your API key when prompted

## Key Commands

### Issue Management
- `linear issue list` - List issues assigned to you (unstarted)
- `linear issue list -A` - List issues assigned to anyone
- `linear issue list -j` - Output as JSON (best for agents)
- `linear issue start [ISSUE-ID]` - Start working on an issue (creates branch)
- `linear issue view` - View current branch's issue details
- `linear issue view ISSUE-ID` - View specific issue
- `linear issue create` - Create a new issue (interactive)
- `linear issue create -t "Title" -d "Description"` - Create with flags
- `linear issue update ISSUE-ID --state "In Progress"` - Update issue state
- `linear issue comment list` - List comments on current issue
- `linear issue comment add "Comment text"` - Add a comment
- `linear issue pr` - Create GitHub PR for current issue

### Team & Project Commands
- `linear team list` - List teams
- `linear team members [TEAM]` - List team members
- `linear project list` - List projects
- `linear project view [PROJECT-ID]` - View project details

### Milestone & Document Commands
- `linear milestone list --project [ID]` - List milestones
- `linear milestone create --project [ID] --name "Name" --target-date "YYYY-MM-DD"`
- `linear document list` - List documents
- `linear document view [SLUG]` - View document
- `linear document create --title "Title" --content "# Markdown"`

### Navigation
- `linear issue view -w` - Open current issue in browser
- `linear issue view -a` - Open current issue in Linear app
- `linear issue list -w` - Open issue list in browser

## Important Flags for Agents

**Always use `-j` or `--json` for structured output:**
```bash
linear issue list -j
linear issue view -j
linear team list -j
```

**Filter by state:**
```bash
linear issue list -s "In Progress"
linear issue list -s "Todo"
linear issue list --state "Done"
```

**Sort options:**
```bash
linear issue list --sort priority    # Sort by priority
linear issue list --sort manual      # Manual sort (default)
```

## Configuration

The CLI uses a config file (`.linear.toml` or `linear.toml`) in your repo root:
```toml
team_id = "ENG"           # Default team
workspace = "mycompany"   # Workspace slug
issue_sort = "priority"   # Default sort
vcs = "git"               # or "jj"
```

Environment variables (override config):
- `LINEAR_TEAM_ID` - Default team
- `LINEAR_WORKSPACE` - Workspace slug
- `LINEAR_ISSUE_SORT` - Sort preference
- `LINEAR_VCS` - Version control system

## Workflow Patterns

### Daily Standup
```bash
# What's in progress?
linear issue list -s "In Progress" -j

# What's todo?
linear issue list -s "Todo" --sort priority -j
```

### Starting Work
```bash
# Pick from your issues
linear issue start

# Or start specific issue
linear issue start ENG-123
```

### Creating Issues
```bash
# Quick create
linear issue create -t "Fix login bug" -d "Users can't log in with OAuth"

# With team and priority
linear issue create -t "Title" --team ENG --priority 1
```

### Review Context
```bash
# See what you're working on
linear issue view

# Get the issue ID for scripts
linear issue id

# Get just the title
linear issue title

# Get the URL
linear issue url
```

## Best Practices

1. **For scripting**: Always use `-j/--json` flag
2. **Git branch detection**: The CLI auto-detects issue IDs from branch names (e.g., `eng-123-feature`)
3. **Works with jj**: If using jujutsu, it reads `Linear-issue` trailers from commits
4. **Multi-workspace**: Use `linear auth login` to add multiple workspaces
5. **PR creation**: `linear issue pr` uses `gh` CLI to create PRs with proper title/body

## Common Gotchas

- Issue IDs can be referenced as `ENG-123` or just `123` (team prefix optional in most cases)
- The CLI requires member access (not guest) to create API keys
- Branch names should include issue ID: `team-123-description` format
- For JSON output, use `-j` not `--json` (shorter)
</skill>
