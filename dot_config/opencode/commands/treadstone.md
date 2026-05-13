---
description: Strategic planning — brainstorm, plan, break down, sync to Linear
agent: treadstone
subtask: true
---

Run the Treadstone planning workflow. $ARGUMENTS

## Phase 0: Scope & Orient

Before anything else, understand what you're working with.

### Determine scope

Use the `question` tool to ask the user:

1. **What's the idea/workstream?** (they may have already said it via $ARGUMENTS — don't re-ask if so)
2. **What altitude are we at?**
   - Initiative (multi-project, quarter+)
   - Project (weeks to months, multiple milestones)
   - Feature/Epic (days to weeks, handful of tasks)
   - Sprint chunk (a few tasks, get it done)
3. **Does this plug into something existing in Linear?**
   - If yes: which project/initiative? (Offer to look it up via Linear tools)
   - If no: starting fresh

### Recon existing Linear state (if applicable)

If plugging into existing work, use Linear MCP tools to pull context:
- `linear_list_projects` / `linear_get_project` — understand current project state
- `linear_list_milestones` — see what milestones exist
- `linear_list_issues` — see existing issues in the space
- `linear_list_issue_labels` — know available labels
- `linear_list_teams` — confirm team context
- `linear_list_issue_statuses` — know the workflow states

Summarize what exists. Ask the user if the picture is accurate before proceeding.

## Phase 1: Brainstorm

This is freeform. The goal is to get the idea out of the user's head and onto the page.

### How to brainstorm

- Ask probing questions using the `question` tool. Give options when you can infer likely directions. Keep it tight — 2-4 questions per round max.
- Think about:
  - What problem does this solve? Who is it for?
  - What are the key technical decisions/unknowns?
  - What are the dependencies (internal systems, external services, team capacity)?
  - What does "done" look like?
  - What's the rough timeline/urgency?
  - Are there things we're explicitly NOT doing?
- After each round, reflect back a tightened summary of what you've heard. Let the user correct/expand.
- 2-3 rounds is usually enough. Don't over-interview. If the user is giving you clear, detailed input, move faster.

### Write the brainstorm dump

Write a freeform markdown file to the current working directory:

```
./{slug}-brainstorm.md
```

Where `{slug}` is a kebab-case name for the workstream (e.g., `auth-overhaul-brainstorm.md`).

This file captures the raw thinking: key ideas, decisions, open questions, constraints, non-goals. It's a reference artifact, not the plan.

Tell the user the file was written and ask if they want to revise anything before moving to structuring.

## Phase 2: Structure the Plan

Take the brainstorm and distill it into a structured planning document. The structure should map to Linear's ontology but only use the layers that match the scope:

### Mapping scope to structure

| Scope | Doc sections |
|-------|-------------|
| Initiative | Vision, Projects, per-Project Milestones, key Epics |
| Project | Overview, Milestones, Epics/Tasks per milestone |
| Feature/Epic | Overview, Tasks, Acceptance criteria |
| Sprint chunk | Task list with descriptions, priority order |

### Write the plan doc

Write to:

```
./{slug}-plan.md
```

The document should include (adapting to scope):

```markdown
# {Title}

## Context
Why this exists. What problem it solves. 1-3 sentences.

## Goals
Bulleted. What does success look like?

## Non-Goals
What we're explicitly not doing.

## Approach
High-level technical/strategic approach. Key decisions made.

## {Milestones / Phases / Sections}
For each:
- Name (clear, specific)
- Description (1-2 sentences)
- Tasks within it:
  - Task title (action-oriented, specific)
  - Brief description
  - Priority (Urgent / High / Normal / Low)
  - Estimate if discussed
  - Labels if applicable

## Open Questions
Anything unresolved that needs answers before or during execution.

## Dependencies
What this depends on, what depends on this.
```

Present the structured plan to the user for review. Use the `question` tool to ask:
- Does this capture the plan correctly?
- Any items to add, remove, or restructure?
- Ready to sync to Linear?

Iterate until approved.

## Phase 3: Sync to Linear

This phase creates the plan in Linear. **Every creation requires explicit user approval.**

### Determine what to create

Based on the scope and whether we're plugging into existing Linear structure:

**Starting fresh (new project):**
1. Present the project to create (name, description, team, labels)
2. On approval → create via `linear_save_project`
3. Present milestones to create (name, description, target dates)
4. On approval → create via `linear_save_milestone`
5. Present issues/tasks grouped by milestone (title, description, priority, labels, assignee)
6. On approval for each group → create via `linear_save_issue` with correct `project` and `milestone`

**Plugging into existing project:**
1. Show what exists, show what you'll add
2. Present new milestones (if any) for approval → `linear_save_milestone`
3. Present new issues grouped logically for approval → `linear_save_issue`

**Small scope (just tasks):**
1. Present the task list with titles, descriptions, priorities, labels
2. On approval → create via `linear_save_issue`

### Approval flow

For each batch of items to create, use the `question` tool:

- Show a clear summary of what will be created
- Ask for approval to proceed
- After creation, confirm what was created with identifiers (e.g., ENG-123)
- Ask if adjustments are needed before moving to the next batch

### Issue quality standards

Every issue created must have:
- **Action-oriented title**: "Implement OAuth2 PKCE flow" not "Auth stuff"
- **Description**: What needs to happen and why. Include acceptance criteria for non-trivial items.
- **Priority**: Set based on discussion (1=Urgent, 2=High, 3=Normal, 4=Low)
- **Labels**: Apply relevant labels from the team's existing label set
- **Parent issue**: Set for sub-tasks of epics

### After sync

Summarize what was created:
- Total items created (projects, milestones, issues)
- Key identifiers for reference
- Note the local planning docs for reference

Ask: "Plan is live. Anything to adjust, or are we good?"

## General Workflow Rules

1. **Always use the `question` tool** for structured input. Don't ask open-ended questions in prose when you can offer options.
2. **Match granularity to scope.** A 2-hour task list doesn't need milestones. A platform migration does.
3. **Local docs first, Linear second.** The planning docs are the source of truth until synced.
4. **Iterate, don't lecture.** Keep rounds tight. Summarize, confirm, move on.
5. **Respect what exists.** If there's existing Linear structure, work within it unless the user explicitly wants to restructure.
6. **Name things well.** Vague titles are a planning failure. Every item should be clear enough that someone could pick it up cold.
