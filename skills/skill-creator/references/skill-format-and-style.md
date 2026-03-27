# Skill Format & Style Guide

## GAIA OS Skill Format

Every skill in this system follows the same structure:

```
~/.openclaw/skills/{skill-name}/
  SKILL.md              # Required — main skill file
  scripts/              # Optional — executable helpers
  references/           # Optional — heavy docs loaded on demand
  assets/               # Optional — templates, icons, fonts
```

Symlink: `~/.claude/skills/{skill-name}` -> `~/.openclaw/skills/{skill-name}`

## YAML Frontmatter (Required)

```yaml
---
name: {skill-name}
description: "{ONLY trigger conditions — start with 'When the user...' or list trigger phrases. NEVER summarize the workflow here.}"
agents:
  - {agent1}
  - {agent2}
---
```

**Critical rules for the description field:**
- ONLY trigger conditions — when should this skill activate?
- Include specific user phrases, keywords, and contexts
- NEVER summarize the skill's process or workflow in the description
- Reason: if the description summarizes the workflow, agents may follow the description shortcut instead of reading the full skill body. This was validated by Anthropic's own skill-creator research.
- Keep under 500 characters
- Be slightly "pushy" — include adjacent triggers the user might not think of

**Bad**: "Builds landing pages with hero, benefits, social proof, and CTA sections."
**Good**: "When the user wants to build a landing page, sales page, offer page, or says 'landing page', 'sales copy', 'offer page', 'convert visitors'."

## Markdown Body Structure

```markdown
# {Skill Name} — {One-Line Description}

{2-3 sentence overview of what this skill does and its core principle.}

## When to Use
- {Bullet list of use cases and symptoms}
- {When NOT to use — helps avoid false triggers}

## Procedure
### Step 1 — {Step Name} ({Agent})
{Instructions, tables, templates}
### Step 2 — ...
{Continue for all steps}

## Output Summary
{Table of deliverables and file locations}

## Related Skills
- {skill-name} — {When to use it instead or alongside}
```

## Style Guidelines

- Use imperative form ("Generate the report" not "The report is generated")
- Explain WHY behind instructions — agents are smart, context helps more than rigid MUSTs
- Include one excellent example per step (not multi-language dilution)
- Use tables for structured data (inputs, outputs, fields)
- Keep under 350 lines total
- If content exceeds 350 lines, move heavy reference to `references/` subdirectory
