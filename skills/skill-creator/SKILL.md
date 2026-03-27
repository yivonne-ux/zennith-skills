---
name: skill-creator
description: "When the user wants to create a new skill, generate a SKILL.md, automate skill creation, turn a process into a skill, or says 'create a skill', 'make a skill', 'new skill', 'skill-creator', 'turn this into a skill', 'skillify'."
agents:
  - taoz
---

# Skill Creator — Meta-Skill for Auto-Generating SKILL.md Files

Turns any process, workflow, or capability into a properly structured GAIA OS skill. Handles the full lifecycle: gathering requirements, generating the SKILL.md, testing with subagents, iterating based on eval results, and packaging into the skills directory with symlinks.

## When to Use

- Creating a new skill from scratch
- Converting a workflow or process into a reusable skill
- Turning a successful Claude Code session into a repeatable skill
- Generating SKILL.md files from verbal descriptions
- Quality-checking existing skills for structure and trigger accuracy

> Load `references/skill-format-and-style.md` for GAIA OS skill format, YAML frontmatter rules, body structure, and style guidelines.

## Procedure

### Step 1 — Gather Process Description

Interview the user to capture:

| Question | Purpose |
|----------|---------|
| What should this skill enable an agent to do? | Core capability |
| When should it trigger? What would a user say? | Trigger phrases for description field |
| What agents should run this? | Agent assignment (taoz, scout, dreami, main) |
| What's the expected output? | Success criteria |
| What tools or scripts does it need? | Dependencies |
| Are there edge cases or things to avoid? | Guardrails |
| Is there an existing workflow to capture? | If yes, extract steps from conversation history |

If the current conversation already contains a workflow the user wants to capture (e.g., "turn this into a skill"), extract answers from the conversation history first. The user confirms before proceeding.

### Step 2 — Generate SKILL.md

Build the skill file following the format and style rules in `references/skill-format-and-style.md`. Key points:
- YAML frontmatter: `name`, `description` (ONLY trigger conditions), `agents`
- Markdown body: title, overview, When to Use, Procedure (steps with agent roles), Output Summary, Related Skills

### Step 3 — Add Procedure Details

For each step in the procedure:

1. **Agent role**: Which agent runs this step and why
2. **Inputs**: What the step needs (from user or previous steps)
3. **Process**: Clear instructions the agent follows
4. **Output**: What this step produces (file, data, decision)
5. **Validation**: How to verify the step succeeded

Include examples, related skills (name only, no @-links), and edge case handling.

### Step 4-5 — Eval Loop & Iterate

> Load `references/eval-and-iteration.md` for the full eval protocol: baseline vs with-skill testing, grading rubric, scoring dimensions, and iteration principles.

Test the skill by running it with and without the SKILL.md loaded. Compare outputs across 5 dimensions (structure, completeness, agent usage, trigger accuracy, edge cases). Pass threshold: 75%. Iterate until all dimensions pass.

### Step 6 — Package and Deploy

```bash
# Verify skill file
ls ~/.openclaw/skills/{skill-name}/SKILL.md

# Symlink
ln -sf ~/.openclaw/skills/{skill-name} ~/.claude/skills/{skill-name}

# Git commit
cd ~/.openclaw && git add skills/{skill-name}/ && git commit -m "Add {skill-name} skill"
```

Tell the user: skill location, symlink, trigger phrases, and assigned agents.

## Output Summary

| Deliverable | Location |
|-------------|----------|
| SKILL.md | `~/.openclaw/skills/{skill-name}/SKILL.md` |
| Symlink | `~/.claude/skills/{skill-name}` |
| Eval results | `~/.openclaw/workspace/data/skill-evals/{skill-name}/` |
| Scripts (if any) | `~/.openclaw/skills/{skill-name}/scripts/` |
| References (if any) | `~/.openclaw/skills/{skill-name}/references/` |

> Load `references/quality-checklist.md` for the full pre-ship checklist, versioning rules, and common mistakes table.

## Related Skills

- `rigour` — Run quality gate on any scripts bundled with the skill
- `skill-router` — The system that matches user queries to skills at runtime
- `knowledge-transfer` — For transferring Claude Code learnings into OpenClaw-executable skills
- `workflow-automation` — For registering the skill in the production chain
